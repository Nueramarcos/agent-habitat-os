#!/usr/bin/env bash
# habitat human-review — corpus collect, export, stats, model bootstrap
set -euo pipefail

HABITAT_ROOT="${HABITAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ISSUE_AGENT_ROOT="${ISSUE_AGENT_ROOT:-$HOME/issue-agent}"

log() { printf '\033[38;5;141m[human-review]\033[0m %s\n' "$*"; }

ACTION="${1:-stats}"
shift || true

case "$ACTION" in
  collect)
    log "Archivist: harvesting human PR reviews from GitHub..."
    issue-agent-human-review collect "$@"
    ;;
  collect-deep)
    log "Archivist DEEP: versatile complex PR discourse (all tiers)..."
    issue-agent-human-review collect-deep "$@"
    ;;
  export)
    log "Librarian: exporting LoRA instruction dataset..."
    issue-agent-human-review export "$@"
    ;;
  stats)
    issue-agent-human-review stats
    ;;
  review)
    issue-agent-human-review review "$@"
    ;;
  bootstrap)
    log "Mentor: creating customs-reviewer-1.5b base model..."
    bash "$ISSUE_AGENT_ROOT/scripts/create-reviewer-model.sh"
    ;;
  team)
    log "═══ Human Reviewer Team ═══"
    log "1 Archivist  → collect merged PRs + maintainer comments"
    log "2 Librarian  → export human-reviewer-lora.jsonl"
    log "3 Mentor     → customs-reviewer-1.5b (bootstrap)"
    log "4 Human Tower→ RAG + model gate before push"
    log "5 Tower      → deterministic safety (existing)"
    echo ""
    issue-agent-human-review stats
    ;;
  *)
    echo "usage: habitat human-review {collect|collect-deep|export|stats|review|bootstrap|team}"
    exit 1
    ;;
esac