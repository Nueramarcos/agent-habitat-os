# Fix mean() — floor division bug

**Labels:** `agent-triage`, `bug`

## Summary

`mean([1, 2, 3, 4])` returns `2` but should return `2.5`. The implementation uses floor division.

## Acceptance criteria

- [ ] `pytest -q` passes
- [ ] Only modify `habitat/calc.py`
- [ ] `mean([])` still returns `0.0`