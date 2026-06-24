#!/usr/bin/env bash
# Agent Habitat OS — first-time setup wizard (non-interactive friendly)
set -euo pipefail

HABITAT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config/agent-habitat"
PROFILE="${HABITAT_PROFILE:-$(cat "$CONFIG_DIR/profile" 2>/dev/null || echo hybrid)}"
GH_USER="${HABITAT_GH_USER:-}"
DEMO_REPO="${HABITAT_DEMO_REPO:-Nueramarcos/agent-habitat-demo}"
FLEET_REPO="${HABITAT_FLEET_REPO:-}"

log() { printf '\033[38;5;141m[habitat init]\033[0m %s\n' "$*"; }
step_ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
step_warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Agent Habitat — init wizard                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

mkdir -p "$CONFIG_DIR"
echo "$PROFILE" > "$CONFIG_DIR/profile"
ln -sf "$HABITAT_ROOT/routing.yaml" "$CONFIG_DIR/routing.yaml"
step_ok "profile=$PROFILE"

# GitHub user
if [[ -z "$GH_USER" ]] && command -v gh >/dev/null; then
  GH_USER="$(gh api user -q .login 2>/dev/null || true)"
fi
if [[ -n "$GH_USER" ]]; then
  step_ok "GitHub user: $GH_USER"
else
  step_warn "GitHub user unknown — run: gh auth login"
fi

# gh auth
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  step_ok "gh authenticated"
else
  step_warn "gh not authenticated — run: gh auth login"
fi

# Grok
if command -v grok >/dev/null 2>&1; then
  if [[ -f "$HOME/.grok/auth.json" ]] || [[ -n "${XAI_API_KEY:-}" ]]; then
    step_ok "Grok credentials present"
  else
    step_warn "Grok not logged in — run: grok login (or export XAI_API_KEY)"
  fi
elif [[ "$PROFILE" == "minimal" ]]; then
  step_ok "Grok skipped (minimal profile)"
else
  step_warn "Grok CLI missing — run first-boot/install.sh"
fi

# Issue-agent fleet config
ISSUE_ROOT="${ISSUE_AGENT_ROOT:-$HOME/issue-agent}"
mkdir -p "$ISSUE_ROOT"
FLEET_REPO="${HABITAT_FLEET_REPO:-}"
if [[ -z "$FLEET_REPO" && -n "$GH_USER" ]]; then
  FLEET_REPO="${GH_USER}/${HABITAT_FLEET_NAME:-agent-habitat-demo}"
fi
FLEET_REPO="${FLEET_REPO:-your-user/your-repo}"

if [[ ! -f "$ISSUE_ROOT/repos.yaml" ]] || grep -q 'your-user/your-repo' "$ISSUE_ROOT/repos.yaml" 2>/dev/null; then
  if [[ "$FLEET_REPO" != *"your-repo"* && -n "$GH_USER" ]]; then
    sed "s|Nueramarcos/agent-habitat-demo|${DEMO_REPO}|g; s|your-user/your-repo|${FLEET_REPO}|g" \
      "$HABITAT_ROOT/agent-runtime/examples/repos.starter.yaml" > "$ISSUE_ROOT/repos.yaml"
    step_ok "wrote $ISSUE_ROOT/repos.yaml (demo: $DEMO_REPO)"
  else
    cp "$HABITAT_ROOT/agent-runtime/examples/repos.starter.yaml" "$ISSUE_ROOT/repos.yaml"
    step_warn "edit $ISSUE_ROOT/repos.yaml — set your GitHub repo"
  fi
else
  step_ok "repos.yaml already configured"
fi

# Install habitat CLI
install -m 755 "$HABITAT_ROOT/scripts/habitat" "$HOME/bin/habitat" 2>/dev/null || \
  cp "$HABITAT_ROOT/scripts/habitat" "$HOME/bin/habitat"
step_ok "habitat CLI → ~/bin/habitat"

# Demo CI hint
if ! gh api "repos/${DEMO_REPO}/contents/.github/workflows/ci.yml" >/dev/null 2>&1; then
  step_warn "demo CI missing — run: habitat ci-setup (needs gh workflow scope)"
fi

echo ""
log "Running verify..."
bash "$HABITAT_ROOT/first-boot/verify.sh" || true

cat <<EOF

Next:
  habitat status
  habitat demo
  issue-agent fix ${DEMO_REPO} 3    # round 2: mean() bug

EOF