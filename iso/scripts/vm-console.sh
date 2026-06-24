#!/usr/bin/env bash
# Boot installed VM with GTK console — login at tty if SSH password unknown
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/iso/build"
DISK="$BUILD/agent-habitat-test.qcow2"

[[ -f "$DISK" ]] || { echo "missing $DISK"; exit 1; }

/usr/bin/pkill -f 'qemu-system.*agent-habitat-test' 2>/dev/null || true
sleep 2

echo "==> Booting installed system with console"
echo "    login: nueramarcos (or ubuntu for autoinstall)"
echo "    password: what you set in GUI installer"
echo "    then: sudo journalctl -u agent-habitat-firstboot -f"

exec qemu-system-x86_64 \
  -machine pc,accel=kvm -cpu qemu64 -m 4096 -smp 2 \
  -drive "file=$DISK,if=virtio,format=qcow2" \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net,netdev=net0 \
  -display gtk