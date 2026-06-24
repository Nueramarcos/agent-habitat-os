#!/usr/bin/env bash
# Sync vendor modules into ~/issue-agent (public clone may lack local-only files).
set -euo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VENDOR="$HABITAT_ROOT/agent-runtime/vendor/issue-agent"
TARGET="${ISSUE_AGENT_HOME:-$HOME/issue-agent}"

log() { printf '\033[38;5;141m[sync]\033[0m %s\n' "$*"; }

[[ -d "$TARGET" ]] || { log "issue-agent not cloned yet — skip"; exit 0; }
[[ -d "$VENDOR" ]] || { log "no vendor bundle — skip"; exit 0; }

for f in "$VENDOR"/*.py; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  if [[ ! -f "$TARGET/$base" ]]; then
    cp -f "$f" "$TARGET/$base"
    log "installed $base"
  fi
done

# Required modules for issue_agent.py
missing=0
for mod in personality.py tower.py mission_control.py; do
  [[ -f "$TARGET/$mod" ]] || { log "missing $mod"; missing=$((missing+1)); }
done
[[ "$missing" -eq 0 ]] || exit 1
log "issue-agent modules complete"