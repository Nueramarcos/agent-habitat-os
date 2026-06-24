# Fix geometric_mean() — returns arithmetic mean

**Labels:** `agent-triage`, `bug`

## Summary

`geometric_mean([1, 2, 4])` returns `2.333...` (arithmetic mean) but should return `2.0`.

## Acceptance criteria

- [ ] `pytest -q` passes
- [ ] Only modify `habitat/calc.py`
- [ ] `geometric_mean([])` returns `0.0`
- [ ] Non-positive inputs return `0.0`