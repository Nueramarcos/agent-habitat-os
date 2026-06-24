"""Personality quiz — match operator vibe to upstream scout opportunities."""

from __future__ import annotations

from typing import Any

ARCHETYPES: dict[str, dict[str, Any]] = {
    "emulator_surgeon": {
        "name": "Emulator Surgeon",
        "emoji": "🧪",
        "blurb": "You live in mock-GPU and compiler emu lanes — drift hunts, green CI without silicon drama.",
        "tag_boost": {"emulator", "mockgpu", "amd", "compiler"},
        "effort_pref": {"s", "m"},
        "hardware_pref": {"amd", "any"},
    },
    "silicon_locksmith": {
        "name": "Silicon Locksmith",
        "emoji": "🔓",
        "blurb": "ROCm gaps and unsupported arch sting. You unlock AMD paths in vision and compiler stacks.",
        "tag_boost": {"rocm", "hardware", "amd", "rdna"},
        "effort_pref": {"m", "l"},
        "hardware_pref": {"gfx1010", "amd"},
    },
    "one_shot_sniper": {
        "name": "One-Shot Sniper",
        "emoji": "🎯",
        "blurb": "Fifteen minutes, one assert, one merged PR. Small bugs and build hygiene are your prey.",
        "tag_boost": {"good-first", "bug", "build"},
        "effort_pref": {"xs", "s"},
        "hardware_pref": {"any"},
    },
    "dtype_alchemist": {
        "name": "Dtype Alchemist",
        "emoji": "⚗️",
        "blurb": "bf16 soft-promote, typing edges, clang quirks — you fix the type system when it lies.",
        "tag_boost": {"dtype", "clang", "typing", "good-first"},
        "effort_pref": {"s", "m"},
        "hardware_pref": {"any"},
    },
    "vision_phantom": {
        "name": "Vision Phantom",
        "emoji": "👁️",
        "blurb": "Faces, pipelines, labeling throughput — you ship CV fixes between coffee refills.",
        "tag_boost": {"vision", "pytorch", "computer-vision", "pipeline"},
        "effort_pref": {"s", "m"},
        "hardware_pref": {"any"},
    },
    "airport_captain": {
        "name": "Airport Captain",
        "emoji": "🛫",
        "blurb": "CI badges, forge reliability, cron lanes — you keep the fleet moving while AFK.",
        "tag_boost": {"ci", "devops", "documentation", "good-first"},
        "effort_pref": {"xs", "s"},
        "hardware_pref": {"any"},
    },
}

QUESTIONS: list[dict[str, Any]] = [
    {
        "id": "friday",
        "prompt": "Friday night energy?",
        "choices": {
            "a": ("One perfect 3-line fix, then sleep", {"one_shot_sniper": 3, "dtype_alchemist": 1}),
            "b": ("Unlock my GPU on real hardware", {"silicon_locksmith": 3, "emulator_surgeon": 1}),
            "c": ("Green CI + merge before midnight", {"airport_captain": 3, "one_shot_sniper": 1}),
            "d": ("Mock-GPU lanes until emu matches silicon", {"emulator_surgeon": 3, "silicon_locksmith": 1}),
        },
    },
    {
        "id": "test_output",
        "prompt": "Your ideal test output?",
        "choices": {
            "a": ("815 passed under mock AMD backend", {"emulator_surgeon": 3}),
            "b": ("assert math.isnan(...)", {"one_shot_sniper": 3, "dtype_alchemist": 1}),
            "c": ("Device.DEFAULT prints AMD", {"silicon_locksmith": 3}),
            "d": ("Green check on GitHub Actions", {"airport_captain": 3}),
        },
    },
    {
        "id": "heartbreak",
        "prompt": "What breaks your heart?",
        "choices": {
            "a": ("NaN silently wrong", {"one_shot_sniper": 2, "dtype_alchemist": 2}),
            "b": ('"Unsupported arch"', {"silicon_locksmith": 3}),
            "c": ("CI red for a README typo", {"airport_captain": 3}),
            "d": ("Face pipeline drops frames at 2am", {"vision_phantom": 3}),
        },
    },
    {
        "id": "patience",
        "prompt": "Patience budget?",
        "choices": {
            "a": ("≤15 min — ship or skip", {"one_shot_sniper": 3, "airport_captain": 1}),
            "b": ("Weekend — one meaty arch fix", {"silicon_locksmith": 2, "emulator_surgeon": 2}),
            "c": ("Multi-week bounty grind OK", {"emulator_surgeon": 2, "silicon_locksmith": 2}),
            "d": ("Whatever the Airport cron queued", {"airport_captain": 3}),
        },
    },
    {
        "id": "workstation",
        "prompt": "Workstation vibe?",
        "choices": {
            "a": ("RX 5700 XT battle station (gfx1010)", {"silicon_locksmith": 3, "emulator_surgeon": 1}),
            "b": ("Pure CPU/mock — no GPU drama", {"dtype_alchemist": 2, "one_shot_sniper": 2}),
            "c": ("Labeling faces + CV hacks", {"vision_phantom": 3}),
            "d": ("Issue Agent Airport doing laps", {"airport_captain": 2, "emulator_surgeon": 1}),
        },
    },
]

FLEET_FALLBACKS: list[dict[str, Any]] = [
    {
        "repo": "Nueramarcos/forge-ci-reliability",
        "number": 0,
        "title": "Add CONTRIBUTING.md with forge dev workflow",
        "url": "https://github.com/Nueramarcos/forge-ci-reliability",
        "score": 70,
        "tier": 1,
        "effort": "xs",
        "tags": ["ci", "documentation", "good-first"],
        "why": "Airport Captain lane — one-file doc fix, tests green in minutes.",
        "test_hint": "python3 -m pytest -q",
        "archetype": "airport_captain",
    },
    {
        "repo": "Nueramarcos/nexus-vision-engine",
        "number": 0,
        "title": "Add pytest smoke test for vision pipeline",
        "url": "https://github.com/Nueramarcos/nexus-vision-engine",
        "score": 68,
        "tier": 1,
        "effort": "s",
        "tags": ["vision", "pipeline", "computer-vision"],
        "why": "Vision Phantom lane — CV smoke tests on your labeling stack.",
        "test_hint": "python3 -m pytest -q",
        "archetype": "vision_phantom",
    },
    {
        "repo": "pytorch/vision",
        "number": 9450,
        "title": "Rotated bounding box NMS implementation for CPU",
        "url": "https://github.com/pytorch/vision/issues/9450",
        "score": 76,
        "tier": 2,
        "effort": "m",
        "tags": ["pytorch", "vision", "good-first", "cpu"],
        "why": "Vision Phantom upstream — CPU NMS pairs with ai-labeler face/bbox work.",
        "test_hint": "python3 -m pytest -q",
        "archetype": "vision_phantom",
    },
    {
        "repo": "pytorch/vision",
        "number": 9342,
        "title": "[ROCM] Add rocjpeg support for GPU image decoding",
        "url": "https://github.com/pytorch/vision/issues/9342",
        "score": 80,
        "tier": 2,
        "effort": "l",
        "tags": ["pytorch", "vision", "amd", "rocm"],
        "hardware_fit": ["amd", "gfx1010"],
        "why": "Silicon Locksmith lane — ROCm decode on your RX 5700 XT stack.",
        "test_hint": "python3 -m pytest -q",
        "archetype": "silicon_locksmith",
    },
]


def _blank_scores() -> dict[str, int]:
    return {k: 0 for k in ARCHETYPES}


def tally_answers(answers: dict[str, str]) -> dict[str, int]:
    scores = _blank_scores()
    for q in QUESTIONS:
        choice = (answers.get(q["id"]) or "").lower()
        spec = q["choices"].get(choice)
        if not spec:
            continue
        _label, boosts = spec
        for archetype, pts in boosts.items():
            scores[archetype] = scores.get(archetype, 0) + pts
    return scores


def top_archetype(scores: dict[str, int]) -> tuple[str, dict[str, Any]]:
    key = max(scores, key=lambda k: scores[k])
    return key, ARCHETYPES[key]


def score_opportunity(item: dict[str, Any], archetype_key: str, archetype: dict[str, Any]) -> float:
    base = float(item.get("score") or 0)
    tags = {t.lower() for t in item.get("tags") or []}
    title = (item.get("title") or "").lower()
    effort = str(item.get("effort") or "").lower()
    fit = {f.lower() for f in item.get("hardware_fit") or []}

    bonus = 0.0
    for tag in archetype.get("tag_boost") or []:
        if tag in tags or tag in title:
            bonus += 8.0
    if effort in (archetype.get("effort_pref") or set()):
        bonus += 5.0
    for hw in archetype.get("hardware_pref") or []:
        if hw in fit or hw in title:
            bonus += 6.0
    status = (item.get("status") or "").lower()
    if status == "open":
        bonus += 3.0
    elif status in ("pr-open", "pr_open"):
        bonus += 1.0
    tier = int(item.get("tier") or 9)
    if tier == 1:
        bonus += 4.0
    return base + bonus


def match_opportunity(
    items: list[dict[str, Any]],
    scores: dict[str, int],
) -> tuple[str, dict[str, Any], dict[str, Any], float]:
    archetype_key, archetype = top_archetype(scores)
    pool = items or []
    if not pool:
        for fb in FLEET_FALLBACKS:
            if fb.get("archetype") == archetype_key:
                return archetype_key, archetype, fb, float(fb.get("score") or 0)
        fb = FLEET_FALLBACKS[0]
        return fb["archetype"], ARCHETYPES[fb["archetype"]], fb, float(fb.get("score") or 0)

    ranked = sorted(
        pool,
        key=lambda it: score_opportunity(it, archetype_key, archetype),
        reverse=True,
    )
    best = ranked[0]
    best_score = score_opportunity(best, archetype_key, archetype)
    return archetype_key, archetype, best, best_score


def compose_quiz_post() -> str:
    lines = [
        "🧬 Habitat Solver personality test — which OSS issue is *your* lane?",
        "",
        "Reply A/B/C/D to each (or run locally: issue-agent personality)",
        "",
    ]
    for i, q in enumerate(QUESTIONS, 1):
        lines.append(f"{i}. {q['prompt']}")
        for key, (label, _) in q["choices"].items():
            lines.append(f"   {key.upper()}) {label}")
        lines.append("")
    lines.append("I'll match you to a scored upstream issue + test command.")
    lines.append("github.com/Nueramarcos/issue-agent")
    text = "\n".join(lines)
    return text[:280] if len(text) > 280 else text


def compose_quiz_thread() -> list[str]:
    """Full quiz as a thread (one tweet per question + intro)."""
    posts: list[str] = []
    intro = (
        "🧬 Habitat Solver personality test\n\n"
        "5 questions → your OSS archetype + a scored target issue.\n"
        "Reply A/B/C/D per tweet. (Or: issue-agent personality)\n\n"
        "1/6 ↓"
    )
    posts.append(intro[:280])
    for i, q in enumerate(QUESTIONS, 2):
        chunk = f"{i}/6 {q['prompt']}\n\n"
        for key, (label, _) in q["choices"].items():
            chunk += f"{key.upper()}) {label}\n"
        posts.append(chunk.strip()[:280])
    posts.append(
        "6/6 Drop your 5-letter code (e.g. abdca) — I'll reply with your archetype + hunt target.\n"
        "Local: issue-agent personality --answers abdca"
    )
    return posts


def compose_result_post(
    archetype_key: str,
    archetype: dict[str, Any],
    item: dict[str, Any],
    *,
    answers_code: str = "",
) -> str:
    emoji = archetype.get("emoji") or "🧬"
    name = archetype.get("name") or archetype_key
    repo = item.get("repo") or "?"
    num = item.get("number") or 0
    title = (item.get("title") or "")[:72]
    url = item.get("url") or ""
    code = f" [{answers_code.upper()}]" if answers_code else ""
    lines = [
        f"{emoji} Archetype: {name}{code}",
        "",
        archetype.get("blurb", "")[:100],
        "",
        f"Target: {repo} #{num}" if num else f"Target: {repo}",
        title,
    ]
    if url:
        lines.append(url)
    text = "\n".join(lines)
    return text[:280] if len(text) > 280 else text


def format_result(
    archetype_key: str,
    archetype: dict[str, Any],
    item: dict[str, Any],
    match_score: float,
    scores: dict[str, int],
) -> str:
    emoji = archetype.get("emoji") or "🧬"
    lines = [
        f"{emoji} You are: {archetype.get('name')} ({archetype_key})",
        f"   {archetype.get('blurb', '')}",
        "",
        "Scoreboard:",
    ]
    for k, v in sorted(scores.items(), key=lambda x: -x[1]):
        mark = "←" if k == archetype_key else " "
        lines.append(f"  {mark} {ARCHETYPES[k]['name']}: {v}")
    lines.extend(
        [
            "",
            f"Your lane — match {match_score:.0f}",
            f"  {item.get('repo')} #{item.get('number')}",
            f"  {item.get('title', '')}",
        ]
    )
    if item.get("why"):
        lines.append(f"  → {item['why']}")
    if item.get("test_hint"):
        lines.append(f"  $ {item['test_hint']}")
    if item.get("url"):
        lines.append(f"  {item['url']}")
    lines.append("")
    lines.append("Next: issue-agent hunt --enqueue 1")
    return "\n".join(lines)


def run_interactive_quiz() -> dict[str, str]:
    answers: dict[str, str] = {}
    print("Habitat Solver — personality test\n")
    for q in QUESTIONS:
        print(q["prompt"])
        for key, (label, _) in q["choices"].items():
            print(f"  {key}) {label}")
        while True:
            raw = input("> ").strip().lower()
            if raw in q["choices"]:
                answers[q["id"]] = raw
                break
            print("  pick a/b/c/d")
        print()
    return answers


def answers_code(answers: dict[str, str]) -> str:
    order = [q["id"] for q in QUESTIONS]
    by_id = {q["id"]: q for q in QUESTIONS}
    return "".join(answers.get(qid, "?") for qid in order if qid in by_id)