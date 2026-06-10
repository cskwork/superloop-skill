# superloop ledger - <mission>

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
