#!/usr/bin/env bash
# habitat flawless — one-shot flawless autonomy setup + verify
set -euo pipefail
HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ISSUE_AGENT_ROOT="${ISSUE_AGENT_ROOT:-$HOME/issue-agent}"
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

log() { printf '\033[38;5;141m[flawless]\033[0m %s\n' "$*"; }
FAIL=0

check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    log "✓ $name"
  else
    log "✗ $name"
    FAIL=1
  fi
}

log "═══ Flawless Autonomy Setup ═══"

# 1. Notify-zero (quiet GitHub, demo lane)
bash "$ISSUE_AGENT_ROOT/scripts/notify-zero.sh" 2>&1 | sed 's/^/[notify-zero] /'

# 2. Human reviewer model
if ollama list 2>/dev/null | grep -q 'customs-reviewer-ft'; then
  log "✓ customs-reviewer-ft-1.5b"
else
  log "training reviewer model..."
  bash "$ISSUE_AGENT_ROOT/scripts/lora-train-reviewer.sh" 2>&1 | tail -3
fi

# 3. Secrets: quiet + retries
SECRETS="$HOME/.config/cockpit/secrets.env"
touch "$SECRETS"
grep -q ISSUE_AGENT_GITHUB_QUIET "$SECRETS" 2>/dev/null || echo 'export ISSUE_AGENT_GITHUB_QUIET=1' >>"$SECRETS"
grep -q HABITAT_MAX_FIX_RETRIES "$SECRETS" 2>/dev/null || echo 'export HABITAT_MAX_FIX_RETRIES=3' >>"$SECRETS"

# 4. Health
check "habitat verify" habitat verify
check "habitat demo" habitat demo
check "human-review corpus 200+" python3 -c "
from pathlib import Path
p=Path('$ISSUE_AGENT_ROOT/flight-recorder/human-reviews.jsonl')
n=len(p.read_text().splitlines()) if p.exists() else 0
raise SystemExit(0 if n>=200 else 1)
"
check "ollama API" curl -sf http://127.0.0.1:11434/api/tags
check "aider" test -x "$HOME/.local/venvs/aider/bin/aider"
check "gh auth" sh -c 'env -u GITHUB_TOKEN gh auth status'
check "habitat planner" test -f "$ISSUE_AGENT_ROOT/habitat_planner/plan.py"
check "notify-zero" grep -q ISSUE_AGENT_GITHUB_QUIET=1 "$SECRETS"

log ""
log "═══ Flawless pipeline ═══"
log "  habitat plan <repo> <issue>   → understand + plan (local)"
log "  habitat fix <repo> <issue>    → plan → fix → retry → merge"
log "  failures → flight-recorder only (no Gmail)"
log ""

if [[ "$FAIL" -eq 0 ]]; then
  log "FLAWLESS READY"
  exit 0
fi
log "FLAWLESS INCOMPLETE — fix checks above"
exit 1