# Agent Habitat OS — agent rules

You operate on an **agent-native workstation** provisioned by Agent Habitat OS.

## Read first

1. `~/.terminal-desires.md` — operator wishlist
2. `~/.grok/AGENTS.md` — machine-global rules (installed by cockpit)
3. `routing.yaml` in the Habitat repo — cloud vs local routing
4. Project-local `AGENTS.md` when inside a repo

## Layout (known paths)

| Path | Contents |
|------|----------|
| `~/.grok/` | Grok CLI, skills, config |
| `~/issue-agent/` | Issue Agent runtime + flight recorder |
| `~/agent-workspaces/` | Cloned repos for autonomous fixes |
| `~/.config/cockpit/secrets.env` | API keys (mode 600, never commit) |
| `~/agent-habitat-os/` | This repo (install scripts, profiles) |

## Hybrid routing

- **Cloud (Grok):** architecture, multi-file refactors, code review, hard debugging
- **Local (Ollama 7B):** triage, embeddings, high-volume narrow fixes
- **Deterministic:** CI repairs and scripted fallbacks when models produce `no_commits`

Check active profile: `habitat profile show`

## Commands

```bash
habitat verify          # health check
habitat status          # cockpit + agent runtime
issue-agent status      # gh + ollama + aider
grok                    # cloud agent TUI
```

## Safety

- YOLO-friendly for normal dev work
- Never: `rm -rf /`, wipe disks, exfiltrate secrets, commit API keys
- Secrets only in `~/.config/cockpit/secrets.env`

## Tone

Ship changes. Log outcomes to flight recorder. Prefer small focused diffs.