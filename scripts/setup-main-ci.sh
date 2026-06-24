#!/usr/bin/env bash
# Push CI workflow to agent-habitat-os (requires gh workflow scope)
set -euo pipefail

REPO="${1:-Nueramarcos/agent-habitat-os}"
HABITAT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WF="${HABITAT_CI_WORKFLOW:-$HABITAT_ROOT/ci/templates/agent-habitat-ci.yml}"

die() { echo "setup-main-ci: $*" >&2; exit 1; }
[[ -f "$WF" ]] || die "missing $WF"

b64="$(base64 -w0 "$WF")"
if sha="$(env -u GITHUB_TOKEN gh api "repos/${REPO}/contents/.github/workflows/ci.yml" --jq .sha 2>/dev/null)"; then
  env -u GITHUB_TOKEN gh api --method PUT "repos/${REPO}/contents/.github/workflows/ci.yml" \
    -f message="Update CI workflow" -f content="$b64" -f branch=main -f sha="$sha"
else
  env -u GITHUB_TOKEN gh api --method PUT "repos/${REPO}/contents/.github/workflows/ci.yml" \
    -f message="Add CI workflow" -f content="$b64" -f branch=main
fi
echo "CI pushed to $REPO"