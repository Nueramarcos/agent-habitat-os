#!/usr/bin/env bash
# QEMU GUI install — use when headless GRUB loop needs eyes on the installer
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/iso/build"
ISO="$BUILD/ubuntu-24.04.3-live-server-amd64.iso"
DISK="$BUILD/agent-habitat-test.qcow2"
USER_DATA="$BUILD/usb/user-data"
META_DATA="$BUILD/usb/meta-data"

[[ -f "$ISO" ]] || { echo "run: habitat iso download"; exit 1; }
bash "$ROOT/iso/prepare-usb.sh" >/dev/null 2>&1 || true

if [[ "${QEMU_FRESH_DISK:-0}" == 1 ]] && [[ -f "$DISK" ]]; then
  echo "==> Fresh disk requested — removing $DISK"
  rm -f "$DISK"
fi
[[ -f "$DISK" ]] || qemu-img create -f qcow2 "$DISK" 32G >/dev/null

echo $$ > "$BUILD/qemu-gui.pid"

exec qemu-system-x86_64 \
  -machine pc,accel=kvm -cpu qemu64 -m 4096 -smp 2 \
  -drive "file=$DISK,if=virtio,format=qcow2" \
  -drive "file=$ISO,if=ide,media=cdrom,readonly=on" \
  -fw_cfg "name=opt/com.coreos/cloud-init/config,file=$USER_DATA" \
  -fw_cfg "name=opt/com.coreos/cloud-init/ident,file=$META_DATA" \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net,netdev=net0 \
  -boot order=d \
  -display gtk