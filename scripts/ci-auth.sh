#!/usr/bin/env bash
# Grant workflow scope to gh, then push demo CI
set -euo pipefail

echo "==> Agent Habitat CI auth"
echo ""
echo "GitHub blocks workflow files without the 'workflow' OAuth scope."
echo "This script refreshes gh credentials (keyring), not GITHUB_TOKEN env."
echo ""

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  echo "Note: unsetting GITHUB_TOKEN for this session (it lacks workflow scope)."
  export GITHUB_TOKEN=""
fi

echo "Run in your terminal (interactive — browser/device code):"
echo ""
echo "  env -u GITHUB_TOKEN gh auth refresh -h github.com -s workflow,repo"
echo "  habitat ci-setup"
echo ""

if env -u GITHUB_TOKEN gh auth refresh -h github.com -s workflow,repo 2>/dev/null; then
  echo ""
  echo "==> Scope refreshed — pushing CI..."
  env -u GITHUB_TOKEN bash "$(dirname "$0")/setup-demo-ci.sh"
else
  echo "Interactive refresh required — run the commands above manually."
  exit 1
fi