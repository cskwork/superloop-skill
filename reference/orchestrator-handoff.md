# Orchestrator handoff - turning a failed criterion into a fix

A criterion that fails verification becomes a fix directive the orchestrator executes. superloop
owns verify / direct / converge; the execution discipline - smallest correct change, failing test
first, verify vs real tests - is **supergoal**'s, not superloop's.

## The fix directive

Structured and evidence-backed, never "please fix this":

- **criterion** - the exact clause from the Intent Spec that failed.
- **failing evidence** - the command run and its output (or response body / DB read) proving the gap.
- **spec clause violated** - quoted verbatim; the fix targets the spec, not the existing tests.
- **scope bound** - max files the fix may touch; exceeding it escalates rather than widens.
- **acceptance test** - the specific check that must go green before the criterion is `proven`.

## Dispatch paths

1. **supergoal DEBUG in-tick** - load supergoal with the directive as its DEBUG objective:
   reproduce with a failing test first, then the smallest change to green, verified against real
   tests. The fix lands in a dedicated worktree (`.superloop/verify/worktree`, see
   `reference/worktree.md`), never the working branch; merge into the working branch only after a
   green VERIFY, and pushing or merging anywhere shared needs explicit consent.
2. **symphony ticket** - when an orchestrator swarm is live, file or append a ticket with the
   directive as its acceptance criteria; re-verify when the ticket returns.
3. **report-only** - write the directive to the ledger, mark the criterion `awaiting-approval`,
   and propose the fix; no write happens until the user consents.

## Deploy-gate

When a fix must reach a deployed environment to be proven: pushing or merging to a shared branch
and the deploy itself are consent gates - `awaiting-approval`, name the exact diff/branch that will
move, proceed only on explicit **APPROVED**; the gate cannot be skipped for any reason. Post-deploy,
prove it for real: env health + browser E2E on the deployed URL + a log sweep + a blast-radius
re-run of adjacent flows. A healthy deploy is not a correct deploy.

## Fresh-context re-verify

Re-verification happens in a later loop iteration, with fresh context - the ledger is the only
memory that survives. Never mark a criterion `proven` from the fixer's own claim; re-run the
acceptance test yourself before recording it.

## Named stops

- `tests_fail_after_one_fix` - one fix attempt didn't green the suite -> revert, mark the criterion
  `blocked` with the red output; never iterate fixes blindly.
- `merge_conflict_requires_product_decision` - a conflict needing a human call -> `awaiting-approval`,
  never guess a resolution.
- `orchestrator_cannot_close_gap` - the same criterion still fails after the fix-directive limit
  (default 2) -> escalate `awaiting-approval` with the full evidence trail.
