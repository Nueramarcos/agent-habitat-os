#!/usr/bin/env bash
# Session B: init guest + run issue-agent fix (host orchestrates SSH)
set -euo pipefail

PORT="${HABITAT_VM_SSH_PORT:-2222}"
USER="${HABITAT_VM_USER:-ubuntu}"
PASS="${HABITAT_VM_PASSWORD:-ubuntu}"
ISSUE="${1:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -z "$ISSUE" ]]; then
  echo "usage: habitat iso session-b <issue-number>"
  exit 1
fi

GH_TOKEN="$(env -u GITHUB_TOKEN gh auth token 2>/dev/null || true)"
if [[ -z "$GH_TOKEN" ]]; then
  echo "Host gh not authenticated — run: gh auth login"
  exit 1
fi

PY=/tmp/sshpeek/bin/python3
[[ -x "$PY" ]] || { python3 -m venv /tmp/sshpeek && /tmp/sshpeek/bin/pip install -q paramiko; }

HABITAT_VM_SSH_PORT="$PORT" HABITAT_VM_USER="$USER" HABITAT_VM_PASSWORD="$PASS" \
HABITAT_SESSION_ISSUE="$ISSUE" HABITAT_GH_TOKEN="$GH_TOKEN" \
"$PY" <<'PY'
import os, paramiko, sys, time

port = int(os.environ["HABITAT_VM_SSH_PORT"])
user = os.environ["HABITAT_VM_USER"]
password = os.environ["HABITAT_VM_PASSWORD"]
issue = os.environ["HABITAT_SESSION_ISSUE"]
gh_token = os.environ["HABITAT_GH_TOKEN"]

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
for i in range(24):
    try:
        c.connect("127.0.0.1", port=port, username=user, password=password,
                  timeout=12, allow_agent=False, look_for_keys=False)
        break
    except Exception as e:
        print(f"ssh wait {i+1}: {e}")
        time.sleep(15)
else:
    sys.exit("SSH failed")

path = 'export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.grok/bin:$PATH"'

def run(cmd, timeout=600, stream=False):
    print(f"$ {cmd[:80]}")
    _, o, e = c.exec_command(cmd, timeout=timeout)
    if stream:
        while not o.channel.exit_status_ready():
            chunk = o.readline()
            if chunk:
                print(chunk, end="")
            time.sleep(0.5)
        err = e.read().decode()
        if err:
            print(err)
        return ""
    out = o.read().decode() + e.read().decode()
    print(out)
    return out

run(path + '; whoami; hostname')
run("gh auth login --with-token 2>/dev/null <<'TOK'\n" + gh_token + "\nTOK")
run(path + '; gh auth status 2>&1 | head -4')
run(path + '; habitat init 2>&1')
run(path + '; habitat verify 2>&1 | tail -10')
run(path + '; issue-agent fix Nueramarcos/agent-habitat-demo ' + issue, timeout=1800, stream=True)
c.close()
PY