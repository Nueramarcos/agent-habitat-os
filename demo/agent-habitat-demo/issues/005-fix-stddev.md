# Fix stddev() — returns variance instead of standard deviation

**Labels:** `agent-triage`, `bug`

## Summary

`stddev()` should return the square root of population variance, but currently returns the raw variance.

Example: `stddev([2, 4, 4, 4, 5, 5, 7, 9])` returns `4.0` but should return `2.0`.

## Acceptance criteria

- [ ] `pytest -q` passes
- [ ] Only modify `habitat/calc.py`
- [ ] `stddev([])` returns `0.0`
- [ ] Use population standard deviation (sqrt of population variance)