# superloop delivery ledger

<!-- Durable project state. Disk is the only cross-tick memory. Append Ticket runs and Ticks. -->

## Contract

- contract: `.superloop/deliver/contract.md`
- contract digest: <sha256>
- project_brief: `.superloop/deliver/project-brief.md`
- project brief digest: <sha256>
- root_goal: `.superloop/deliver/root-goal.md`
- root goal digest: <sha256>
- source_ref: <verified base ref>
- target_ref: <verified integration ref>
- target shared: <true | false>
- integration_proof: <exact command or artifact>
- deadline_or_duration: <absolute deadline and/or bounded duration>
- deadline_at: <immutable ISO-8601 timestamp computed once at INIT>
- scheduler_job_id: <CronCreate id | dynamic | single-tick>
- scheduler status: <present + checked_at | dynamic | single-tick | missing/unreadable>
- launch_prompt: <original `/loop ...` launch message verbatim; audit only>
- scheduled_payload: <parsed delivery prompt; the fixed cron payload>
- dynamic_reentry_prompt: <`/loop `-prefixed wakeup prompt | none>
- lease_recovery_rule: <objective owner-death proof + expiry grace + authorized actor>
- preauthorized_local_actions: <explicit local actions only>
- gates: <push, deploy, destructive/force, shared merge, ticket-system writes, every data write>

## Project

- status: initializing
- initialized at: <ISO-8601 | pending>
- wayfinder map: `.superloop/deliver/wayfinder/map.md`
- map revision/digest: <revision and sha256 | pending>
- root stop: <all_tickets_integrated | frontier_blocked | deadline_reached | budget/circuit breaker>

## Frontier

<!-- stable id | spec path | spec digest | dependencies | status: unclaimed / active / integrated / blocked / maintenance -->
- <T-001> | `.superloop/deliver/wayfinder/tickets/<T-001>.md` | <sha256> | <none> | unclaimed

## Active ticket

<!-- Exactly one ticket identity or `none`. Publish the complete claim atomically before dispatch. -->
- ticket id: <stable id | none>
- ticket spec: <path | none>
- ticket spec digest: <sha256 | none>
- claim idempotency key: <stable key | none>
- claimed_at: <ISO-8601 | none>
- source_ref / target_ref: <refs | none>
- source commit / target base commit: <resolved commits | none>
- installed supergoal path / SKILL digest: <path and sha256 | none>
- commit-gate path / digest: <path and sha256 | none>
- supergoal run id: <stable run id | none>
- supergoal run vault: <path | none>
- run branch / worktree: <branch and path | none>
- phase: <none | claimed | running | inner-verified | integration-pending | integration-observed>
- close idempotency key: <stable ticket + run key | none>
- state: <none | claimed | running | awaiting-approval(reason) | blocked(reason)>

## Ticket runs

<!-- Append-only: tick | ticket/run/revision + close key | evidence manifest + exact artifacts | installed commit gate | target commit/tree + integration proof/receipt | result -->

## Ticks

<!-- Append-only: #N <date> <INIT|ticket-id|overlap> -> <result> (evidence: path) -->

## Counters

- ticks used (vs contract budget): 0
- tickets integrated: 0
- consecutive failed ticks (mission-wide): 0
- consecutive failed ticks (active ticket): 0
- consecutive empty/blocked ticks: 0
- maintenance tickets queued: 0
- ticks since last check-in: 0
