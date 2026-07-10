# R-LOOP - verifier -> implementer loop channel

Append one timestamped section for each failed verification pass. Never rewrite older sections.

## 2026-07-10T13:44:28Z - Improve full spec

- Closed three frozen-contract gaps: distinct immutable `root-goal.md`; atomic active-ticket/run
  publication and reread before dispatch; same-ticket/run/revision binding for exact close evidence.
- Added explicit one-to-two-day `deadline_at` normalization and verbatim scheduled `reentry_prompt`.
- Proof: all four shell contract suites pass; skill validation passes; `git diff --check` passes.
- Next: fresh-context Improve edge cases; do not close criteria from this role.

## 2026-07-10T13:50:15Z - Improve edge cases

- Added 17 red-first contract assertions for overlap/crash recovery, stale leases, active-ticket
  deadline/check-in stops, digest/version/worktree drift, missing scheduler jobs, gated integration,
  and close replay; all are green.
- Bound recovery to durable active phases, frozen supergoal/commit-gate and ref digests, an explicit
  lease recovery rule, scheduler reconciliation, and integration idempotency keys/receipts.
- Proof: all four shell contract suites pass; skill validation passes; `git diff --check` passes.
- Next: fresh-context Mandatory Adversarial Review; do not close criteria from this role.

## 2026-07-10T15:15:55Z - Mandatory Adversarial Review -> fix pass

- Adversarial review encoded five defect classes red-first: launch/scheduled/dynamic prompt
  separation, per-ticket provisional evidence, immutable atomic final close manifest,
  `active_ticket_blocked` breaker, and an executable crash-recovery state machine
  (18 red assertions plus `tests/delivery-state-machine.test.sh`).
- Fix pass: split `reentry_prompt` into `launch_prompt` (audit-only) / `scheduled_payload` (parsed
  cron payload, recorded in both modes) / `dynamic_reentry_prompt` across contract, ledger,
  loop-runtime, and loop-contract; RECORD is two-staged (per-ticket provisional bundle -> durable
  integration receipt -> atomic rename to the immutable final close manifest, no overwrite, receipt
  drift fail-closed); named stop `active_ticket_blocked` preserves the active ticket, removes pacing
  (CronDelete / omit ScheduleWakeup), and rejects sibling claims.
- Fresh-context verification: INIT bootstrap PASS and TICK disk-resume PASS (independent subagents,
  dual prose/state-machine citations); three derivability MINORs applied (`scheduled_payload`
  recorded in both modes; `target_is_shared`, contract digest, scheduler status named as INIT
  outputs).
- Proof: deliver 96, loop-runtime 34, delivery state machine PASS, observability 22, skill 65;
  `git diff --check` clean.
- Residual: INIT steps 3/4/6 writes lack explicit atomic-rename discipline (a torn file is caught by
  validation, not prevented) - maintenance-ticket candidate.
