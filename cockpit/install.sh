#!/usr/bin/env bash
# Agent Habitat OS — cockpit (shell, tools, grok config)
set -euo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
COCKPIT_DIR="$HABITAT_ROOT/cockpit"
PROFILE="${HABITAT_PROFILE:-hybrid}"
INSTALL_GROK="${HABITAT_INSTALL_GROK:-true}"

log() { printf '\033[38;5;141m[cockpit]\033[0m %s\n' "$*"; }

mkdir -p "$HOME/.zsh" "$HOME/bin" "$HOME/.local/bin" "$HOME/.grok/skills"

# ── zsh modules ──────────────────────────────────────────────────────────
for f in "$COCKPIT_DIR"/zsh/*.zsh; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  if [[ ! -f "$HOME/.zsh/$base" ]]; then
    cp "$f" "$HOME/.zsh/$base"
    log "installed ~/.zsh/$base"
  fi
done

# Thin zshrc loader
if [[ ! -f "$HOME/.zshrc" ]] || ! grep -q 'Agent Habitat' "$HOME/.zshrc" 2>/dev/null; then
  cp "$COCKPIT_DIR/templates/zshrc" "$HOME/.zshrc"
  log "installed ~/.zshrc"
fi

# ── modern CLI tools (user-local, no sudo) ───────────────────────────────
install_bin() {
  local name="$1" url="$2"
  local dest="$HOME/.local/bin/$name"
  [[ -x "$dest" ]] && return 0
  log "fetching $name..."
  curl -fsSL "$url" -o "$dest" || { log "warning: fetch $name failed"; return 0; }
  chmod +x "$dest" || return 0
}

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_TAG="x86_64" ;;
  aarch64) ARCH_TAG="aarch64" ;;
  *)       ARCH_TAG="x86_64" ;;
esac

# starship
if ! command -v starship >/dev/null; then
  install_bin starship "https://github.com/starship/starship/releases/latest/download/starship-${ARCH_TAG}-unknown-linux-gnu" || true
fi

# eza
if ! command -v eza >/dev/null; then
  install_bin eza "https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH_TAG}-unknown-linux-gnu" || true
fi

# bat
if ! command -v bat >/dev/null; then
  BAT_VER="0.24.0"
  TMP="$(mktemp -d)"
  curl -fsSL "https://github.com/sharkdp/bat/releases/download/v${BAT_VER}/bat-v${BAT_VER}-${ARCH_TAG}-unknown-linux-gnu.tar.gz" \
    | tar -xz -C "$TMP" 2>/dev/null || true
  find "$TMP" -name bat -type f -executable -exec cp {} "$HOME/.local/bin/bat" \; 2>/dev/null || true
  chmod +x "$HOME/.local/bin/bat" 2>/dev/null || true
  rm -rf "$TMP"
fi

# fd
if ! command -v fd >/dev/null; then
  FD_VER="10.1.0"
  TMP="$(mktemp -d)"
  curl -fsSL "https://github.com/sharkdp/fd/releases/download/v${FD_VER}/fd-v${FD_VER}-${ARCH_TAG}-unknown-linux-gnu.tar.gz" \
    | tar -xz -C "$TMP" 2>/dev/null || true
  find "$TMP" -name fd -type f -executable -exec cp {} "$HOME/.local/bin/fd" \; 2>/dev/null || true
  chmod +x "$HOME/.local/bin/fd" 2>/dev/null || true
  rm -rf "$TMP"
fi

# ripgrep — prefer apt; fallback curl
if ! command -v rg >/dev/null; then
  RG_VER="14.1.0"
  install_bin rg "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep-${RG_VER}-${ARCH_TAG}-unknown-linux-gnu" 2>/dev/null || true
fi

# zoxide
if ! command -v zoxide >/dev/null; then
  install_bin zoxide "https://github.com/ajeetdsouza/zoxide/releases/latest/download/zoxide-${ARCH_TAG}-unknown-linux-gnu" || true
fi

# fzf
if [[ ! -f "$HOME/.fzf.zsh" ]]; then
  if [[ ! -d "$HOME/.fzf" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null || true
  fi
  "$HOME/.fzf/install" --all --no-bash --no-fish 2>/dev/null || true
fi

# motd
mkdir -p "$HOME/bin"
cp -f "$COCKPIT_DIR/bin/motd" "$HOME/bin/motd" 2>/dev/null || true
chmod +x "$HOME/bin/motd" 2>/dev/null || true

# ── grok ─────────────────────────────────────────────────────────────────
if [[ "$INSTALL_GROK" == true ]] && ! command -v grok >/dev/null 2>&1; then
  log "Installing Grok CLI..."
  curl -fsSL https://x.ai/cli/install.sh | bash || log "Grok install failed — run manually later"
fi

# Grok config template (don't overwrite existing)
mkdir -p "$HOME/.grok"
if [[ ! -f "$HOME/.grok/config.toml" ]]; then
  cp "$COCKPIT_DIR/templates/config.toml" "$HOME/.grok/config.toml"
  log "installed ~/.grok/config.toml"
fi

if [[ ! -f "$HOME/.grok/AGENTS.md" ]]; then
  cp "$COCKPIT_DIR/templates/AGENTS.md" "$HOME/.grok/AGENTS.md"
  log "installed ~/.grok/AGENTS.md"
fi

if [[ ! -f "$HOME/.terminal-desires.md" ]]; then
  cp "$COCKPIT_DIR/templates/terminal-desires.md" "$HOME/.terminal-desires.md"
  log "installed ~/.terminal-desires.md"
fi

# Link habitat skill into grok skills (optional discovery)
mkdir -p "$HOME/.grok/skills/agent-habitat"
if [[ ! -f "$HOME/.grok/skills/agent-habitat/SKILL.md" ]]; then
  ln -sf "$HABITAT_ROOT/AGENTS.md" "$HOME/.grok/skills/agent-habitat/SKILL.md" 2>/dev/null || \
    cp "$HABITAT_ROOT/AGENTS.md" "$HOME/.grok/skills/agent-habitat/SKILL.md"
fi

log "cockpit ready"