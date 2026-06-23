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
- mission: <docs|smells|qa|jira|custom>
- scope: <paths / services / JQL filter>
- tick budget: one unit per tick
- autonomy: consent required for push/merge/deploy/Jira transitions/data writes
- started: <YYYY-MM-DD>

## Cursor
- <last verified SHA | current ticket + stage | last sweep SHA>: <value>

## Queue
<!-- key | summary | status: open / in-progress / done / blocked(reason) / awaiting-approval(what) / unverified -->
- [ ] <key> - <summary> - open

## Ticks
<!-- append-only: #N <date> <unit-key> -> <result> (evidence: .superloop/<mission>/evidence/...) -->

## Counters
- consecutive failures (mission-wide): 0
- consecutive failures (current unit): 0
- consecutive empty ticks: 0
- ticks used (cumulative, vs budget.max_ticks): 0
- files changed (cumulative): 0
- ticks since last check-in (vs budget.checkin_every_n_ticks): 0
