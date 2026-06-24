#!/usr/bin/env bash
# Remove junk files before Tower review (Output, bad .gitignore, etc.)
set -euo pipefail

WS="${1:-.}"
cd "$WS"
rm -f Output output .aider.conf.yml 2>/dev/null || true
if [[ -f .gitignore ]] && head -1 .gitignore | grep -qE '^[^#[:space:]]'; then
  # Orion rejects invalid-syntax .gitignore from aider
  if ! python3 -m py_compile .gitignore 2>/dev/null; then
    git checkout HEAD -- .gitignore 2>/dev/null || rm -f .gitignore
  fi
fi
git add -A 2>/dev/null || true