---
name: superloop
description: Use when running recurring /loop project missions under a per-tick contract - documentation sweeps, bug/code-smell loops, recent-commit QA, or end-to-end Jira resolution. Use supergoal for one-off tasks.
---

# /superloop - mission discipline on top of /loop

/loop gives you a heartbeat; superloop gives each beat a contract. Every tick does **one unit of
work**, verifies it against ground truth, records it durably, and paces the next tick. The loop
survives compaction because state lives on disk, not in context.

**Invocation.**
- `/loop 30m /superloop qa` - fixed interval, mission per tick (see `reference/loop-runtime.md`)
- `/loop /superloop jira` - dynamic mode; the model self-paces and uses Monitor for event-gated waits
- `/superloop docs` - single tick now (also how every cron/wakeup fire re-enters)
- Put `/superloop <mission>` lines in `.claude/loop.md` to run missions via the bare `/loop` default

## Missions

| Arg | Mission | Reference |
|---|---|---|
| `docs` | Auto-document: keep changelog/wiki/READMEs in step with recent commits | `reference/mission-docs.md` |
| `smells` | Hunt one bug or code smell in recently-touched code and fix it surgically | `reference/mission-smells.md` |
| `qa` | QA commits since the last verified SHA; check blast radius and side effects | `reference/mission-qa.md` |
| `jira` | Resolve one Jira ticket end-to-end: branch -> fix -> test -> build -> DB/API -> local verify -> deploy gate -> post-deploy QA | `reference/mission-jira.md` |
| anything else | Custom: treat the text as the unit-queue definition; apply the same tick anatomy | this file |

## Core principles

- **One unit of work per tick.** The smallest independently verifiable unit (one doc page, one
  smell, one commit reviewed, one ticket stage). Never batch units to "use the tick well" - a
  half-verified batch is worth less than one verified unit.
- **Ledger before memory.** Durable state lives in `.superloop/<mission>/ledger.md`
  (`reference/state-ledger.md`, `templates/ledger.md`). Context compaction must never lose the
  cursor, the queue, or what was already done. Re-derive nothing you already recorded.
- **EXECUTE is supergoal.** Execution discipline is delegated to the supergoal skill (smallest
  correct change, failing test first, verify vs real tests/spec) - superloop adds the loop contract,
  not a parallel methodology. For full-pipeline work reuse existing skills (`jira-resolve`,
  `qa-engineer`, `sql-check`, `service-build`) instead of reinventing them.
- **Ground truth per tick.** A tick without verification evidence (test run, build output, HTTP
  response, read-only DB query) records `unverified`, never `done`.

## Tick anatomy (every tick, every mission)

1. **ORIENT.** Read the ledger. First tick: bootstrap it from `templates/ledger.md` and build the
   initial queue per the mission reference. Reconcile ledger vs reality (current branch, git log,
   running servers) - reality wins; note drift in the ledger.
2. **PICK.** Take the single highest-priority unit not `done`/`blocked`/`awaiting-approval`. If the
   queue is empty, refresh it from the mission's source (new commits, new tickets); still empty ->
   record an empty tick and back off (see Safety rails). **Never invent work** to look busy -
   padding ticks with speculative refactors is a contract violation.
3. **EXECUTE.** Follow the mission reference for this unit, with supergoal discipline. Stay
   surgical: touch only what the unit requires.
4. **VERIFY.** Re-run the relevant ground truth and capture command output as evidence. Failed
   verification -> the unit stays open; record the failure and what was learned.
5. **RECORD.** Append a tick entry to the ledger (unit, result, evidence pointer, next action) and
   advance the cursor. If code changed, also write the reasoning to
   `docs/changelog/changelog-YYYY-MM-DD.md`. Report the tick to the user in one short block
   (`templates/tick-report.md`).
6. **PACE.** Schedule the next tick per `reference/loop-runtime.md`: fixed-interval loops need
   nothing (cron refires); dynamic loops MUST end the turn with ScheduleWakeup carrying the original
   `/loop ...` prompt; event-gated waits (CI, Jenkins deploy, PR review) arm a Monitor instead of
   polling.

## Safety rails (autonomy contract)

- **Consent gates.** Destructive or outward-facing steps - push/merge to shared branches
  (`aidt-dev`, `aidt-stg`, `aidt-prd`), deploys, Jira transitions/comments, any data write, force
  ops - require **explicit consent** from the user. The loop runs unattended, so a gate means: mark
  the unit `awaiting-approval` in the ledger, say exactly what approval is needed, and move on to
  the next unit. A gate is never skipped because the loop is autonomous.
- **Circuit breaker.** 3 **consecutive failed ticks** on the same unit -> mark it `blocked` with the
  failure trail and move on. 3 consecutive failed ticks across different units -> stop the loop
  (omit the wakeup / tell the user to `CronDelete`) and report; something systemic is wrong and
  iteration is making the context worse, not better.
- **Empty-queue backoff.** Nothing to do -> lengthen the delay (dynamic: 1200-1800s; fixed: suggest
  a longer interval). After 3 consecutive empty ticks, propose stopping the loop.
- **Tick budget.** A unit must complete inside one tick. If it can't, split it into sub-units in the
  ledger and complete the first - never leave a tick half-done with no record.

## Reference map (load only what the tick needs)

| Read this | When |
|---|---|
| `reference/loop-runtime.md` | Launching a loop, PACE step, Monitor wiring, stopping |
| `reference/loop-runner-pitfalls.md` | Building your own dispatcher (not `/loop`) - shell bugs that silently drop work |
| `reference/state-ledger.md` + `templates/ledger.md` | ORIENT/RECORD - ledger schema and reconciliation |
| `reference/mission-docs.md` | `docs` mission tick |
| `reference/mission-smells.md` | `smells` mission tick |
| `reference/mission-qa.md` | `qa` mission tick |
| `reference/mission-jira.md` | `jira` mission tick |
| `templates/tick-report.md` | RECORD - user-facing tick summary |

## Per-tick checklist (before ending the tick)

- [ ] Ledger read at ORIENT and written at RECORD (cursor advanced or empty tick logged)
- [ ] Exactly one unit of work attempted; no batching, no invented work
- [ ] Verification evidence captured (command output) or the unit recorded as not-done
- [ ] Consent gates respected - `awaiting-approval` recorded, nothing outward without explicit consent
- [ ] Failure counters updated; circuit breaker applied if tripped
- [ ] Next tick paced: cron refire / ScheduleWakeup as the last action / Monitor armed once
