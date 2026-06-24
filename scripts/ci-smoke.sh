#!/usr/bin/env bash
# CI-friendly smoke — no downloaded ISO or KVM required
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OK=0
FAIL=0

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; OK=$((OK+1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

echo "Agent Habitat CI smoke"
echo ""

[[ -f "$ROOT/iso/cloud-init/user-data.yaml" ]] && pass "autoinstall user-data" || fail "user-data.yaml missing"
[[ -f "$ROOT/first-boot/install.sh" ]] && pass "first-boot/install.sh" || fail "install.sh missing"
[[ -f "$ROOT/first-boot/provision.sh" ]] && pass "first-boot/provision.sh" || fail "provision.sh missing"
[[ -f "$ROOT/scripts/habitat" ]] && pass "habitat CLI" || fail "habitat CLI missing"
[[ -f "$ROOT/demo/agent-habitat-demo/habitat/calc.py" ]] && pass "demo calc.py" || fail "demo missing"
command -v bash >/dev/null && pass "bash" || fail "bash missing"

bash -n "$ROOT/first-boot/install.sh" && pass "install.sh syntax" || fail "install.sh syntax"
bash -n "$ROOT/first-boot/provision.sh" && pass "provision.sh syntax" || fail "provision.sh syntax"
bash -n "$ROOT/scripts/habitat" && pass "habitat syntax" || fail "habitat syntax"

if grep -q '^autoinstall:' "$ROOT/iso/cloud-init/user-data.yaml" 2>/dev/null; then
  pass "autoinstall block"
else
  fail "autoinstall block"
fi

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "CI smoke: $OK passed"
  exit 0
fi
echo "CI smoke: $OK passed, $FAIL failed"
exit 1