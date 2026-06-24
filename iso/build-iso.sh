#!/usr/bin/env bash
# Agent Habitat OS — ISO build helper (stages repo, prints Cubic steps)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE="${ROOT}/iso/build/staging"
PROFILE="${HABITAT_PROFILE:-hybrid}"

echo "==> Agent Habitat ISO staging"
echo "    profile: $PROFILE"
echo "    stage:   $STAGE"

rm -rf "$STAGE"
mkdir -p "$STAGE"
rsync -a --exclude 'iso/build' --exclude '.git' "$ROOT/" "$STAGE/agent-habitat-os/"

cat <<EOF

==> Staging complete: $STAGE/agent-habitat-os

Next — build ISO with Cubic (see iso/README.md):

  1. sudo apt install cubic
  2. Open Cubic, select Ubuntu 24.04 ISO
  3. Add packages from iso/packages.list
  4. In chroot: copy $STAGE/agent-habitat-os to /home/ubuntu/
  5. Post-install: iso/autoinstall/post-install.sh
  6. HABITAT_PROFILE=$PROFILE

Or test provisioning without ISO:

  cd $ROOT && ./first-boot/install.sh

EOF