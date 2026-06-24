#!/usr/bin/env bash
# Print / run VM provisioning after install (when firstboot unit is missing)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${HABITAT_VM_SSH_PORT:-2222}"

cat <<EOF
==> Agent Habitat VM provisioning

Manual GUI install? Your VM user may be nueramarcos (not ubuntu).
Run these INSIDE the VM (GTK console or SSH):

  habitat iso console
  ssh -p $PORT \$USER@localhost    # or: HABITAT_VM_USER=nuermarcos habitat iso ssh

Then paste ONE of:

  # repo already on disk (autoinstall partial):
  bash ~/agent-habitat-os/first-boot/provision.sh

  # fresh manual Ubuntu install:
  git clone https://github.com/Nueramarcos/agent-habitat-os.git ~/agent-habitat-os
  bash ~/agent-habitat-os/first-boot/provision.sh

Watch first-boot (~10 min):
  sudo journalctl -u agent-habitat-firstboot -f

When done:
  habitat verify

EOF

if [[ "${1:-}" == "--try-ssh" ]]; then
  exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -p "$PORT" ubuntu@127.0.0.1 \
    'bash -s' < "$ROOT/first-boot/provision.sh"
fi