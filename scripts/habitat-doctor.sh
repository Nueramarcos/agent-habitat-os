#!/usr/bin/env bash
# Diagnose + auto-repair all known Agent Habitat failure modes.
set -uo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FIX="${HABITAT_DOCTOR_FIX:-1}"
ISSUES=0
FIXED=0

warn() { printf '  \033[33m!\033[0m %s\n' "$1"; ISSUES=$((ISSUES+1)); }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fix()  { printf '  \033[36m→\033[0m %s\n' "$1"; FIXED=$((FIXED+1)); }

echo "═══ Agent Habitat Doctor ═══"
echo ""

# 1. GITHUB_TOKEN shadowing gh
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  if ! env -u GITHUB_TOKEN gh auth status >/dev/null 2>&1; then
    warn "GITHUB_TOKEN env invalid — blocks gh workflow scope"
    [[ "$FIX" == 1 ]] && fix "run: env -u GITHUB_TOKEN gh auth refresh -h github.com -s workflow,repo"
  else
    ok "gh works when GITHUB_TOKEN unset"
  fi
fi

# 2. Disk space
if df -h / 2>/dev/null | tail -1 | awk '{gsub(/%/,"",$5); if ($5+0 > 90) exit 1}'; then
  ok "disk space OK"
else
  warn "disk >90% full — ollama pull will fail"
  [[ "$FIX" == 1 ]] && bash "$HABITAT_ROOT/first-boot/expand-disk.sh" 2>/dev/null && fix "expanded LVM if possible"
fi

# 3. RAM tier
mem_gb="$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 8)"
if [[ "$mem_gb" -lt 6 ]]; then
  warn "RAM ${mem_gb}GB — use HABITAT_LIGHT=1 or QEMU_MEM=8192"
else
  ok "RAM ${mem_gb}GB"
fi

# 4. Model tier (8GB VMs need 1.5B for aider)
if [[ -d "$HOME/issue-agent" ]] && [[ "$mem_gb" -lt 10 ]]; then
  cfg="$HOME/issue-agent/config.local.toml"
  if [[ -f "$cfg" ]] && grep -q '1.5b' "$cfg" 2>/dev/null; then
    ok "model tier 1.5B (RAM ${mem_gb}GB)"
  else
    warn "RAM ${mem_gb}GB — issue-agent should use 1.5B (7B OOMs under aider)"
    [[ "$FIX" == 1 ]] && bash "$HABITAT_ROOT/agent-runtime/configure-model-tier.sh" 2>/dev/null && fix "configured 1.5B model tier"
  fi
fi

# 5. ~/bin ownership
if [[ -d "$HOME/bin" ]] && [[ ! -w "$HOME/bin" ]]; then
  warn "~/bin not writable (often root-owned after cloud-init)"
  [[ "$FIX" == 1 ]] && sudo chown -R "$(id -un):$(id -gn)" "$HOME/bin" && fix "chown ~/bin"
else
  ok "~/bin writable"
fi

# 6. issue-agent modules
if [[ -d "$HOME/issue-agent" ]]; then
  for mod in personality.py tower.py; do
    if [[ ! -f "$HOME/issue-agent/$mod" ]]; then
      warn "issue-agent missing $mod"
      [[ "$FIX" == 1 ]] && bash "$HABITAT_ROOT/agent-runtime/sync-issue-agent.sh" && fix "synced vendor modules"
      break
    fi
  done
  [[ -f "$HOME/issue-agent/personality.py" ]] && ok "issue-agent modules"
else
  warn "issue-agent not installed"
  [[ "$FIX" == 1 ]] && fix "run: habitat install"
fi

# 7. ollama
if command -v ollama >/dev/null; then
  if curl -sf "${OLLAMA_HOST:-http://127.0.0.1:11434}/api/tags" >/dev/null 2>&1; then
    ok "ollama API"
  else
    warn "ollama not responding"
    [[ "$FIX" == 1 ]] && (ollama serve >/dev/null 2>&1 &) && sleep 2 && fix "started ollama serve"
  fi
else
  warn "ollama not installed"
fi

# 8. gh auth
if command -v gh >/dev/null; then
  if gh auth status >/dev/null 2>&1; then
    ok "gh authenticated"
    scopes="$(gh auth status 2>&1 | grep -oE "'[^']+'" | tr '\n' ' ')"
    echo "$scopes" | grep -q workflow || warn "gh missing workflow scope — CI push will fail"
  else
    warn "gh not authenticated"
    [[ "$FIX" == 1 ]] && fix "run: gh auth login"
  fi
fi

# 9. Run ensure + verify
if [[ "$FIX" == 1 ]]; then
  bash "$HABITAT_ROOT/first-boot/ensure.sh" 2>/dev/null || true
fi

echo ""
if [[ "$ISSUES" -eq 0 ]]; then
  echo "Doctor: all checks passed"
else
  echo "Doctor: $ISSUES issue(s) found, $FIXED repair(s) attempted"
  echo "Run: habitat verify"
fi