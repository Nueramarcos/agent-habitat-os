# Flight Recorder

Structured audit trail for agent outcomes. Issue Agent writes to:

```
~/issue-agent/flight-recorder/trajectories.jsonl
```

Each line is one JSON object. Schema: [`schema.json`](schema.json).

## Example events

```json
{"outcome":"merge_success","repo":"you/demo","issue_num":1,"lane":"local","model":"qwen2.5-coder:7b","ts":"2026-06-23T12:00:00Z"}
{"outcome":"failure_ledger","kind":"no_commits","hint":"Model produced no diff","repo":"you/demo","lane":"local","ts":"2026-06-23T12:05:00Z"}
```

## Habitat verify logging

`habitat verify` appends to `~/agent-habitat-os/flight-recorder/verify.jsonl` when checks pass or fail.

## Why this matters

Teams like SpaceX/Tesla-style engineering cultures need **replayable agent decisions**, not black-box chat. Flight recorder is the trust layer.