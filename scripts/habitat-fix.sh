#!/usr/bin/env bash
# habitat fix — zero-rescue loop: doctor → agent → sanitize → test → PR → merge
set -euo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RECORD="$HABITAT_ROOT/flight-recorder/fix.jsonl"
REPO="${1:-}"
ISSUE="${2:-}"
MERGE="${HABITAT_FIX_MERGE:-1}"
START_EPOCH="$(date +%s)"

log() { printf '\033[38;5;141m[habitat fix]\033[0m %s\n' "$*"; }
die() { log "error: $*"; record_outcome "failure_ledger" "$*"; exit 1; }

record_outcome() {
  local outcome="$1" detail="${2:-}"
  mkdir -p "$(dirname "$RECORD")"
  local ts dur model
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  dur=$(( $(date +%s) - START_EPOCH ))
  model="$(grep -E '^model' "$HOME/issue-agent/config.local.toml" 2>/dev/null | head -1 | cut -d'"' -f2 || echo unknown)"
  printf '{"outcome":"%s","repo":"%s","issue_num":%s,"detail":"%s","lane":"local","model":"%s","duration_secs":%s,"ts":"%s","source":"habitat-fix.sh"}\n' \
    "$outcome" "$REPO" "${ISSUE:-null}" "${detail//\"/\\\"}" "$model" "$dur" "$ts" >> "$RECORD"
}

slugify() { echo "$1" | tr '/:' '__'; }

issue_is_closed() {
  local state
  state="$(gh issue view "$ISSUE" -R "$REPO" --json state --jq '.state' 2>/dev/null || true)"
  [[ "$state" == "CLOSED" ]]
}

find_merged_pr() {
  gh pr list -R "$REPO" --state merged --search "Fix issue #$ISSUE" \
    --json url,number --jq 'sort_by(.number) | reverse | .[0].url // empty' 2>/dev/null || true
}

find_open_pr() {
  local branch="$1"
  gh pr list -R "$REPO" --head "$branch" --state open \
    --json url --jq '.[0].url // empty' 2>/dev/null || true
}

ensure_gitignore_venvs() {
  local gi=".gitignore"
  touch "$gi"
  for pat in .issue-agent-venv/ .venv/ __pycache__/ .pytest_cache/; do
    grep -qxF "$pat" "$gi" 2>/dev/null || echo "$pat" >> "$gi"
  done
}

stage_clean_changes() {
  ensure_gitignore_venvs
  git reset HEAD .issue-agent-venv .venv 2>/dev/null || true
  rm -rf .issue-agent-venv
  git add -A -- ':!.issue-agent-venv' ':!.issue-agent-venv/**' ':!.venv' ':!.venv/**' 2>/dev/null \
    || git add habitat/ tests/ .gitignore 2>/dev/null || true
}

recover_workspace() {
  local ws="$1"
  [[ -d "$ws" ]] || return 1
  cd "$ws"
  bash "$HABITAT_ROOT/agent-runtime/sanitize-workspace.sh" "$ws" 2>/dev/null || true
  rm -f Output output 2>/dev/null || true
  if git ls-files --error-unmatch .issue-agent-venv >/dev/null 2>&1; then
    git rm -rf --cached .issue-agent-venv 2>/dev/null || true
    rm -rf .issue-agent-venv
  fi
  # Strip aider trailers from Python if sanitizer missed
  python3 -c "
import pathlib, re
pat = re.compile(r'\n+FILES_CHANGED:.*\Z', re.DOTALL)
for p in pathlib.Path('habitat').rglob('*.py'):
    t = p.read_text(encoding='utf-8')
    n = pat.sub('\n', t)
    if n != t: p.write_text(n.rstrip()+'\n', encoding='utf-8')
" 2>/dev/null || true
  local venv=".venv"
  [[ -x "$venv/bin/pytest" ]] || { python3 -m venv "$venv" && "$venv/bin/pip" install -q pytest; }
  if "$venv/bin/python" -m pytest -q 2>&1; then
    return 0
  fi
  return 1
}

open_pr_if_needed() {
  local ws="$1" branch="$2"
  cd "$ws"
  local existing
  existing="$(find_open_pr "$branch")"
  if [[ -n "$existing" ]]; then
    echo "$existing"
    return 0
  fi
  if issue_is_closed; then
    log "issue #$ISSUE already closed — skipping recovery PR"
    return 1
  fi
  git push -u origin "$branch" 2>/dev/null || git push -f origin "$branch"
  gh api "repos/$REPO/pulls" \
    -f title="Fix issue #$ISSUE" \
    -f head="$branch" -f base="main" \
    -f body="Closes #$ISSUE. Shipped via habitat fix (zero-rescue loop)."
}

wait_and_merge() {
  local pr_url="$1"
  local pr_num="${pr_url##*/}"
  local pr_state
  pr_state="$(gh pr view "$pr_num" -R "$REPO" --json state --jq '.state' 2>/dev/null || true)"
  if [[ "$pr_state" == "MERGED" ]]; then
    log "PR #$pr_num already merged"
    return 0
  fi
  [[ "$MERGE" == "1" ]] || { log "merge skipped (HABITAT_FIX_MERGE=0)"; return 0; }
  log "waiting for CI on PR #$pr_num..."
  for _ in $(seq 1 36); do
    if gh pr checks "$pr_num" -R "$REPO" 2>/dev/null | grep -qE 'fail|failure'; then
      die "CI failed on PR #$pr_num"
    fi
    if gh pr checks "$pr_num" -R "$REPO" 2>/dev/null | grep -qE 'pass|skipping'; then
      if ! gh pr checks "$pr_num" -R "$REPO" 2>/dev/null | grep -qE 'pending|in_progress'; then
        break
      fi
    fi
    sleep 10
  done
  if gh pr merge "$pr_num" -R "$REPO" --squash --delete-branch 2>/dev/null; then
    log "merged PR #$pr_num"
    return 0
  fi
  log "auto-merge skipped — review PR #$pr_num manually"
  return 0
}

[[ -n "$REPO" && -n "$ISSUE" ]] || die "usage: habitat fix <owner/repo> <issue-number>"

export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.grok/bin:$PATH"
export HABITAT_ROOT
export ISSUE_AGENT_GITHUB_QUIET="${ISSUE_AGENT_GITHUB_QUIET:-1}"
export HABITAT_MAX_FIX_RETRIES="${HABITAT_MAX_FIX_RETRIES:-3}"

log "═══ Habitat Fix (flawless zero-rescue) ═══"
log "repo=$REPO issue=#$ISSUE"

log "preflight: doctor + feedback"
HABITAT_DOCTOR_FIX=1 bash "$HABITAT_ROOT/scripts/habitat-doctor.sh" >/dev/null 2>&1 || true
bash "$HABITAT_ROOT/scripts/flight-recorder-feedback.sh" 2>/dev/null || true

SLUG="$(slugify "$REPO")"
WS="$HOME/agent-workspaces/${SLUG}-issue-${ISSUE}"
BRANCH="fix/issue-${ISSUE}"

# Fast path: issue already resolved (e.g. prior run or issue-agent merged + deleted branch)
if issue_is_closed; then
  PR_URL="$(find_merged_pr)"
  if [[ -n "$PR_URL" ]]; then
    log "issue #$ISSUE already closed — merged PR: $PR_URL"
    record_outcome "merge_success" "$PR_URL (already resolved)"
    log "═══ Done in $(( $(date +%s) - START_EPOCH ))s (no agent run) ═══"
    exit 0
  fi
fi

log "phase: plan (local — no GitHub)"
bash "$HABITAT_ROOT/scripts/habitat-plan.sh" "$REPO" "$ISSUE" 2>&1 | tee "/tmp/habitat-plan-${ISSUE}.log" || true
export HABITAT_PLAN_PATH="$WS/.habitat-plan.json"

log "phase: fix (plan → aider → test → Tower → Human Tower → retry up to ${HABITAT_MAX_FIX_RETRIES}x)"
set +e
issue-agent fix "$REPO" "$ISSUE" 2>&1 | tee "/tmp/habitat-fix-${ISSUE}.log"
AGENT_RC=${PIPESTATUS[0]}
set -e

PR_URL=""
if [[ "$AGENT_RC" -eq 0 ]]; then
  PR_URL="$(find_open_pr "$BRANCH")"
  [[ -z "$PR_URL" ]] && PR_URL="$(find_merged_pr)"
  if [[ -n "$PR_URL" ]] || issue_is_closed; then
    PR_URL="${PR_URL:-$(find_merged_pr)}"
    log "issue-agent succeeded (merged or closed)"
  fi
fi

# Recovery only when agent failed AND issue still open AND no merged PR exists
if [[ -z "$PR_URL" ]] && ! issue_is_closed && [[ -z "$(find_merged_pr)" ]]; then
  if recover_workspace "$WS"; then
    log "recovery: tests pass — finishing PR pipeline"
    cd "$WS"
    if [[ "${HABITAT_HUMAN_TOWER:-1}" == "1" ]] && [[ -x "$HOME/issue-agent/scripts/human-tower-gate.sh" ]]; then
      log "Human Tower: maintainer-voice review..."
      if ! bash "$HOME/issue-agent/scripts/human-tower-gate.sh" "$REPO" "$WS" "Fix issue #$ISSUE" 2>&1 | tee "/tmp/human-tower-${ISSUE}.log"; then
        die "Human Tower rejected recovery diff — see /tmp/human-tower-${ISSUE}.log"
      fi
    fi
    stage_clean_changes
    if ! git diff --cached --quiet; then
      git commit -m "Fix issue #$ISSUE (habitat fix recovery)" 2>/dev/null || true
    fi
    PR_URL="$(open_pr_if_needed "$WS" "$BRANCH" || true)"
  fi
fi

# Final resolution check after agent + optional recovery
if [[ -z "$PR_URL" ]]; then
  PR_URL="$(find_merged_pr)"
fi
[[ -n "$PR_URL" ]] || die "no PR produced — see /tmp/habitat-fix-${ISSUE}.log"

log "PR: $PR_URL"
wait_and_merge "$PR_URL"

if [[ "$REPO" == *agent-habitat-demo* ]]; then
  cd "$HABITAT_ROOT/demo/agent-habitat-demo"
  git pull --ff-only origin main 2>/dev/null || true
  habitat demo 2>&1 | tail -3 || true
fi

record_outcome "merge_success" "$PR_URL"
log "═══ Done in $(( $(date +%s) - START_EPOCH ))s ═══"
log "PR: $PR_URL"