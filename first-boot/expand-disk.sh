#!/usr/bin/env bash
# Grow Ubuntu LVM root when the VG has free extents (common on 32G QEMU disks).
set -euo pipefail

log() { printf '\033[38;5;141m[habitat]\033[0m %s\n' "$*"; }

if ! command -v lvextend >/dev/null || ! command -v resize2fs >/dev/null; then
  log "lvm2 tools missing — skip disk expand"
  exit 0
fi

LV="$(df / --output=source | tail -1)"
VFREE="$(sudo vgs --noheadings -o vg_free --units g --nosuffix 2>/dev/null | awk '{print int($1)}' || echo 0)"
if [[ "$VFREE" -lt 1 ]]; then
  log "no VG free space to expand"
  exit 0
fi

log "Expanding $LV (+${VFREE}G free in VG)..."
sudo lvextend -l +100%FREE "$LV"
sudo resize2fs "$LV"
df -h / | tail -1
log "disk expand complete"