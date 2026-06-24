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

**Live repos:** [agent-habitat-os](https://github.com/Nueramarcos/agent-habitat-os) · [agent-habitat-demo](https://github.com/Nueramarcos/agent-habitat-demo)

Then:

```bash
habitat init          # wizard: gh, grok, repos.yaml
grok login            # or export XAI_API_KEY=...
gh auth login
habitat verify        # 16 checks
habitat demo          # 17 pytest (demo repo)
```

**Goal:** `habitat verify` green → `issue-agent fix` opens a PR → CI merges in under an hour.

## Agent demo chain (6 rounds — all merged)

| Round | Bug | Issue | PR |
|-------|-----|-------|-----|
| 1 | calc regressions | [#1](https://github.com/Nueramarcos/agent-habitat-demo/issues/1) | [#2](https://github.com/Nueramarcos/agent-habitat-demo/pull/2) |
| 2 | `mean()` floor division | [#3](https://github.com/Nueramarcos/agent-habitat-demo/issues/3) | [#4](https://github.com/Nueramarcos/agent-habitat-demo/pull/4) |
| 3 | `median()` even-length | [#5](https://github.com/Nueramarcos/agent-habitat-demo/issues/5) | [#6](https://github.com/Nueramarcos/agent-habitat-demo/pull/6) |
| 4 | `mode()` wrong frequency | [#7](https://github.com/Nueramarcos/agent-habitat-demo/issues/7) | [#8](https://github.com/Nueramarcos/agent-habitat-demo/pull/8) |
| 5 | `variance()` sample vs population | — | [main](https://github.com/Nueramarcos/agent-habitat-demo) |
| 6 | `stddev()` no sqrt | [#9](https://github.com/Nueramarcos/agent-habitat-demo/issues/9) | [#10](https://github.com/Nueramarcos/agent-habitat-demo/pull/10) |

Run the next round:

```bash
issue-agent fix Nueramarcos/agent-habitat-demo <issue>
```

## QEMU VM (tested)

Boot an agent-ready VM from the Ubuntu 24.04 server ISO:

```bash
habitat iso prepare      # autoinstall seed files
habitat iso download     # Ubuntu 24.04 server ISO (~3.3 GB)
habitat iso vm-gui       # GUI install (or habitat iso vm headless)
habitat iso boot-disk    # boot installed qcow2 (8 GB RAM default)
habitat iso peek         # host-side health check
habitat iso ssh          # SSH (user: your installer username)
```

Manual GUI install? See [docs/POST-INSTALL.md](docs/POST-INSTALL.md) — run `first-boot/provision.sh` inside the guest.

**Proven on QEMU:** 16/16 `habitat verify`, 17/17 `habitat demo`, Ollama 7B + Issue Agent, CI green on GitHub Actions.

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
| [`first-boot/provision.sh`](first-boot/provision.sh) | Manual/GUI install provisioning |
| [`cockpit/`](cockpit/) | zsh, tools, Grok config, AGENTS.md templates |
| [`agent-runtime/`](agent-runtime/) | Issue Agent install + starter `repos.yaml` |
| [`flight-recorder/`](flight-recorder/) | JSONL audit schema |
| [`demo/agent-habitat-demo/`](demo/agent-habitat-demo/) | Intentional bugs for agent-fix demos |
| [`iso/`](iso/) | Autoinstall, QEMU helpers, USB seed |
| [`docs/POST-INSTALL.md`](docs/POST-INSTALL.md) | VM post-install checklist |

## CI

Both repos run GitHub Actions on push:

- **agent-habitat-os** — smoke checks + demo pytest (17 tests)
- **agent-habitat-demo** — demo pytest

Enable workflow scope once, then:

```bash
env -u GITHUB_TOKEN gh auth refresh -h github.com -s workflow,repo
habitat ci-setup    # pushes demo CI if missing
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
| `QEMU_MEM` | `8192` | VM RAM for `habitat iso boot-disk` |

## Related projects

- [issue-agent](https://github.com/Nueramarcos/issue-agent) — autonomous GitHub fleet
- [Grok CLI](https://x.ai/cli) — cloud coding agent

## License

MIT — see [LICENSE](LICENSE). Grok and xAI APIs are separate products.