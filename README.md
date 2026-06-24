# Agent Habitat OS

**Agent-native engineering substrate** — boot a machine, authenticate once, and ship PRs with a hybrid cloud + local AI stack.

Cloud Grok plans and reviews. Local Ollama (7B) triages and executes. [Issue Agent](https://github.com/Nueramarcos/issue-agent) runs the fleet. Every action is flight-recorded.

```
┌─────────────────────────────────────────────────────────────┐
│  Ubuntu 24.04  →  first-boot  →  agent-ready workstation    │
│  ├─ Grok CLI (cloud brain)                                  │
│  ├─ Ollama 7B + 1.5B (local muscle)                         │
│  ├─ Issue Agent + Aider (autonomous PRs)                    │
│  ├─ Skills + AGENTS.md (portable agent rules)               │
│  └─ Flight recorder (audit trail)                           │
└─────────────────────────────────────────────────────────────┘
```

## Quick start (existing Ubuntu)

```bash
git clone https://github.com/Nueramarcos/agent-habitat-os.git
cd agent-habitat-os
./first-boot/install.sh
```

**Live repos:** [agent-habitat-os](https://github.com/Nueramarcos/agent-habitat-os) · [agent-habitat-demo](https://github.com/Nueramarcos/agent-habitat-demo) · [PR #2 merged](https://github.com/Nueramarcos/agent-habitat-demo/pull/2) · [issue #3](https://github.com/Nueramarcos/agent-habitat-demo/issues/3) (round 2)

Then:

```bash
habitat init        # wizard: gh, grok, repos.yaml
grok login          # or export XAI_API_KEY=...
gh auth login
habitat verify
habitat demo        # round 2: mean() bug — issue #3
habitat iso prepare # USB autoinstall for Ubuntu 24.04
```

**Goal:** `habitat verify` green → `issue-agent demo --dry-run` passes → first agent-merge in under an hour.

## Profiles

| Profile | Cloud | Local | Use case |
|---------|-------|-------|----------|
| `hybrid` (default) | Grok for plan/review | Ollama 7B for codegen/triage | Best balance |
| `minimal` | Off | Ollama only | Air-gap, privacy, no API cost |
| `cloud-only` | Grok for everything | Off | Fastest quality, cloud-dependent |

```bash
habitat profile set hybrid
habitat profile show
```

Routing rules live in [`routing.yaml`](routing.yaml).

## What's included

| Path | Purpose |
|------|---------|
| [`first-boot/install.sh`](first-boot/install.sh) | One-shot workstation setup |
| [`cockpit/`](cockpit/) | zsh, tools, Grok config, AGENTS.md templates |
| [`agent-runtime/`](agent-runtime/) | Issue Agent install + starter `repos.yaml` |
| [`flight-recorder/`](flight-recorder/) | JSONL audit schema |
| [`demo/agent-habitat-demo/`](demo/agent-habitat-demo/) | Intentional bugs for first agent-fix |
| [`iso/`](iso/) | Cubic ISO build guide + package list |

## Demo repo

The bundled demo has three deliberate bugs. Boot the stack, then:

```bash
cd demo/agent-habitat-demo
python3 -m pytest   # fails — that's the point
grok -p "Fix the failing tests in habitat/calc.py"
# or autonomous:
issue-agent fix Nueramarcos/agent-habitat-demo 1
```

## ISO build (optional)

For a bootable live image, see [`iso/README.md`](iso/README.md). The ISO wraps the same `first-boot/install.sh` — reproducible config is the product; the ISO is the demo.

## For engineering leads

**Time-to-first-merge:** clone → `install.sh` → `gh auth` → `grok login` → agent opens PR.

**Auditability:** `~/issue-agent/flight-recorder/trajectories.jsonl` logs every outcome (merge, `no_commits`, CI timeout).

**Hybrid policy:** route by task type in `routing.yaml` — triage stays local, architecture stays cloud.

**No vendor lock-in:** swap Grok for any OpenAI-compatible endpoint in `~/.grok/config.toml`. Local lane always works without cloud.

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `HABITAT_ROOT` | repo clone path | Install scripts root |
| `HABITAT_PROFILE` | `hybrid` | Active profile name |
| `ISSUE_AGENT_ROOT` | `~/issue-agent` | Agent runtime |
| `OLLAMA_HOST` | `http://127.0.0.1:11434` | Local inference |
| `XAI_API_KEY` | — | Grok cloud auth (optional in minimal) |

## Related projects

- [issue-agent](https://github.com/Nueramarcos/issue-agent) — autonomous GitHub fleet
- [Grok CLI](https://x.ai/cli) — cloud coding agent

## License

MIT — see [LICENSE](LICENSE). Grok and xAI APIs are separate products.