#!/usr/bin/env bash
# Agent Habitat OS — first-boot provisioning
set -euo pipefail

HABITAT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export HABITAT_ROOT
PROFILE="${HABITAT_PROFILE:-hybrid}"
export HABITAT_PROFILE="$PROFILE"

log() { printf '\033[38;5;141m[habitat]\033[0m %s\n' "$*"; }
die() { printf '\033[31m[habitat] error:\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f /etc/os-release ]] && source /etc/os-release
if [[ "${ID:-}" != "ubuntu" && "${ID_LIKE:-}" != *"debian"* ]]; then
  log "warning: tested on Ubuntu 24.04; continuing on ${PRETTY_NAME:-unknown}"
fi

log "Agent Habitat OS first-boot"
log "  root:    $HABITAT_ROOT"
log "  profile: $PROFILE"
log "  user:    ${USER:-unknown}"

bash "$HABITAT_ROOT/first-boot/ensure.sh" || true

# ── apt base ─────────────────────────────────────────────────────────────
if command -v apt-get >/dev/null 2>&1; then
  log "Installing base packages..."
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    git curl wget jq zsh build-essential python3 python3-venv python3-pip \
    ca-certificates gnupg unzip ripgrep fd-find 2>/dev/null || \
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    git curl wget jq zsh build-essential python3 python3-venv python3-pip \
    ca-certificates gnupg unzip ripgrep fd-find
fi

# Default shell → zsh (optional, non-fatal)
if command -v zsh >/dev/null && [[ "${SHELL:-}" != *zsh* ]]; then
  if chsh -s "$(command -v zsh)" 2>/dev/null; then
    log "Default shell set to zsh (open a new terminal)"
  fi
fi

mkdir -p "$HOME/.config/cockpit" "$HOME/bin" "$HOME/.local/bin" "$HOME/agent-workspaces"
chmod 700 "$HOME/.config/cockpit"
touch "$HOME/.config/cockpit/secrets.env"
chmod 600 "$HOME/.config/cockpit/secrets.env"

# ── profile-driven installs ──────────────────────────────────────────────
install_grok=true
install_local=true
install_issue_agent=true

case "$PROFILE" in
  minimal)
    install_grok=false
    ;;
  cloud-only)
    install_local=false
    install_issue_agent=false
    ;;
  hybrid|*)
    ;;
esac

# ── cockpit (zsh, tools, grok templates) ─────────────────────────────────
log "Installing cockpit..."
HABITAT_PROFILE="$PROFILE" HABITAT_INSTALL_GROK="$install_grok" \
  bash "$HABITAT_ROOT/cockpit/install.sh" || log "cockpit had warnings — habitat doctor can repair"

# ── agent runtime (issue-agent + ollama) ─────────────────────────────────
if [[ "$install_issue_agent" == true ]]; then
  log "Installing agent runtime..."
  HABITAT_PROFILE="$PROFILE" bash "$HABITAT_ROOT/agent-runtime/install.sh"
  if [[ -x "$HABITAT_ROOT/agent-runtime/configure-model-tier.sh" ]]; then
    bash "$HABITAT_ROOT/agent-runtime/configure-model-tier.sh" || true
  fi
fi

# ── git identity (VM pushes / agent commits) ─────────────────────────────
if ! git config --global user.email >/dev/null 2>&1; then
  git config --global user.email "${HABITAT_GIT_EMAIL:-$(id -un)@$(hostname -s 2>/dev/null || echo local).local}"
fi
if ! git config --global user.name >/dev/null 2>&1; then
  git config --global user.name "${HABITAT_GIT_NAME:-Agent Habitat ($(id -un))}"
fi

# ── habitat CLI ──────────────────────────────────────────────────────────
install -m 755 "$HABITAT_ROOT/scripts/habitat" "$HOME/bin/habitat"
grep -q 'agent-habitat-os' "$HOME/.zsh/20-habitat.zsh" 2>/dev/null || \
  cp "$HABITAT_ROOT/cockpit/zsh/20-habitat.zsh" "$HOME/.zsh/20-habitat.zsh" 2>/dev/null || true

# Persist profile (cloud-init runcmd may leave profile root-owned)
mkdir -p "$HOME/.config/agent-habitat"
if [[ -e "$HOME/.config/agent-habitat/profile" ]] && [[ ! -w "$HOME/.config/agent-habitat/profile" ]]; then
  sudo chown -R "$(id -un):$(id -gn)" "$HOME/.config/agent-habitat" 2>/dev/null || true
fi
echo "$PROFILE" > "$HOME/.config/agent-habitat/profile"

# Symlink routing for agents
ln -sf "$HABITAT_ROOT/routing.yaml" "$HOME/.config/agent-habitat/routing.yaml"

# ── verify ───────────────────────────────────────────────────────────────
log "Running verify..."
bash "$HABITAT_ROOT/first-boot/verify.sh" || true

cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║  Agent Habitat OS — first-boot complete                      ║
╚══════════════════════════════════════════════════════════════╝

  Profile:  $PROFILE
  Verify:   habitat verify
  Status:   habitat status

  Next steps:
    $( [[ "$install_grok" == true ]] && echo 'grok login    # or export XAI_API_KEY=...' )
    gh auth login
    habitat demo

  Docs: $HABITAT_ROOT/README.md

EOF