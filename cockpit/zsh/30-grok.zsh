export PATH="$HOME/.grok/bin:$PATH"

desire() {
  [[ $# -eq 0 ]] && { echo 'Usage: desire "wish"'; return 1; }
  echo "- [ ] $*" >> "$HOME/.terminal-desires.md"
  echo "Recorded → ~/.terminal-desires.md"
}

cockpit() {
  echo "╔══════════════════════════════════════╗"
  echo "║  AGENT HABITAT COCKPIT               ║"
  echo "╚══════════════════════════════════════╝"
  echo "Profile:  $(cat "$HOME/.config/agent-habitat/profile" 2>/dev/null || echo hybrid)"
  echo "Grok:     $(command -v grok 2>/dev/null || echo not found)"
  echo "Ollama:   $(command -v ollama 2>/dev/null || echo not found)"
  echo "Agent:    $(command -v issue-agent 2>/dev/null || echo not found)"
}

if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh >/dev/null; then
  export GITHUB_TOKEN="$(gh auth token 2>/dev/null)" || true
fi

grok() {
  local dir="$PWD"
  if [[ "$dir" == "$HOME" && -d "$HOME/agent-habitat-os" ]]; then
    (cd "$HOME/agent-habitat-os" && command grok "$@")
    return
  fi
  command grok "$@"
}

alias g='grok'