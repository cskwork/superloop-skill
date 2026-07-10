# SL-001 - scheduled fresh-context deliver mission

Route: LEGACY

Blocked by: none

Unblocks: DISC-001, APP-001, APP-*

## User story

As an operator of a large project, I want each scheduler tick to start from durable state and deliver
one feature through supergoal, so work can safely continue for one or two days without relying on one
conversation's context.

## Acceptance criteria

- WHEN `deliver` starts without durable program state THEN superloop SHALL initialize one root goal, Frontier Map, vertical ticket graph, contract, and delivery ledger before scheduling repetition.
- WHEN a tick starts THEN it SHALL reconstruct state from disk, acquire one atomic lease, resume the active ticket or claim exactly one unblocked ticket, and SHALL NOT dispatch a sibling.
- WHEN a ticket is claimed THEN superloop SHALL invoke the installed supergoal workflow with a self-contained ticket brief and scheduled auto-approval reason.
- WHEN supergoal reports completion THEN superloop SHALL close the ticket only if its GOAL, QA PASS, fulfilled run-state, DONE marker, commit gate, and named integration proof all agree.
- WHEN the ticket closes THEN superloop SHALL record evidence, update the map/frontier, release the lease, and only then pace the next tick.
- WHEN a consent gate, deadline, budget, repeated failure, unavailable supergoal, or ambiguous product decision occurs THEN superloop SHALL pause or stop with durable evidence instead of guessing.

## Edge cases

- Cron fires while the prior tick still owns the lease.
- A tick crashes after claiming but before dispatch, or after supergoal finishes but before RECORD.
- The active ticket's vault is partial or contradicts its ledger state.
- No unblocked frontier exists because all remaining tickets need a user decision.
- Skill-maintenance work is discovered while a product ticket is active.

## Scope boundaries

- Include reusable skill/docs/templates/tests needed for `deliver`.
- Preserve the existing `verify` mission and TUI reader behavior.
- Do not implement LMS product code in this ticket.

## Proof commands

- `bash tests/deliver-contract.test.sh`
- `for t in tests/*.test.sh; do bash "$t"; done`
- `git diff --check`

