#!/usr/bin/env bash
# Prepare Ubuntu 24.04 USB with Agent Habitat autoinstall
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/iso/build/usb"
USER_DATA="${ROOT}/iso/cloud-init/user-data.yaml"
META_DATA="${ROOT}/iso/cloud-init/meta-data"

die() { echo "prepare-usb: $*" >&2; exit 1; }

echo "==> Agent Habitat USB prep"
mkdir -p "$OUT"

# meta-data required for NoCloud datasource
cat > "$META_DATA" <<EOF
instance-id: agent-habitat-001
local-hostname: agent-habitat
EOF

cp "$USER_DATA" "$OUT/user-data"
cp "$META_DATA" "$OUT/meta-data"

# CIDATA volume (FAT) — standard for autoinstall USB
CIDATA_IMG="$OUT/cidata.img"
if command -v mkfs.vfat >/dev/null; then
  dd if=/dev/zero of="$CIDATA_IMG" bs=1M count=4 status=none 2>/dev/null || \
    dd if=/dev/zero of="$CIDATA_IMG" bs=1048576 count=4 2>/dev/null
  mkfs.vfat "$CIDATA_IMG" >/dev/null
  if command -v mcopy >/dev/null; then
    mmd -i "$CIDATA_IMG" ::cidata 2>/dev/null || true
    mcopy -i "$CIDATA_IMG" "$OUT/user-data" ::user-data
    mcopy -i "$CIDATA_IMG" "$OUT/meta-data" ::meta-data
    step=1
  else
    step=0
  fi
else
  step=0
fi

cat <<EOF

==> Autoinstall files ready: $OUT

Files:
  user-data  → $OUT/user-data
  meta-data  → $OUT/meta-data
$([[ -f "$CIDATA_IMG" ]] && echo "  cidata.img → $CIDATA_IMG (FAT volume with NoCloud config)")

## Option A — Ventoy USB (easiest)

1. Install Ventoy on a spare USB
2. Copy Ubuntu 24.04 Desktop ISO to the Ventoy partition
3. Copy these to the Ventoy partition root:
     user-data
     meta-data
4. Boot USB → Ubuntu installer picks up NoCloud autoinstall

## Option B — Cubic custom ISO

See iso/README.md — add post-install.sh + packages.list

## Option C — VM test (no USB)

1. Download Ubuntu 24.04 live ISO
2. Create VM, attach $OUT/user-data as cloud-init seed (virt-manager: cloud-init ISO)
3. Or use:

   cloud-localds $OUT/seed.iso $OUT/user-data $OUT/meta-data

4. Boot VM with seed.iso as second CD

## After first boot

  habitat init
  grok login
  gh auth login
  habitat verify

⚠️  Change the placeholder password in iso/cloud-init/user-data.yaml before production use.

EOF