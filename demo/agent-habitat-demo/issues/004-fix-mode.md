# Fix mode() — returns least frequent value

**Labels:** `agent-triage`, `bug`

## Summary

`mode([1, 2, 2, 3])` returns `1` but should return `2`.

## Acceptance criteria

- [ ] `pytest -q` passes
- [ ] Only modify `habitat/calc.py`
- [ ] `mode([])` still returns `None`