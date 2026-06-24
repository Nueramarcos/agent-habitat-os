#!/usr/bin/env bash
# habitat plan — repo brief + solution plan before fix (local only)
set -euo pipefail
REPO="${1:-}"
ISSUE="${2:-}"
[[ -n "$REPO" && -n "$ISSUE" ]] || { echo "usage: habitat plan <owner/repo> <issue>"; exit 1; }
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export ISSUE_AGENT_GITHUB_QUIET="${ISSUE_AGENT_GITHUB_QUIET:-1}"
issue-agent plan "$REPO" "$ISSUE"