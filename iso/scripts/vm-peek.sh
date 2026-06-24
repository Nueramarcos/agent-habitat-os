#!/usr/bin/env bash
# Host-side VM health peek (no password required for heuristics)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DISK="$ROOT/iso/build/agent-habitat-test.qcow2"
PORT="${HABITAT_VM_SSH_PORT:-2222}"
USER="${HABITAT_VM_USER:-nuermarcos}"

echo "═══ Agent Habitat VM peek ═══"
echo ""

# Process
if pgrep -f 'qemu-system.*agent-habitat-test' >/dev/null; then
  pid="$(pgrep -f 'qemu-system.*agent-habitat-test' | head -1)"
  echo "VM:     running (pid $pid)"
  ps -p "$pid" -o rss=,etime= 2>/dev/null | awk '{printf "RAM:    %.1f GB RSS, uptime %s\n", $1/1024/1024, $2}'
else
  echo "VM:     not running"
fi

# Disk
if [[ -f "$DISK" ]]; then
  bytes="$(stat -c%s "$DISK" 2>/dev/null || stat -f%z "$DISK")"
  gb="$(awk "BEGIN {printf \"%.1f\", $bytes/1024/1024/1024}")"
  mtime="$(stat -c%y "$DISK" 2>/dev/null | cut -d. -f1)"
  echo "Disk:   ${gb} GB ($DISK)"
  echo "        last write: $mtime"
  if awk "BEGIN {exit !($bytes > 7000000000)}"; then
    echo "Hint:   >7 GB usually means Ollama models were pulled ✓"
  elif awk "BEGIN {exit !($bytes > 4500000000)}"; then
    echo "Hint:   >4.5 GB = Ubuntu installed; Habitat may still be provisioning"
  else
    echo "Hint:   <4.5 GB = install likely incomplete"
  fi
fi

# SSH
if ss -tln 2>/dev/null | grep -q ":$PORT "; then
  echo "SSH:    port $PORT listening"
else
  echo "SSH:    port $PORT not forwarded"
fi

# Remote verify (needs password or key)
if [[ -n "${HABITAT_VM_PASSWORD:-}" ]] && command -v sshpass >/dev/null; then
  echo ""
  echo "── Remote checks (sshpass) ──"
  sshpass -p "$HABITAT_VM_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -p "$PORT" "${USER}@127.0.0.1" \
    'whoami; hostname; test -f ~/.habitat-provisioned && echo provisioned; habitat verify 2>&1 | tail -5' || true
elif ssh -o BatchMode=yes -o ConnectTimeout=3 -p "$PORT" "${USER}@127.0.0.1" true 2>/dev/null; then
  echo "SSH:    key auth works as $USER"
else
  echo ""
  echo "── Confirm inside VM (GTK console) ──"
  echo "  habitat verify"
  echo "  tail -5 ~/habitat-install.log"
  echo ""
  echo "Or from host with password:"
  echo "  HABITAT_VM_USER=nuermarcos HABITAT_VM_PASSWORD='...' habitat iso peek"
fi