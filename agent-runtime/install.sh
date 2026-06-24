#!/usr/bin/env bash
# Agent Habitat OS — issue-agent + ollama runtime
set -euo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROFILE="${HABITAT_PROFILE:-hybrid}"
ISSUE_AGENT_REPO="${ISSUE_AGENT_REPO:-https://github.com/Nueramarcos/issue-agent.git}"
INSTALL_DIR="${ISSUE_AGENT_HOME:-$HOME/issue-agent}"

log() { printf '\033[38;5;141m[runtime]\033[0m %s\n' "$*"; }

# gh CLI
if ! command -v gh >/dev/null 2>&1; then
  log "Installing gh CLI..."
  if command -v apt-get >/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -qq && sudo apt-get install -y -qq gh
  else
    log "Install gh manually: https://cli.github.com/"
  fi
fi

# Ollama
if ! command -v ollama >/dev/null 2>&1; then
  log "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Ensure ollama is reachable
if ! curl -sf "${OLLAMA_HOST:-http://127.0.0.1:11434}/api/tags" >/dev/null 2>&1; then
  log "Starting ollama serve (background)..."
  (ollama serve >/dev/null 2>&1 &) || true
  sleep 2
fi

# Pull models per profile
pull_model() {
  local m="$1"
  if ollama list 2>/dev/null | grep -qF "$m"; then
    log "model present: $m"
    return 0
  fi
  log "pulling $m..."
  if ollama pull "$m"; then
    return 0
  fi
  log "warning: failed to pull $m — retry later: ollama pull $m"
  return 0
}

case "$PROFILE" in
  minimal|hybrid)
    if [[ "${HABITAT_LIGHT:-}" == 1 ]]; then
      pull_model "qwen2.5-coder:1.5b"
    else
      pull_model "qwen2.5-coder:7b"
      pull_model "qwen2.5-coder:1.5b"
      pull_model "nomic-embed-text"
    fi
    ;;
esac

# Issue Agent
if [[ -d "$INSTALL_DIR/.git" ]]; then
  log "Updating issue-agent at $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null || true
else
  log "Cloning issue-agent..."
  if ! git clone "$ISSUE_AGENT_REPO" "$INSTALL_DIR"; then
    log "warning: issue-agent clone failed — check network and retry"
  fi
fi

VENV_DIR="${ISSUE_AGENT_VENV:-$HOME/.local/venvs/aider}"
mkdir -p "$(dirname "$VENV_DIR")"
if [[ ! -x "$VENV_DIR/bin/aider" ]]; then
  log "Creating Aider venv..."
  python3 -m venv "$VENV_DIR"
  if ! "$VENV_DIR/bin/pip" install -U pip aider-chat pyyaml; then
    log "warning: pip install failed — retry: $VENV_DIR/bin/pip install -U pip aider-chat pyyaml"
  fi
fi

mkdir -p "$HOME/agent-workspaces" "$HOME/bin"
if [[ -f "$INSTALL_DIR/bin/issue-agent" ]]; then
  cp -f "$INSTALL_DIR/bin/issue-agent" "$HOME/bin/"
  chmod +x "$HOME/bin/issue-agent"
fi

# Starter repos.yaml if missing
if [[ ! -f "$INSTALL_DIR/repos.yaml" ]]; then
  cp "$HABITAT_ROOT/agent-runtime/examples/repos.starter.yaml" "$INSTALL_DIR/repos.yaml"
  log "Wrote starter repos.yaml — edit your-user/your-repo"
fi

export ISSUE_AGENT_ROOT="$INSTALL_DIR"
export ISSUE_AGENT_AIDER="$VENV_DIR/bin/aider"

log "agent runtime ready"
log "  issue-agent status"
log "  issue-agent demo --dry-run"