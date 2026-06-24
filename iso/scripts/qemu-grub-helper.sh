#!/usr/bin/env bash
# Headless GRUB helper — send HMP commands to QEMU monitor (not QMP JSON).
set -euo pipefail

MONITOR_SOCK="${1:-}"
LOG="${2:-}"

[[ -n "$MONITOR_SOCK" ]] || { echo "usage: qemu-grub-helper.sh <monitor-sock> [serial-log]" >&2; exit 1; }

send_hmp() {
  local cmd="$1"
  printf '%s\n' "$cmd" | socat - "UNIX-CONNECT:$MONITOR_SOCK" 2>/dev/null || true
}

wait_sock() {
  local i
  for i in $(seq 1 120); do
    [[ -S "$MONITOR_SOCK" ]] && return 0
    sleep 1
  done
  return 1
}

grub_visible() {
  [[ -n "$LOG" && -f "$LOG" ]] || return 1
  tail -40 "$LOG" 2>/dev/null | grep -qiE 'GNU GRUB|Try or Install|Ubuntu Server'
}

wait_sock || exit 0

# GRUB menu usually appears 10–40s after QEMU start
for _ in $(seq 1 90); do
  grub_visible && break
  sleep 2
done

# Default entry often lacks autoinstall — edit kernel cmdline once
send_hmp "sendkey e"
sleep 2
for _ in 1 2 3 4 5 6; do
  send_hmp "sendkey down"
  sleep 0.4
done
send_hmp "sendkey end"
sleep 0.5
for ch in a u t o i n s t a l l; do
  send_hmp "sendkey $ch"
  sleep 0.15
done
send_hmp "sendkey f10"
sleep 5

# Fallback: Enter in case we are still on the menu
for _ in 1 2 3 4 5 6 8 10 12; do
  if [[ -n "$LOG" && -f "$LOG" ]] && grep -qiE 'autoinstall|subiquity|curtin|cloud-init' "$LOG" 2>/dev/null; then
    exit 0
  fi
  send_hmp "sendkey ret"
  sleep 20
done