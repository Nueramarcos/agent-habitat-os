#!/usr/bin/env bash
# Cubic post-install / first-login hook — Agent Habitat OS
# Runs inside chroot or on first live-session login.
set -euo pipefail

HABITAT_USER="${SUDO_USER:-ubuntu}"
HABITAT_HOME="$(eval echo "~$HABITAT_USER")"
REPO="$HABITAT_HOME/agent-habitat-os"
PROFILE="${HABITAT_PROFILE:-hybrid}"

if [[ ! -d "$REPO" ]]; then
  sudo -u "$HABITAT_USER" git clone https://github.com/Nueramarcos/agent-habitat-os.git "$REPO"
fi

export HABITAT_PROFILE="$PROFILE"
export HABITAT_ROOT="$REPO"

sudo -u "$HABITAT_USER" bash "$REPO/first-boot/install.sh"

# Desktop autostart hint (optional)
cat > "$HABITAT_HOME/Desktop/agent-habitat-verify.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Agent Habitat Verify
Exec=gnome-terminal -- bash -lc 'habitat verify; read -p "Press enter..."'
Icon=utilities-terminal
Terminal=false
EOF
chown "$HABITAT_USER:$HABITAT_USER" "$HABITAT_HOME/Desktop/agent-habitat-verify.desktop"
chmod +x "$HABITAT_HOME/Desktop/agent-habitat-verify.desktop"