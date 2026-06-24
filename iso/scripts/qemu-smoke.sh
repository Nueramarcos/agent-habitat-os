#!/usr/bin/env bash
# Quick smoke: verify ISO + cloud-init files exist; optional 120s boot probe
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/iso/build"
OK=0
FAIL=0

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; OK=$((OK+1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

echo "Agent Habitat ISO smoke test"
echo ""

[[ -f "$BUILD/ubuntu-24.04.3-live-server-amd64.iso" ]] && pass "Ubuntu ISO present" || fail "Ubuntu ISO missing (habitat iso download)"
[[ -f "$BUILD/usb/user-data" ]] && pass "user-data present" || fail "user-data missing"
[[ -f "$BUILD/usb/meta-data" ]] && pass "meta-data present" || fail "meta-data missing"
[[ -f "$BUILD/usb/seed.iso" ]] && pass "seed.iso present" || fail "seed.iso missing (habitat iso seed)"
command -v qemu-system-x86_64 >/dev/null && pass "qemu installed" || fail "qemu missing"
[[ -e /dev/kvm ]] && pass "KVM available" || fail "KVM unavailable (TCG only)"

if /usr/bin/grep -q '^autoinstall:' "$BUILD/usb/user-data" 2>/dev/null; then
  pass "autoinstall block in user-data"
else
  fail "autoinstall block missing from user-data"
fi

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "Smoke: $OK passed — run 'habitat iso vm' for full install test"
  echo "Monitor: habitat iso vm-status (disk should grow past 1G during install)"
  exit 0
fi
echo "Smoke: $OK passed, $FAIL failed"
exit 1