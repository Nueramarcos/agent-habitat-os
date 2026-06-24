#!/usr/bin/env bash
# Boot installed VM from disk only (no ISO) — use after autoinstall completes
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/iso/build"
DISK="$BUILD/agent-habitat-test.qcow2"
LOG="$BUILD/qemu-disk-boot.log"
PIDFILE="$BUILD/qemu-disk.pid"

[[ -f "$DISK" ]] || { echo "missing $DISK — run habitat iso vm-gui first"; exit 1; }

/usr/bin/pkill -f 'qemu-system.*agent-habitat-test.qcow2' 2>/dev/null || true
sleep 2

: > "$LOG"
nohup qemu-system-x86_64 \
  -machine pc,accel=kvm -cpu qemu64 -m 4096 -smp 2 \
  -drive "file=$DISK,if=virtio,format=qcow2" \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net,netdev=net0 \
  -display none -monitor null \
  -serial "file:$LOG" \
  > "$BUILD/qemu-disk-stdout.log" 2>&1 &

echo $! > "$PIDFILE"
echo "==> Disk boot started pid=$(cat "$PIDFILE")"
echo "    wait ~45s, then: habitat iso ssh hostname"
echo "    log: $LOG"