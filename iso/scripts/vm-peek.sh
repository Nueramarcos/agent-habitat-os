#!/usr/bin/env bash
# Host-side VM health peek (no password required for heuristics)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLOUD_DISK="$ROOT/iso/build/agent-habitat-cloud.qcow2"
DISK="$ROOT/iso/build/agent-habitat-test.qcow2"
[[ -f "$CLOUD_DISK" ]] && DISK="$CLOUD_DISK"
PORT="${HABITAT_VM_SSH_PORT:-2222}"
USER="${HABITAT_VM_USER:-ubuntu}"
PASS="${HABITAT_VM_PASSWORD:-ubuntu}"

echo "═══ Agent Habitat VM peek ═══"
echo ""

# Process
if pgrep -f 'qemu-system.*agent-habitat-(cloud|test)' >/dev/null; then
  pid="$(pgrep -f 'qemu-system.*agent-habitat-(cloud|test)' | head -1)"
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
HABITAT_VM_PASSWORD="${HABITAT_VM_PASSWORD:-$PASS}"
if [[ -n "$HABITAT_VM_PASSWORD" ]]; then
  echo ""
  echo "── Remote checks ──"
  if command -v sshpass >/dev/null; then
    sshpass -p "$HABITAT_VM_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -p "$PORT" "${USER}@127.0.0.1" \
      'export PATH=$HOME/.local/bin:$HOME/bin:$HOME/.grok/bin:$PATH; whoami; hostname; test -f ~/.habitat-provisioned && echo provisioned; habitat verify 2>&1 | tail -6' || true
  elif [[ -x /tmp/sshpeek/bin/python3 ]] || python3 -m venv /tmp/sshpeek 2>/dev/null; then
    [[ -x /tmp/sshpeek/bin/python3 ]] || true
    /tmp/sshpeek/bin/pip install -q paramiko 2>/dev/null || true
    HABITAT_VM_PASSWORD="$HABITAT_VM_PASSWORD" HABITAT_VM_USER="$USER" HABITAT_VM_SSH_PORT="$PORT" \
      /tmp/sshpeek/bin/python3 - <<'PY' || true
import os, paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("127.0.0.1", port=int(os.environ.get("HABITAT_VM_SSH_PORT", 2222)),
          username=os.environ["HABITAT_VM_USER"], password=os.environ["HABITAT_VM_PASSWORD"],
          timeout=15, allow_agent=False, look_for_keys=False)
_, o, _ = c.exec_command("export PATH=$HOME/.local/bin:$HOME/bin:$HOME/.grok/bin:$PATH; whoami; hostname; habitat verify 2>&1 | tail -6")
print(o.read().decode())
c.close()
PY
  fi
elif ssh -o BatchMode=yes -o ConnectTimeout=3 -p "$PORT" "${USER}@127.0.0.1" true 2>/dev/null; then
  echo "SSH:    key auth works as $USER"
else
  echo ""
  echo "── Confirm inside VM (GTK console) ──"
  echo "  habitat verify"
  echo "  tail -5 ~/habitat-install.log"
  echo ""
  echo "Or from host with password:"
  echo "  HABITAT_VM_USER=ubuntu HABITAT_VM_PASSWORD=ubuntu habitat iso peek"
fi