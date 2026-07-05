# Mission: verify - hold an orchestrator's delivery to its intent

Unit = **one acceptance criterion** - prove it against the spec, or direct a fix; the loop
converges at `all_criteria_proven`.

## ORIENT - build the Intent Spec (first tick)

Derive criteria from three sources: the original request/ticket, the orchestrator's own claims
(what it says it built), and surfaced/implicit requirements - negative constraints, must-preserve
invariants, non-goals. Each criterion is one testable clause plus a proof type (test / build / HTTP
body / DB read / architecture check). Missing-but-implied behavior is a criterion too: degenerate
inputs, error paths, security, concurrency - not only what was asked for in words. Capture the
result in `templates/intent-spec.md`; queue the acceptance criteria in the ledger, each starting
`unverified`.

## PICK

One criterion not `proven` / `blocked` / `awaiting-approval`. Empty queue -> refresh against the
delivered intent (did the orchestrator add scope since ORIENT?); still empty -> converged.

## EXECUTE - two shapes

### verify shape (default)

Adversarial passes against the **spec**, not the existing tests:

- **Intent pass** - read the diff + ticket/commit: what behavior was supposed to change?
- **Blast-radius pass** - callers/usages of changed symbols; shared DB tables (other readers of the
  same columns); shared API contracts/DTO consumers; config, cache keys, async/batch consumers.
- **Evidence pass** - run targeted real tests + build; hit the endpoint locally and assert the
  response **body**, not just the status; read-only DB checks when persisted data is load-bearing.
- **Degenerate-input sweep** - null / undefined / empty / boundary, per parameter.

Missing coverage on a risky path becomes a new failing-test criterion, not a silent gap.

### direct shape (criterion failed)

Emit a fix directive to the orchestrator (structure and dispatch paths in
`reference/orchestrator-handoff.md`), mark the criterion `in-progress`, and bump its fix-directive
count in `## Counters`. At the `orchestrator_cannot_close_gap` limit (default 2), escalate instead of
re-directing. A later tick re-verifies the `in-progress` criterion with fresh context.

## VERIFY

A criterion is `proven` only with fresh this-tick evidence, saved to `evidence/`. Tests/build green
but the response body or DB state contradicts the intent is `green_signal_wrong_outcome` - a fail,
not a pass; escalate. A 200 is not a pass.

## Named stops

- `green_signal_wrong_outcome` - see VERIFY above; the only verify-side stop.
- Fix-side stops (`tests_fail_after_one_fix`, `merge_conflict_requires_product_decision`,
  `orchestrator_cannot_close_gap`) live in `reference/orchestrator-handoff.md`.
