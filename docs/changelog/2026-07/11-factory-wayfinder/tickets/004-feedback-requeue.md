# FCT-004 - Feedback / improvement auto-requeue

- Route: GREENFIELD
- Blocked by: FCT-002, FCT-003
- Unblocks: FCT-006

## Slice

Verification FAIL or a surfaced improvement becomes a corrective ticket appended to the frontier (via the
meta-prompter), with de-dupe + a convergence guard so the loop self-corrects without looping forever.

## Acceptance (EARS)

- WHEN a ticket's exact verify fails THEN append a corrective ticket citing the failed criterion.
- WHEN the same target requeues more than N times (default 3) THEN stop with `convergence_blocked`
  instead of requeuing again.
- WHEN a duplicate corrective ticket already exists THEN merge, do not duplicate.

## Proof commands

- Requeue test: fail -> corrective ticket appended; (N+1)th requeue -> `convergence_blocked` stop.

## Non-goals

- Fixing the underlying defect (that is the corrective ticket's own delivery).
