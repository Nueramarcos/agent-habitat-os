#!/usr/bin/env bash
# Idempotent Habitat provisioning — run inside the VM when autoinstall late-commands
# did not run (manual GUI install) or agent-habitat-firstboot.service is missing.
set -euo pipefail

log() { printf '\033[38;5;141m[habitat]\033[0m %s\n' "$*"; }

HABITAT_USER="$(id -un)"
HABITAT_HOME="$HOME"
REPO="${HABITAT_ROOT:-$HABITAT_HOME/agent-habitat-os}"
PROFILE="${HABITAT_PROFILE:-hybrid}"
MARKER="$HABITAT_HOME/.habitat-provisioned"

log "Provisioning for user $HABITAT_USER on $(hostname)"

mkdir -p "$HABITAT_HOME/.config/cockpit" "$HABITAT_HOME/.config/agent-habitat" "$HABITAT_HOME/bin"
chmod 700 "$HABITAT_HOME/.config/cockpit"
touch "$HABITAT_HOME/.config/cockpit/secrets.env"
chmod 600 "$HABITAT_HOME/.config/cockpit/secrets.env"
echo "$PROFILE" > "$HABITAT_HOME/.config/agent-habitat/profile"

if [[ ! -f "$REPO/first-boot/install.sh" ]]; then
  log "Cloning agent-habitat-os..."
  git clone https://github.com/Nueramarcos/agent-habitat-os.git "$REPO"
fi

install -m 755 "$REPO/scripts/habitat" "$HABITAT_HOME/bin/habitat"

UNIT=/etc/systemd/system/agent-habitat-firstboot.service
needs_unit=false
if [[ ! -f "$UNIT" ]]; then
  needs_unit=true
elif ! grep -q "User=$HABITAT_USER" "$UNIT" 2>/dev/null; then
  log "Refreshing firstboot unit for $HABITAT_USER..."
  needs_unit=true
fi

if [[ "$needs_unit" == true ]]; then
  log "Installing agent-habitat-firstboot.service..."
  sudo tee "$UNIT" >/dev/null <<UNIT
[Unit]
Description=Agent Habitat first-boot provisioning
After=network-online.target
Wants=network-online.target
ConditionPathExists=!$MARKER

[Service]
Type=oneshot
User=$HABITAT_USER
WorkingDirectory=$REPO
Environment=HABITAT_ROOT=$REPO
Environment=HOME=$HABITAT_HOME
ExecStart=/bin/bash $REPO/first-boot/install.sh
ExecStartPost=/usr/bin/touch $MARKER
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
  sudo systemctl daemon-reload
  sudo systemctl enable agent-habitat-firstboot.service
fi

if [[ -f "$MARKER" ]]; then
  log "Already provisioned — re-running install.sh"
  export HABITAT_ROOT="$REPO" HABITAT_PROFILE="$PROFILE"
  bash "$REPO/first-boot/install.sh"
  exit 0
fi

log "Starting first-boot (Ollama + agents — may take 10+ min)..."
sudo systemctl start agent-habitat-firstboot.service
sudo systemctl status agent-habitat-firstboot.service --no-pager || true
log "Tail progress: sudo journalctl -u agent-habitat-firstboot -f"