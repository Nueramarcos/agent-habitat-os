#!/usr/bin/env bash
# QEMU smoke test — Ubuntu 24.04 autoinstall + Agent Habitat cloud-init
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/iso/build"
USB="$BUILD/usb"
ISO="${UBUNTU_ISO:-$BUILD/ubuntu-24.04.3-live-server-amd64.iso}"
USER_DATA="${HABITAT_USER_DATA:-$USB/user-data}"
META_DATA="${HABITAT_META_DATA:-$USB/meta-data}"
DISK="$BUILD/agent-habitat-test.qcow2"
LOG="$BUILD/qemu-serial.log"
PIDFILE="$BUILD/qemu.pid"
MONITOR_SOCK="$BUILD/qemu-monitor.sock"
RAM_MB="${QEMU_RAM_MB:-8192}"
CPUS="${QEMU_CPUS:-2}"
SEED="$USB/seed.iso"

die() { echo "qemu-test: $*" >&2; exit 1; }

# Refresh cloud-init files + seed ISO
bash "$ROOT/iso/prepare-usb.sh" >/dev/null 2>&1 || true
bash "$ROOT/iso/scripts/create-seed-iso.sh" >/dev/null 2>&1 || true
[[ -f "$USER_DATA" ]] || die "missing $USER_DATA"
[[ -f "$META_DATA" ]] || die "missing $META_DATA"
[[ -f "$ISO" ]] || die "missing Ubuntu ISO — run: habitat iso download"

mkdir -p "$BUILD"
if [[ "${QEMU_FRESH_DISK:-0}" == 1 ]] && [[ -f "$DISK" ]]; then
  rm -f "$DISK"
fi
[[ -f "$DISK" ]] || qemu-img create -f qcow2 "$DISK" 32G >/dev/null

KVM_ARGS=()
if [[ -e /dev/kvm ]] && [[ -r /dev/kvm ]]; then
  KVM_ARGS=(-machine pc,accel=kvm -cpu qemu64)
else
  KVM_ARGS=(-machine pc,accel=tcg -cpu max)
  echo "warning: KVM unavailable — using TCG (slow)"
fi

# fw_cfg NoCloud is more reliable than a second CDROM for autoinstall detection
FW_CFG=(
  -fw_cfg "name=opt/com.coreos/cloud-init/config,file=${USER_DATA}"
  -fw_cfg "name=opt/com.coreos/cloud-init/ident,file=${META_DATA}"
)

SEED_DRIVE=()
[[ -f "$SEED" ]] && SEED_DRIVE=(-drive "file=$SEED,if=virtio,media=cdrom,readonly=on")

rm -f "$MONITOR_SOCK"
cmd=(
  qemu-system-x86_64
  "${KVM_ARGS[@]}"
  -m "$RAM_MB"
  -smp "$CPUS"
  -drive "file=$DISK,if=virtio,format=qcow2"
  -drive "file=$ISO,if=ide,media=cdrom,readonly=on"
  "${SEED_DRIVE[@]}"
  "${FW_CFG[@]}"
  -netdev user,id=net0,dhcpstart=10.0.2.15,hostfwd=tcp::2222-:22
  -device virtio-net-pci,netdev=net0
  -boot order=d
  -nographic
  -monitor "unix:$MONITOR_SOCK,server,nowait"
  -serial "file:$LOG"
)

echo "==> Agent Habitat QEMU test (fw_cfg NoCloud)"
echo "    ubuntu:    $ISO"
echo "    user-data: $USER_DATA"
echo "    disk:      $DISK"
echo "    log:       $LOG"
echo "    ssh fwd:   localhost:2222 → vm:22 (after install)"
echo ""
echo "    habitat iso vm-status"
echo "    tail -f $LOG"
echo ""

: > "$LOG"
nohup "${cmd[@]}" > "$BUILD/qemu-stdout.log" 2>&1 &
echo $! > "$PIDFILE"
echo "QEMU started pid=$(cat "$PIDFILE")"

# Headless GRUB often needs Enter — send via QMP after boot menu appears
(
  for _ in $(seq 1 60); do
    [[ -S "$MONITOR_SOCK" ]] && break
    sleep 1
  done
  [[ -S "$MONITOR_SOCK" ]] || exit 0
  for _ in 1 2 3 4 5 6 8 10; do
    printf 'sendkey ret\n' | socat - "UNIX-CONNECT:$MONITOR_SOCK" 2>/dev/null || true
    sleep 20
  done
) > "$BUILD/qemu-grub-helper.log" 2>&1 &