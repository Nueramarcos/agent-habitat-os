#!/usr/bin/env bash
exec bash "${ISSUE_AGENT_ROOT:-$HOME/issue-agent}/scripts/notify-zero.sh" "$@"