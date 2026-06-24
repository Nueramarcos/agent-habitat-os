#!/usr/bin/env bash
# Manual install with logging — use when systemd firstboot fails in VM.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="${HABITAT_INSTALL_LOG:-$HOME/habitat-install.log}"

exec > >(tee -a "$LOG") 2>&1
echo "==> habitat manual install $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "    log: $LOG"

export HABITAT_ROOT="$REPO"
export HABITAT_PROFILE="${HABITAT_PROFILE:-hybrid}"
export HABITAT_LIGHT="${HABITAT_LIGHT:-1}"
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

bash "$REPO/first-boot/install.sh" || {
  echo ""
  echo "==> install exited non-zero — see $LOG"
  echo "    common fix: ollama serve &  then  ollama pull qwen2.5-coder:1.5b"
  exit 1
}

touch "$HOME/.habitat-provisioned"
echo "==> done — run: habitat verify"