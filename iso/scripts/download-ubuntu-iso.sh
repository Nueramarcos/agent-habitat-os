#!/usr/bin/env bash
# Download Ubuntu 24.04.3 live server ISO for QEMU tests
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/iso/build/ubuntu-24.04.3-live-server-amd64.iso"
URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"

if [[ -f "$OUT" ]]; then
  echo "ISO present: $OUT ($(du -h "$OUT" | cut -f1))"
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
echo "==> Downloading Ubuntu 24.04.3 live server ISO (~2.6 GB)"
echo "    → $OUT"
curl -fL --progress-bar -C - -o "$OUT" "$URL"
echo "==> Done: $OUT"