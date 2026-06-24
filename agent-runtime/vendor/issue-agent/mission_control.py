#!/usr/bin/env python3
"""Mission Control — live Habitat Solver fleet dashboard."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
AGENT = ROOT / "issue_agent.py"
PYTHON = Path(os.environ.get("ISSUE_AGENT_PYTHON", str(Path.home() / ".local/venvs/aider/bin/python")))
SNAPSHOT = ROOT / "validate-snapshot.json"
FAILURE_LEDGER = ROOT / "failure-ledger.json"
TRAJECTORIES = ROOT / "flight-recorder" / "trajectories.jsonl"
FLEET_OWNER = "Nueramarcos"
UPSTREAM_PROOF_REPOS = [
    "tinygrad/tinygrad",
    "0xReLogic/Forge",
    "karpathy/micrograd",
    "pytorch/vision",
]


def _load_json(path: Path) -> dict | list:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return {}


def _utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def _run(cmd: list[str]) -> str:
    try:
        r = subprocess.run(cmd, text=True, capture_output=True, check=False, timeout=8)
        return (r.stdout or r.stderr or "").strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def _lane_workers() -> list[tuple[str, str]]:
    out = _run(["ps", "aux"])
    rows: list[tuple[str, str]] = []
    for line in out.splitlines():
        if "issue_agent.py" not in line:
            continue
        if "issue_agent.py airport" in line:
            continue
        if not any(k in line for k in (" worker ", " roam", " upstream")):
            continue
        parts = line.split(None, 10)
        if len(parts) < 11:
            continue
        pid, label = parts[1], parts[10]
        if "issue_agent.py" in label:
            label = label.split("issue_agent.py", 1)[-1].strip()[:72]
        rows.append((pid, label))
    return rows


def _recent_activity(events: list, limit: int = 8) -> list[dict]:
    interesting = {"pass", "merge", "pr_merged", "fix_success", "failure", "habitat_ready", "roam_pass", "factory", "airport_start"}
    picked = [e for e in reversed(events) if e.get("event") in interesting]
    return picked[:limit]


def _load_trajectories() -> list[dict[str, Any]]:
    if not TRAJECTORIES.exists():
        return []
    rows: list[dict[str, Any]] = []
    for line in TRAJECTORIES.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


def _recorder_stats() -> dict[str, Any]:
    rows = _load_trajectories()
    by_outcome: dict[str, int] = {}
    for row in rows:
        outcome = str(row.get("outcome", "unknown"))
        by_outcome[outcome] = by_outcome.get(outcome, 0) + 1
    merged = by_outcome.get("merged_pr", 0)
    failures = by_outcome.get("failure", 0)
    attempts = merged + failures
    yield_pct = round(100 * merged / attempts, 1) if attempts else 0.0
    return {
        "trajectories": len(rows),
        "merged_pr": merged,
        "failures": failures,
        "merge_yield_pct": yield_pct,
        "by_outcome": by_outcome,
    }


def _load_failure_ledger() -> dict[str, Any]:
    if not FAILURE_LEDGER.exists():
        return {"items": {}}
    try:
        return json.loads(FAILURE_LEDGER.read_text())
    except json.JSONDecodeError:
        return {"items": {}}


def _top_failure() -> dict[str, Any] | None:
    items = _load_failure_ledger().get("items", {})
    if not items:
        return None
    ranked = sorted(
        items.values(),
        key=lambda e: (not e.get("blocked"), int(e.get("attempts", 0))),
        reverse=True,
    )
    return ranked[0] if ranked else None


def _upstream_merge_count() -> tuple[int, str]:
    total = 0
    rate_limited = False
    for repo in UPSTREAM_PROOF_REPOS:
        raw = _run(
            [
                "gh",
                "pr",
                "list",
                "-R",
                repo,
                "--author",
                FLEET_OWNER,
                "--state",
                "merged",
                "--json",
                "number",
                "--limit",
                "100",
            ]
        )
        if "rate limit" in raw.lower():
            rate_limited = True
            break
        try:
            total += len(json.loads(raw)) if raw.startswith("[") else 0
        except json.JSONDecodeError:
            continue
    if rate_limited or total == 0:
        fleet_prefix = f"{FLEET_OWNER}/"
        recorder = len(
            {
                row.get("repo")
                for row in _load_trajectories()
                if row.get("outcome") == "merged_pr"
                and row.get("repo")
                and not str(row.get("repo", "")).startswith(fleet_prefix)
            }
        )
        if recorder:
            return recorder, "recorder (gh rate-limited or empty)"
    return total, "github"


def _fleet_merge_count() -> tuple[int, str]:
    repos = [
        "Nueramarcos/orion-ai-agent",
        "Nueramarcos/forge-ci-reliability",
        "Nueramarcos/nexus-vision-engine",
        "Nueramarcos/vertex-sim-core",
        "Nueramarcos/issue-agent",
    ]
    total = 0
    rate_limited = False
    for repo in repos:
        raw = _run(
            [
                "gh",
                "pr",
                "list",
                "-R",
                repo,
                "--author",
                FLEET_OWNER,
                "--state",
                "merged",
                "--json",
                "number",
                "--limit",
                "100",
            ]
        )
        if "rate limit" in raw.lower():
            rate_limited = True
            break
        try:
            total += len(json.loads(raw)) if raw.startswith("[") else 0
        except json.JSONDecodeError:
            continue
    if rate_limited or total == 0:
        fleet_prefix = f"{FLEET_OWNER}/"
        recorder = sum(
            1
            for row in _load_trajectories()
            if row.get("outcome") == "merged_pr" and str(row.get("repo", "")).startswith(fleet_prefix)
        )
        if recorder:
            return recorder, "recorder (gh rate-limited or empty)"
    return total, "github"


def _floor_label(*, trajectories: int, merge_yield: float, upstream: int) -> tuple[int, str]:
    if upstream >= 5 and trajectories >= 500 and merge_yield >= 70:
        return 4, "Floor 4 — research/benchmark tier (proof + volume)"
    if upstream >= 2 and trajectories >= 200:
        return 3, "Floor 3 — paid OSS / bounties / consulting lane"
    if trajectories >= 50 or upstream >= 1:
        return 2, "Floor 2 — serious solo builder (you are here)"
    return 1, "Floor 1 — demo/hype without durable proof"


def _machine_verdict(*, floor: int, upstream: int, trajectories: int, delta_t: int) -> str:
    if floor >= 3:
        return "ON TRACK — upstream proof is showing; keep output cycle and monetize proof."
    if upstream < 2 and trajectories >= 100:
        return "LOOP STRONG, PROOF THIN — factory works; push upstream lane before more fleet polish."
    if delta_t > 0:
        return "MOVING — trajectories grew; next lever is upstream merges, not architecture."
    return "STALL RISK — run mission validate --do to execute the next highest-leverage action."


def _pick_next_action(
    *,
    gh_ok: bool,
    ollama_ok: bool,
    workers: list[tuple[str, str]],
    upstream: int,
    top_fail: dict[str, Any] | None,
    triage: list[tuple[str, int]],
) -> tuple[str, list[str]]:
    if not gh_ok:
        return "Fix GitHub auth", ["gh", "auth", "status"]
    if not ollama_ok:
        return "Start Ollama", ["systemctl --user start ollama 2>/dev/null || ollama serve &"]
    if not workers:
        return "Start airport fleet", ["issue-agent-airport-start"]
    if upstream < 2:
        return "Scout upstream opportunities (Floor 3 lever)", ["issue-agent", "scout", "--live", "--limit", "5"]
    if top_fail and not top_fail.get("blocked"):
        repo = str(top_fail.get("repo", ""))
        ident = str(top_fail.get("ident", ""))
        scope = str(top_fail.get("scope", "issue"))
        if scope == "issue" and ident.isdigit():
            return f"Retry blocked pattern on {repo} #{ident}", ["issue-agent", "fix", repo, ident]
        if scope == "local":
            return f"Retry local task on {repo}", ["issue-agent", "local", repo, ident]
    hot = sorted(triage, key=lambda x: -x[1])
    if hot and hot[0][1] > 0:
        short, _ = hot[0]
        repo = f"Nueramarcos/{short}"
        raw = _run(
            [
                "gh",
                "issue",
                "list",
                "-R",
                repo,
                "--label",
                "agent-triage",
                "--state",
                "open",
                "--json",
                "number",
                "--limit",
                "1",
            ]
        )
        try:
            issues = json.loads(raw) if raw.startswith("[") else []
        except json.JSONDecodeError:
            issues = []
        if issues:
            num = str(issues[0].get("number", ""))
            return f"Fix hottest triage issue {repo} #{num}", ["issue-agent", "fix", repo, num]
    return "Seed factory queue", ["issue-agent", "factory"]


def _save_snapshot(payload: dict[str, Any]) -> None:
    SNAPSHOT.write_text(json.dumps(payload, indent=2))


def _load_snapshot() -> dict[str, Any]:
    if not SNAPSHOT.exists():
        return {}
    try:
        return json.loads(SNAPSHOT.read_text())
    except json.JSONDecodeError:
        return {}


def render_validate(*, do: bool = False) -> int:
    prev = _load_snapshot()
    stats = _recorder_stats()
    upstream, upstream_src = _upstream_merge_count()
    fleet, fleet_src = _fleet_merge_count()
    workers = _lane_workers()
    triage = _agent_triage_counts()
    top_fail = _top_failure()
    gh_ok = _run(["gh", "auth", "status"]).find("Logged in") >= 0
    ollama_ok = _run(["curl", "-sf", "http://127.0.0.1:11434/api/tags"]).startswith("{")

    floor, floor_desc = _floor_label(
        trajectories=stats["trajectories"],
        merge_yield=stats["merge_yield_pct"],
        upstream=upstream,
    )
    prev_t = int(prev.get("trajectories", 0))
    delta_t = stats["trajectories"] - prev_t
    verdict = _machine_verdict(
        floor=floor,
        upstream=upstream,
        trajectories=stats["trajectories"],
        delta_t=delta_t,
    )
    action_label, action_cmd = _pick_next_action(
        gh_ok=gh_ok,
        ollama_ok=ollama_ok,
        workers=workers,
        upstream=upstream,
        top_fail=top_fail,
        triage=triage,
    )

    now = datetime.now(timezone.utc)
    payload = {
        "ts": now.isoformat(),
        "floor": floor,
        "trajectories": stats["trajectories"],
        "merge_yield_pct": stats["merge_yield_pct"],
        "upstream_merges": upstream,
        "fleet_merges": fleet,
        "verdict": verdict,
        "next_action": action_label,
    }
    _save_snapshot(payload)

    lines: list[str] = []
    lines.append("")
    lines.append("  ╔══════════════════════════════════════════════════════════════╗")
    lines.append("  ║  MISSION VALIDATE — machine mirror (say → do)               ║")
    lines.append("  ╚══════════════════════════════════════════════════════════════╝")
    lines.append(f"  {now.strftime('%Y-%m-%d %H:%M:%S UTC')}")
    lines.append("")
    lines.append(f"  FLOOR: {floor} — {floor_desc}")
    lines.append("")
    lines.append("  SCOREBOARD")
    lines.append(f"    trajectories:      {stats['trajectories']:4}  ({delta_t:+} since last validate)")
    lines.append(f"    merge_yield:       {stats['merge_yield_pct']:5}%  ({stats['merged_pr']} merged / {stats['failures']} fail)")
    lines.append(f"    upstream_merges:   {upstream:4}  ({upstream_src}) ← credibility + income lever")
    lines.append(f"    fleet_merges:      {fleet:4}  ({fleet_src}) ← loop fuel (not ego fuel)")
    lines.append(f"    active_workers:    {len(workers):4}")
    lines.append("")
    lines.append("  MACHINE VERDICT")
    lines.append(f"    {verdict}")
    lines.append("")
    if top_fail:
        hint = str(top_fail.get("hint", ""))[:60]
        lines.append("  TOP FAILURE TO REFINE")
        lines.append(
            f"    {top_fail.get('repo', '?')} · {top_fail.get('scope', '?')}/{top_fail.get('ident', '?')} "
            f"({top_fail.get('kind', '?')}) — {hint}"
        )
        lines.append("")
    lines.append("  NEXT ACTION (say → do)")
    lines.append(f"    SAY: {action_label}")
    lines.append(f"    DO:  {' '.join(action_cmd)}")
    lines.append("")
    lines.append("  TOP FLOOR PATH")
    lines.append("    Floor 2→3: upstream merges + paid bounties/labeling")
    lines.append("    Floor 3→4: repeatable income + benchmark-grade proof")
    lines.append("    Say-do loop every session beats more architecture.")
    lines.append("")
    print("\n".join(lines))

    if do:
        print("  EXECUTING NOW…\n")
        env = os.environ.copy()
        env.pop("GITHUB_TOKEN", None)
        env.pop("GH_TOKEN", None)
        env["PATH"] = f"{Path.home() / 'bin'}:{Path.home() / '.local/bin'}:{env.get('PATH', '')}"
        if len(action_cmd) == 1 and (" " in action_cmd[0] or "|" in action_cmd[0] or "&" in action_cmd[0]):
            proc = subprocess.run(action_cmd[0], shell=True, check=False, env=env)
        else:
            proc = subprocess.run(action_cmd, check=False, env=env)
        return proc.returncode
    return 0


def _agent_triage_counts() -> list[tuple[str, int]]:
    repos = [
        "Nueramarcos/orion-ai-agent",
        "Nueramarcos/forge-ci-reliability",
        "Nueramarcos/nexus-vision-engine",
        "Nueramarcos/vertex-sim-core",
    ]
    rows: list[tuple[str, int]] = []
    for repo in repos:
        raw = _run(
            [
                "gh",
                "issue",
                "list",
                "-R",
                repo,
                "--label",
                "agent-triage",
                "--state",
                "open",
                "--json",
                "number",
                "--limit",
                "100",
            ]
        )
        try:
            n = len(json.loads(raw)) if raw.startswith("[") else 0
        except json.JSONDecodeError:
            n = 0
        rows.append((repo.split("/")[-1], n))
    return rows


def render(*, watch: bool = False) -> int:
    airport = _load_json(ROOT / "airport-status.json")
    status = _load_json(ROOT / "status.json")
    activity = _load_json(ROOT / "activity.json")
    if not isinstance(activity, list):
        activity = []

    health = status.get("health", {}) if isinstance(status, dict) else {}
    gh_ok = health.get("gh", _run(["gh", "auth", "status"]).find("Logged in") >= 0)
    ollama_ok = _run(["curl", "-sf", "http://127.0.0.1:11434/api/tags"]).startswith("{")
    ruff_ok = bool(_run(["ruff", "--version"]))

    lines: list[str] = []
    lines.append("")
    lines.append("  ╔══════════════════════════════════════════════════════════════╗")
    lines.append("  ║  HABITAT MISSION CONTROL — Nueramarcos · 24h sprint         ║")
    lines.append("  ╚══════════════════════════════════════════════════════════════╝")
    lines.append(f"  {_utc_now()}")
    lines.append("")
    lines.append("  NORTH STAR")
    lines.append("  Local agent fleet → merged PRs → Flight Recorder → LoRA → repeat")
    lines.append("  Grok (brain) + Issue Agent (hands) + Ollama (muscle) on your gaming PC")
    lines.append("")
    lines.append("  STACK HEALTH")
    sym = lambda ok: "✓" if ok else "✗"
    lines.append(f"    {sym(gh_ok)} GitHub (gh)     {sym(ollama_ok)} Ollama          {sym(ruff_ok)} Ruff/Tower")
    sup = airport.get("supervisor", "?") if isinstance(airport, dict) else "?"
    lanes = airport.get("lanes", "?") if isinstance(airport, dict) else "?"
    hb = (airport.get("supervisor_heartbeat") or "")[:19] if isinstance(airport, dict) else ""
    lines.append(f"    Airport: {sup} · {lanes} lanes · heartbeat {hb}")
    lines.append("")
    lines.append("  ACTIVE WORKERS")
    workers = _lane_workers()
    if workers:
        for pid, label in workers[:10]:
            lines.append(f"    pid {pid:>6}  {label}")
    else:
        lines.append("    (none — run: issue-agent-airport-start)")
    lines.append("")
    lines.append("  AGENT-TRIAGE QUEUE (open issues)")
    for short, n in _agent_triage_counts():
        bar = "█" * min(n, 12)
        lines.append(f"    {short:22} {n:3}  {bar}")
    qtotal = status.get("local_queue_total", "?") if isinstance(status, dict) else "?"
    lines.append(f"    local queue total: {qtotal}")
    lines.append("")
    lines.append("  RECENT EVENTS")
    for ev in _recent_activity(activity):
        ts = (ev.get("ts") or "")[11:19]
        evt = ev.get("event", "?")
        repo = (ev.get("repo") or "—").split("/")[-1]
        detail = (ev.get("detail") or "")[:48]
        lines.append(f"    {ts}  {evt:14} {repo:18} {detail}")
    lines.append("")
    lines.append("  24H TARGETS")
    lines.append("    • 4+ merged PRs across fleet repos")
    lines.append("    • Tower green (ruff + Orion AST)")
    lines.append("    • Grok MCP + gh auth persistent")
    lines.append("    • Airport survives reboot (systemd)")
    lines.append("")
    lines.append("  COMMANDS")
    lines.append("    mission validate        machine mirror + next action")
    lines.append("    mission validate --do   say it, then run it")
    lines.append("    mission --watch         live refresh")
    lines.append("    issue-agent-ui          interactive menu")
    lines.append("    issue-agent fix REPO N  force one fix")
    lines.append("    grok                    strategic agent (YOLO)")
    lines.append("")
    text = "\n".join(lines)
    if watch:
        os.system("clear")
    print(text)
    return 0


def main() -> int:
    if "validate" in sys.argv:
        return render_validate(do="--do" in sys.argv or "-d" in sys.argv)
    watch = "--watch" in sys.argv or "-w" in sys.argv
    if watch:
        try:
            while True:
                render(watch=True)
                time.sleep(5)
        except KeyboardInterrupt:
            return 0
    return render()


if __name__ == "__main__":
    raise SystemExit(main())