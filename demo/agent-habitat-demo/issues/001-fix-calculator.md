# Fix calculator module — tests failing

**Labels:** `agent-triage`, `bug`, `good first issue`

## Summary

`python3 -m pytest` fails in CI. The `habitat/calc.py` module has regressions.

## Acceptance criteria

- [ ] `pytest -q` passes locally
- [ ] Only modify `habitat/calc.py` unless tests are objectively wrong
- [ ] `sum_range(1, 5)` returns 15
- [ ] `is_palindrome("Racecar")` returns True
- [ ] `clamp(5, 10, 0)` returns 5 when bounds are inverted

## Hints

Run tests first. Fix one failure at a time.