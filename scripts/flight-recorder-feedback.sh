#!/usr/bin/env bash
# Learn from recent issue-agent outcomes — tune model tier and log hints.
set -euo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TRAJ="${ISSUE_AGENT_ROOT:-$HOME/issue-agent}/flight-recorder/trajectories.jsonl"
OUT="$HOME/.config/agent-habitat/feedback.yaml"
mkdir -p "$(dirname "$OUT")"

log() { printf '[feedback] %s\n' "$*"; }

[[ -f "$TRAJ" ]] || { log "no trajectories yet — skip"; exit 0; }

python3 <<PY
import json, pathlib, time
from collections import Counter

traj = pathlib.Path("$TRAJ")
lines = traj.read_text(encoding="utf-8", errors="replace").strip().splitlines()[-40:]
events = []
for line in lines:
    line = line.strip()
    if not line:
        continue
    try:
        events.append(json.loads(line))
    except json.JSONDecodeError:
        pass

kinds = Counter()
for e in events:
    o = str(e.get("outcome", e.get("kind", "")))
    hint = str(e.get("hint", e.get("detail", ""))).lower()
    if "no_commits" in o or "no_commits" in hint:
        kinds["no_commits"] += 1
    elif "test" in hint or "tests failed" in hint:
        kinds["tests_failed"] += 1
    elif "tower" in o or "tower" in hint:
        kinds["tower_reject"] += 1
    elif "merge" in o or e.get("outcome") == "merged_pr":
        kinds["merge_success"] += 1
    elif "timeout" in hint or "oom" in hint:
        kinds["oom_timeout"] += 1

total = max(len(events), 1)
fail_rate = sum(kinds[k] for k in ("no_commits", "tests_failed", "tower_reject", "oom_timeout")) / total
oom = kinds["oom_timeout"]

out = pathlib.Path("$OUT")
lines_out = [
    f"# Auto-generated {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}",
    f"window_events: {len(events)}",
    f"fail_rate: {fail_rate:.2f}",
    f"no_commits: {kinds['no_commits']}",
    f"tests_failed: {kinds['tests_failed']}",
    f"tower_reject: {kinds['tower_reject']}",
    f"merge_success: {kinds['merge_success']}",
    f"oom_timeout: {oom}",
]
out.write_text("\n".join(lines_out) + "\n", encoding="utf-8")

print(f"fail_rate={fail_rate:.0%} merges={kinds['merge_success']} oom={oom}")
PY

# Force lighter model if recent OOM/timeouts or high fail rate with 7B host
if python3 -c "
import pathlib, re
p = pathlib.Path('$OUT')
if not p.exists():
    raise SystemExit(0)
t = p.read_text()
oom = int(re.search(r'oom_timeout: (\d+)', t).group(1)) if 'oom_timeout' in t else 0
fr = float(re.search(r'fail_rate: ([0-9.]+)', t).group(1)) if 'fail_rate' in t else 0
raise SystemExit(1 if oom >= 2 or fr >= 0.6 else 0)
" 2>/dev/null; then
  export HABITAT_LIGHT=1
  bash "$HABITAT_ROOT/agent-runtime/configure-model-tier.sh" || true
  log "tuned model tier → 1.5B (recent failures)"
fi