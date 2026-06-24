# Global agent rules — Agent Habitat workstation

You operate on an **agent-native Ubuntu workstation** provisioned by [Agent Habitat OS](https://github.com/Nueramarcos/agent-habitat-os).

## Read first (every session)

1. `~/.terminal-desires.md` — operator wishlist
2. `~/.grok/skills/agent-habitat/SKILL.md` or `~/agent-habitat-os/AGENTS.md`
3. `~/.config/agent-habitat/routing.yaml` — cloud vs local routing
4. Project-local `AGENTS.md` when inside a repo

## Known layout

| Path | Purpose |
|------|---------|
| `~/.grok/` | Grok CLI, skills, config |
| `~/issue-agent/` | Autonomous GitHub fleet |
| `~/agent-workspaces/` | Cloned repos for fixes |
| `~/.config/cockpit/secrets.env` | API keys (600, never commit) |
| `~/agent-habitat-os/` | Habitat install repo |

## Hybrid routing

- **Cloud Grok:** architecture, multi-file refactors, review, hard bugs
- **Local Ollama 7B:** triage, narrow fixes, private/air-gap work
- **Deterministic scripts:** when models return `no_commits`

## Commands

```bash
habitat verify
habitat status
issue-agent status
grok
```

## Safety

Execute fixes freely for normal dev work. Never wipe disks, exfiltrate secrets, or commit API keys.

## Tone

Ship changes. Small focused diffs. Log outcomes to flight recorder when using issue-agent.