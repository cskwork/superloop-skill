# Changelog - 2026-07-11

## Deliver mission: adversarial-review fix pass

Context: the 2026-07-10 adversarial review encoded five defect classes test-first - 18 red contract
assertions plus an executable crash-recovery state machine (`tests/delivery-state-machine.test.sh`,
`tests/fixtures/delivery-state-machine.sh`) - and intentionally left the branch red. This pass makes
the prose contracts match that executable ground truth.

### Decisions

1. **Split `reentry_prompt` into three fields.** `launch_prompt` (original `/loop ...` message,
   audit only, never re-parsed), `scheduled_payload` (parsed prompt without the interval token,
   recorded in both modes; the only thing a fixed cron re-fires), `dynamic_reentry_prompt`
   (`/loop `-prefixed dynamic wakeup prompt, `none` in fixed mode). Why: one field made every fixed
   re-entry re-parse `/loop 30m ...`, consuming the launch prompt as state; the state machine now
   rejects an init whose payload still starts with `/loop`.
   Rejected: one field plus prose rules on when to strip the interval - re-entry ambiguity is
   exactly what the fresh-context contract forbids.

2. **Two-staged close publication.** RECORD appends to a per-ticket provisional evidence bundle
   (run-vault path + close idempotency key); the immutable final close manifest is published only
   after the durable integration receipt exists, via sibling temp file + atomic rename, never
   overwriting an existing manifest; a contradicting receipt is fail-closed drift. Why: the manifest
   was previously written before integration proof, so a crash replay could overwrite final
   evidence, and shared evidence paths let one ticket clobber another's.
   Rejected: file locking on the manifest - atomic rename plus existence/digest check is portable
   and lock-free.

3. **Named stop `active_ticket_blocked`.** After the contract's max consecutive failed ticks on one
   active ticket: preserve the ticket and phase, record the stop durably, remove pacing (CronDelete
   the fixed job / omit ScheduleWakeup), reject re-arming and sibling claims until an explicit
   authorized resume. Why: without a breaker a stuck ticket burns scheduled ticks indefinitely, and
   a helpful tick could claim a sibling around the blockage, breaking the one-active-ticket
   invariant.
   Rejected: auto-skipping to the next unblocked ticket - silent frontier reordering hides failure
   and breaks resume-before-sibling.

### Verification

- All five suites green: deliver 96, loop-runtime 34, delivery state machine, observability 22,
  skill 65; `git diff --check` clean; no residual `reentry_prompt` vocabulary in operative docs.
- Independent fresh-context subagents: INIT bootstrap PASS (three derivability MINORs applied:
  `scheduled_payload` recorded in both modes, `target_is_shared` + contract digest + scheduler
  status named as INIT outputs) and TICK disk-resume PASS (all eight durable phases map 1:1 to the
  state machine; MINORs were fixture simplifications, no prose action).

### Residual / follow-up

- INIT steps 3/4/6 writes rely on validation to catch a torn file rather than atomic-rename
  discipline; maintenance-ticket candidate.
- State-machine fixture models a single ticket at shared root paths; extend to two live tickets if
  per-ticket path collisions ever need executable proof.
- Merge of `codex/superloop-deliver-lms` into `main` stays gated on explicit approval (GOAL d1);
  next frontier ticket is `DISC-001` (Figma feature discovery).
