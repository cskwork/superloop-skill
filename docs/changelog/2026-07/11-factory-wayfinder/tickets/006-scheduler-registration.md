# FCT-006 - Scheduler / loop-task registration for autonomous ticks

- Route: GREENFIELD
- Blocked by: FCT-004

## Slice

Register the recurring fresh-context tick (deliver `scheduler_job_id` via a `/schedule` cloud routine or
`/loop`), with cadence, tick budget, deadline, and `checkin_every_n_ticks`. ORIENT re-verifies the job
each tick.

## Acceptance (EARS)

- WHEN registered THEN a durable job id is recorded and re-verified on every ORIENT.
- WHEN the job is missing/unreadable THEN the tick fail-closes with `scheduler_job_missing` and does NOT
  invent a replacement.

## Proof commands

- Registration + ORIENT-verification test; a dry-run tick fires in a fresh context and reconstructs from
  disk only.

## Non-goals

- The tick's delivery logic (already covered by deliver + FCT-002 router).
