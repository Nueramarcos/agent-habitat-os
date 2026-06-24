#!/usr/bin/env bash
# Push CI workflow to agent-habitat-demo (requires gh workflow scope)
set -euo pipefail

REPO="${1:-Nueramarcos/agent-habitat-demo}"
HABITAT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WF="${HABITAT_CI_WORKFLOW:-$HABITAT_ROOT/ci/templates/demo-ci.yml}"

die() { echo "setup-demo-ci: $*" >&2; exit 1; }
[[ -f "$WF" ]] || die "missing $WF"

# Check workflow scope
SCOPES="$(gh auth status 2>&1 | grep -oE "'[^']+'" | tr '\n' ' ' || true)"
if ! gh api "repos/${REPO}/actions/workflows" >/dev/null 2>&1; then
  echo "Cannot access Actions API for $REPO"
fi

push_via_git() {
  local tmp
  tmp="$(mktemp -d)"
  git clone "https://github.com/${REPO}.git" "$tmp/repo"
  cd "$tmp/repo"
  mkdir -p .github/workflows
  cp "$WF" .github/workflows/ci.yml
  git add .github/workflows/ci.yml
  git commit -m "Add CI workflow for pytest"
  if ! git push origin main 2>&1; then
    echo "git push rejected (workflow scope required)" >&2
    return 1
  fi
  if ! gh api "repos/${REPO}/actions/workflows" --jq '.total_count' 2>/dev/null | grep -qv '^0$'; then
    echo "CI verified on GitHub"
    return 0
  fi
  echo "push succeeded but workflow not visible — need: gh auth refresh -h github.com -s workflow" >&2
  return 1
}

push_via_api() {
  local b64 sha out
  b64="$(base64 -w0 "$WF")"
  if sha="$(gh api "repos/${REPO}/contents/.github/workflows/ci.yml" --jq .sha 2>/dev/null)"; then
    out="$(gh api --method PUT "repos/${REPO}/contents/.github/workflows/ci.yml" \
      -f message="Update CI workflow" -f content="$b64" -f branch=main -f sha="$sha" 2>&1)" || return 1
  else
    out="$(gh api --method PUT "repos/${REPO}/contents/.github/workflows/ci.yml" \
      -f message="Add CI workflow for pytest" -f content="$b64" -f branch=main 2>&1)" || return 1
  fi
  [[ "$out" == *'"content"'* ]] || { echo "$out"; return 1; }
  echo "CI pushed via API"
  return 0
}

echo "==> Adding CI workflow to $REPO"
echo "    scopes: $SCOPES"

if push_via_api 2>/dev/null; then
  exit 0
fi

echo "API push failed (workflow scope likely required). Trying git push..."
if push_via_git; then
  exit 0
fi

cat <<EOF

Failed — refresh GitHub CLI with workflow scope, then retry:

  habitat ci-auth
  # or manually:
  env -u GITHUB_TOKEN gh auth refresh -h github.com -s workflow,repo
  habitat ci-setup

Or add a fine-grained PAT with Actions: Read and write, then:

  export GH_TOKEN=ghp_...
  habitat ci-setup

EOF
exit 1