#!/usr/bin/env bash
# SSH into QEMU test VM (after autoinstall)
set -euo pipefail

PORT="${HABITAT_VM_SSH_PORT:-2222}"
USER="${HABITAT_VM_USER:-ubuntu}"
HOST="${HABITAT_VM_HOST:-127.0.0.1}"

echo "Connecting ${USER}@${HOST}:${PORT} (password: ubuntu)"
exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$PORT" "${USER}@${HOST}" "$@"