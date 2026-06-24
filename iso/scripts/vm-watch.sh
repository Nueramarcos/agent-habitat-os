#!/usr/bin/env bash
# Monitor Agent Habitat VM install progress
set -euo pipefail

BUILD="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/iso/build"
DISK="$BUILD/agent-habitat-test.qcow2"

echo "Agent Habitat VM watch — $(date)"
echo "  disk: $DISK"
echo ""

if pgrep -f 'qemu-system.*agent-habitat-test' >/dev/null; then
  echo "  QEMU: running"
else
  echo "  QEMU: not running"
fi

if [[ -f "$DISK" ]]; then
  echo "  size: $(du -h "$DISK" | cut -f1)"
fi

ss -tln 2>/dev/null | grep -q ':2222 ' && echo "  ssh:  port 2222 forwarded" || echo "  ssh:  port 2222 down"

if [[ -f "$BUILD/qemu-gui.pid" ]]; then
  echo "  gui pid: $(cat "$BUILD/qemu-gui.pid")"
fi

echo ""
echo "Milestones:"
echo "  < 500M  → GRUB / early installer"
echo "  > 1G    → autoinstall writing"
echo "  > 4G    → install likely complete — stop GUI VM, run: habitat iso boot-disk"
echo ""
echo "After boot-disk + 60s:"
echo "  habitat iso ssh 'sudo journalctl -u agent-habitat-firstboot -f'"