#!/usr/bin/env bash
# Unified preflight + repair — fixes all known install/VM issues idempotently.
set -uo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
log() { printf '\033[38;5;141m[ensure]\033[0m %s\n' "$*"; }

# ── ownership (cloud-init runcmd often leaves ~/bin or ~/.config root-owned) ─
for d in "$HOME/bin" "$HOME/.config" "$HOME/.local" "$HOME/.config/agent-habitat"; do
  if [[ -d "$d" ]] && [[ ! -w "$d" ]]; then
    log "Fixing ownership of $d"
    sudo chown -R "$(id -un):$(id -gn)" "$d" 2>/dev/null || true
  fi
done
mkdir -p "$HOME/bin" "$HOME/.local/bin" "$HOME/.grok/bin" "$HOME/.config/cockpit" "$HOME/agent-workspaces"
chmod 700 "$HOME/.config/cockpit" 2>/dev/null || true
touch "$HOME/.config/cockpit/secrets.env" 2>/dev/null || sudo touch "$HOME/.config/cockpit/secrets.env" 2>/dev/null || true
sudo chown "$(id -un):$(id -gn)" "$HOME/.config/cockpit/secrets.env" 2>/dev/null || true
chmod 600 "$HOME/.config/cockpit/secrets.env" 2>/dev/null || true

# Bash SSH sessions (session-b, paramiko) need grok on PATH
if [[ -f "$HABITAT_ROOT/first-boot/bash-path.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HABITAT_ROOT/first-boot/bash-path.sh"
  if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'first-boot/bash-path.sh' "$HOME/.bashrc" 2>/dev/null; then
    echo '[[ -f "$HOME/agent-habitat-os/first-boot/bash-path.sh" ]] && source "$HOME/agent-habitat-os/first-boot/bash-path.sh"' >> "$HOME/.bashrc"
  fi
fi

# ── disk (LVM half-allocated on 32G QEMU disks) ───────────────────────────
if [[ -x "$HABITAT_ROOT/first-boot/expand-disk.sh" ]]; then
  bash "$HABITAT_ROOT/first-boot/expand-disk.sh" || true
fi

# ── RAM → model tier (4GB guests use light install) ──────────────────────
if [[ -z "${HABITAT_LIGHT:-}" ]]; then
  mem_gb="$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 8)"
  if [[ "$mem_gb" -lt 6 ]]; then
    export HABITAT_LIGHT=1
    log "RAM ${mem_gb}GB — HABITAT_LIGHT=1 (1.5B model only)"
  fi
fi

# ── gh git credentials (VM push needs this) ──────────────────────────────
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh auth setup-git 2>/dev/null || true
fi

# ── routing.yaml (verify checks ~/.config/agent-habitat/routing.yaml) ────
if [[ -n "${HABITAT_ROOT:-}" && -f "$HABITAT_ROOT/routing.yaml" ]]; then
  mkdir -p "$HOME/.config/agent-habitat"
  ln -sf "$HABITAT_ROOT/routing.yaml" "$HOME/.config/agent-habitat/routing.yaml"
fi

# ── issue-agent module completeness ──────────────────────────────────────
if [[ -d "$HOME/issue-agent" ]] && [[ -x "$HABITAT_ROOT/agent-runtime/sync-issue-agent.sh" ]]; then
  bash "$HABITAT_ROOT/agent-runtime/sync-issue-agent.sh" || true
fi
if [[ -x "$HABITAT_ROOT/agent-runtime/configure-model-tier.sh" ]]; then
  bash "$HABITAT_ROOT/agent-runtime/configure-model-tier.sh" || true
fi

# ── GITHUB_TOKEN blocks gh on host ───────────────────────────────────────
if [[ -n "${GITHUB_TOKEN:-}" ]] && gh auth status 2>&1 | grep -q 'invalid'; then
  log "hint: unset GITHUB_TOKEN for gh — use: env -u GITHUB_TOKEN gh auth status"
fi

log "ensure complete (profile=${HABITAT_PROFILE:-hybrid}, light=${HABITAT_LIGHT:-0})"