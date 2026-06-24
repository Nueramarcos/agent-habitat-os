# Fix median() — even-length lists wrong

**Labels:** `agent-triage`, `bug`

## Summary

`median([1, 2, 3, 4])` returns `3.0` but should return `2.5`.

## Acceptance criteria

- [ ] `pytest -q` passes
- [ ] Only modify `habitat/calc.py`
- [ ] `median([])` still returns `0.0`