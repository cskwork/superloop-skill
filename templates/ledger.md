# superloop ledger - <mission>

## Contract
<!-- Copied from templates/contract.md on the first tick. Read every ORIENT. Spec: reference/loop-contract.md -->
- trigger: <interval | dynamic | event-gated>
- scope: include <...> / exclude <...>
- permissions: unattended <...> / gates <push/merge/deploy/Jira/data writes>
- budget: max_ticks <N> / max_files_per_unit <N> / max_runtime_per_tick <T> / checkin_every_n_ticks <N>
- stop: <queue empty 3 ticks | budget hit | circuit breaker | mission complete>
- report: tick-report + ledger + docs/changelog + Board
- mode: <report-only | write>
- owns: <branches / ledger / worktree / file globs this loop exclusively writes>

## Config
- mission: verify
- scope: <the delivery under verification - paths / services / criteria source>
- tick budget: one criterion per tick
- autonomy: consent required for push/merge/deploy/ticket transitions/data writes
- started: <YYYY-MM-DD>

## Cursor
- current criterion: <#> / last proven: <#>

## Queue
<!-- criterion | proof type | status: unverified / in-progress / proven / blocked(reason) / awaiting-approval(what) -->
- [ ] <criterion> - <proof type> - unverified

## Ticks
<!-- append-only: #N <date> <criterion> -> <result> (evidence: .superloop/verify/evidence/...) -->

## Counters
- consecutive failures (mission-wide): 0
- consecutive failures (current unit): 0
- consecutive empty ticks: 0
- ticks used (cumulative, vs budget.max_ticks): 0
- files changed (cumulative): 0
- ticks since last check-in (vs budget.checkin_every_n_ticks): 0
