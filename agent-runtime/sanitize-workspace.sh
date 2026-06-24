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
# Strip aider "FILES_CHANGED:" trailer blocks pasted into Python sources
python3 <<'PY'
import pathlib, re
ws = pathlib.Path(".")
pat = re.compile(r"\n+FILES_CHANGED:.*\Z", re.DOTALL)
for p in ws.rglob("*.py"):
    if any(part in {".venv", "__pycache__", ".git"} for part in p.parts):
        continue
    try:
        text = p.read_text(encoding="utf-8")
    except OSError:
        continue
    new = pat.sub("\n", text)
    if new != text:
        p.write_text(new.rstrip() + "\n", encoding="utf-8")
PY

git add -A 2>/dev/null || true