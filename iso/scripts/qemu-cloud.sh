#!/usr/bin/env bash
# QEMU cloud-image boot — unattended Session B (no GRUB installer)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/iso/build"
DISK="$BUILD/agent-habitat-cloud.qcow2"
BASE="$BUILD/ubuntu-24.04-server-cloudimg-amd64.img"
URL="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
SEED_DIR="$BUILD/cloud-seed"
USER_DATA="$ROOT/iso/cloud-init/cloud-image-user-data.yaml"
META_DATA="$ROOT/iso/cloud-init/meta-data"
LOG="$BUILD/qemu-cloud.log"
PIDFILE="$BUILD/qemu-cloud.pid"
RAM="${QEMU_RAM_MB:-8192}"

die() { echo "qemu-cloud: $*" >&2; exit 1; }

mkdir -p "$BUILD" "$SEED_DIR"
cat > "$META_DATA" <<EOF
instance-id: agent-habitat-cloud-001
local-hostname: agent-habitat
EOF

if [[ ! -f "$BASE" ]]; then
  echo "==> Downloading Ubuntu 24.04 cloud image..."
  curl -fL --progress-bar -o "$BASE" "$URL"
fi

if [[ "${QEMU_FRESH_DISK:-0}" == 1 ]] && [[ -f "$DISK" ]]; then
  rm -f "$DISK"
fi
if [[ ! -f "$DISK" ]]; then
  qemu-img create -f qcow2 -b "$BASE" -F qcow2 "$DISK" 32G >/dev/null
fi

SEED="$BUILD/cloud-seed.iso"
cp "$USER_DATA" "$SEED_DIR/user-data"
cp "$META_DATA" "$SEED_DIR/meta-data"
if command -v cloud-localds >/dev/null; then
  cloud-localds "$SEED" "$SEED_DIR/user-data" "$SEED_DIR/meta-data"
else
  xorriso -as mkisofs -output "$SEED" -volid cidata -joliet -rock \
    "$SEED_DIR/user-data" "$SEED_DIR/meta-data" 2>/dev/null || die "need cloud-localds or xorriso"
fi

/usr/bin/pkill -f 'qemu-system.*agent-habitat-cloud' 2>/dev/null || true
sleep 2

: > "$LOG"
nohup qemu-system-x86_64 \
  -machine pc,accel=kvm -cpu qemu64 -m "$RAM" -smp 2 \
  -drive "file=$DISK,if=virtio,format=qcow2" \
  -drive "file=$SEED,if=virtio,media=cdrom,readonly=on" \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net,netdev=net0 \
  -display none -monitor null \
  -serial "file:$LOG" \
  > "$BUILD/qemu-cloud-stdout.log" 2>&1 &

echo $! > "$PIDFILE"
echo "==> Cloud image VM started pid=$(cat "$PIDFILE")"
echo "    disk: $DISK"
echo "    user: ubuntu / ubuntu"
echo "    ssh:  localhost:2222"
echo "    log:  $LOG"