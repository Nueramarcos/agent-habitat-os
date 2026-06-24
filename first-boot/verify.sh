#!/usr/bin/env bash
# Agent Habitat OS — health verification
set -euo pipefail

HABITAT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${HABITAT_PROFILE:-$(cat "$HOME/.config/agent-habitat/profile" 2>/dev/null || echo hybrid)}"
RECORD_DIR="$HABITAT_ROOT/flight-recorder"
RECORD_FILE="$RECORD_DIR/verify.jsonl"
PASS=0
FAIL=0
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

log_pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
log_fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

record() {
  local outcome="$1" detail="$2"
  mkdir -p "$RECORD_DIR"
  printf '{"outcome":"habitat_verify","profile":"%s","detail":"%s","ts":"%s","source":"verify.sh"}\n' \
    "$PROFILE" "$detail" "$TS" >> "$RECORD_FILE"
}

check() {
  local name="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    log_pass "$name"
    return 0
  else
    log_fail "$name"
    return 1
  fi
}

echo ""
echo "Agent Habitat verify (profile: $PROFILE)"
echo ""

check "git"          "command -v git"
check "python3"      "python3 --version"
check "zsh"          "command -v zsh"
check "gh"           "command -v gh"
check "curl"         "command -v curl"
check "habitat CLI"  "command -v habitat || test -x $HOME/bin/habitat"

if [[ "$PROFILE" != "cloud-only" ]]; then
  check "ollama"     "command -v ollama"
  if curl -sf "${OLLAMA_HOST:-http://127.0.0.1:11434}/api/tags" >/dev/null 2>&1; then
    log_pass "ollama API"
    if curl -sf "${OLLAMA_HOST:-http://127.0.0.1:11434}/api/tags" | grep -q 'qwen2.5-coder:7b'; then
      log_pass "model qwen2.5-coder:7b"
    else
      log_fail "model qwen2.5-coder:7b (run: ollama pull qwen2.5-coder:7b)"
    fi
  else
    log_fail "ollama API (run: ollama serve)"
  fi
fi

if [[ "$PROFILE" != "minimal" ]]; then
  if command -v grok >/dev/null 2>&1; then
    log_pass "grok CLI"
  else
    log_fail "grok CLI (run: curl -fsSL https://x.ai/cli/install.sh | bash)"
  fi
fi

if [[ -d "$HOME/issue-agent" ]]; then
  log_pass "issue-agent installed"
  if command -v issue-agent >/dev/null 2>&1 || [[ -x "$HOME/bin/issue-agent" ]]; then
    log_pass "issue-agent CLI"
  else
    log_fail "issue-agent CLI"
  fi
  if [[ -f "$HOME/issue-agent/personality.py" && -f "$HOME/issue-agent/tower.py" ]]; then
    log_pass "issue-agent modules"
  else
    log_fail "issue-agent modules (run: habitat doctor)"
  fi
else
  if [[ "$PROFILE" == "cloud-only" ]]; then
    log_pass "issue-agent skipped (cloud-only profile)"
  else
    log_fail "issue-agent not installed"
  fi
fi

check "agent-workspaces" "test -d $HOME/agent-workspaces"
check "cockpit secrets"  "test -f $HOME/.config/cockpit/secrets.env"
check "AGENTS.md"        "test -f $HOME/.grok/AGENTS.md"
check "routing.yaml"     "test -f $HOME/.config/agent-habitat/routing.yaml"

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  printf '\033[32mAll %d checks passed.\033[0m\n\n' "$PASS"
  record "pass" "all_checks_passed"
  exit 0
else
  printf '\033[33m%d passed, %d failed — see messages above.\033[0m\n\n' "$PASS" "$FAIL"
  record "fail" "${PASS}_pass_${FAIL}_fail"
  exit 1
fi