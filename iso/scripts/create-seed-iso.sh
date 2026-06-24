#!/usr/bin/env bash
# Create NoCloud seed ISO for QEMU / virt-manager
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
USB="$ROOT/iso/build/usb"
SEED="$USB/seed.iso"

mkdir -p "$USB"
[[ -f "$USB/user-data" ]] || bash "$ROOT/iso/prepare-usb.sh" >/dev/null

if command -v cloud-localds >/dev/null; then
  cloud-localds "$SEED" "$USB/user-data" "$USB/meta-data"
  echo "seed.iso → $SEED (cloud-localds)"
  exit 0
fi

CIDATA="$(mktemp -d)"
trap 'rm -rf "$CIDATA"' EXIT
cp "$USB/user-data" "$CIDATA/user-data"
cp "$USB/meta-data" "$CIDATA/meta-data"

if command -v xorriso >/dev/null; then
  xorriso -as mkisofs -output "$SEED" -volid cidata -joliet -rock "$CIDATA/user-data" "$CIDATA/meta-data"
elif command -v genisoimage >/dev/null; then
  genisoimage -output "$SEED" -volid cidata -joliet -rock "$CIDATA/user-data" "$CIDATA/meta-data"
elif command -v mkisofs >/dev/null; then
  mkisofs -output "$SEED" -volid cidata -joliet -rock "$CIDATA/user-data" "$CIDATA/meta-data"
else
  echo "Install cloud-image-utils or genisoimage/xorriso" >&2
  exit 1
fi

echo "seed.iso → $SEED ($(du -h "$SEED" | cut -f1))"