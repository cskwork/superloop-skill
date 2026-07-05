---
name: superloop
description: Use when a /loop should hold an orchestrator's delivery to its intent - verify what supergoal or oh-my-symphony just built, QA every feature against acceptance criteria, and drive fixes back to the orchestrator until tests pass and the architecture is correct. Use supergoal to build; superloop to verify the build.
---

# /superloop - hold an orchestrator's delivery to its intent

/loop gives you a heartbeat; superloop makes each beat an acceptance loop that supervises the build.
An orchestrator (supergoal, or an oh-my-symphony multi-agent swarm) declares a feature, bug fix, or
greenfield task "done"; superloop holds that delivery to its **original intent** - full QA of every
feature, tests pass, architecture correct. A gap becomes an evidence-backed **fix directive** to the
orchestrator, re-verified with fresh context next tick, until every requirement has a proof. State
survives compaction because it lives in the ledger, not in context.

**Invocation.**
- `/loop 30m /superloop verify` - fixed interval, one criterion checked per tick (see
  `reference/loop-runtime.md`)
- `/loop /superloop verify` - dynamic mode; the model self-paces and uses Monitor for event-gated
  waits (CI, deploy, PR review)
- `/superloop verify` - single tick now (also how every cron/wakeup fire re-enters)
- Put `/superloop verify` in `.claude/loop.md` to run it via the bare `/loop` default
- Naming: the mission is `verify`; the tick step `VERIFY` is where most of the work happens -
  `/superloop verify` reads unambiguously in context.

**Recording.** The live **Board** is the default recording surface: the first tick starts it
(`bash tui/launch.sh`, opt-out, best-effort) and every tick emits a heartbeat. The ledger stays the
durable record; the Board is a live lens that never gates a tick (`reference/observability.md`).

## The verify mission

superloop runs a single mission: `verify`. The unit-queue is not commits or files but the
**acceptance criteria** derived from the delivered intent - each a clause of an **Intent Spec**
(`templates/intent-spec.md`) with a required proof type (test / build / HTTP body / DB read /
architecture check). ORIENT builds the spec (below); full protocol: `reference/mission-verify.md`;
fix dispatch: `reference/orchestrator-handoff.md`. Custom scope: text after `verify`, or a path to a
criteria file, replaces the auto-derived source. Ledger: `.superloop/verify/ledger.md`.

## Core principles

- **Contract before the first tick.** Each loop has a one-page contract - trigger, scope,
  permissions, budget, stop, report, mode, owns. The clearest contract (not the most agents) is what
  makes an unattended loop trustworthy. Write it from `templates/contract.md`, record it in the
  ledger's `## Contract`, read it every ORIENT (`reference/loop-contract.md`).
- **One criterion per tick.** The smallest independently verifiable acceptance criterion - one
  clause of the Intent Spec, checked or fixed, per tick: one unit of work per tick. Never batch
  criteria to "use the tick well" - a half-verified batch is worth less than one proven criterion.
- **Ledger before memory.** Durable state lives in `.superloop/verify/ledger.md` (generally
  `.superloop/<mission>/ledger.md`; `reference/state-ledger.md`, `templates/ledger.md`). Compaction
  must never lose the cursor, the criteria queue, or what was already proven - re-derive nothing you
  already recorded.
- **Intent is ground truth.** Verify against the original request/spec and its surfaced
  requirements, not merely the existing tests - tests can be as wrong as the code. A
  `green_signal_wrong_outcome` (200 with the wrong body, a passing suite that misses the clause) is
  a fail, not a pass.
- **Direct, don't do.** A failed criterion becomes an evidence-backed fix directive to the
  orchestrator (`reference/orchestrator-handoff.md`), not a silent patch. Execution discipline
  delegates to **supergoal** (smallest correct change, failing test first, verify vs real
  tests/spec) - superloop adds the loop contract and the directive, not a parallel methodology.
  Fixes land in a dedicated worktree (`reference/worktree.md`), never the working branch, merged
  back only after a green VERIFY plus consent.
- **Converge or escalate.** A criterion is `proven` only with fresh this-tick evidence (test run,
  build output, HTTP response, read-only DB query); anything less is `unverified`. Stop conditions
  in Convergence & stop below.

## Tick anatomy (every tick)

1. **ORIENT.** Read the ledger, contract included. First tick: bootstrap the ledger from
   `templates/ledger.md`, copy the contract from `templates/contract.md` into `## Contract`, build
   the Intent Spec and criteria queue (`templates/intent-spec.md`) from the original request, the
   orchestrator's claims, and surfaced/implicit requirements, and start the Board
   (`bash tui/launch.sh &`, best-effort). Reconcile ledger vs reality - branch, git log, running
   services, the orchestrator's worktree - reality wins; note drift in the ledger.
2. **PICK.** Take the single highest-priority criterion not `proven`/`blocked`/`awaiting-approval`.
   Empty queue -> refresh from the intent (did the orchestrator add scope?); still empty -> the loop
   has **converged** - stop cleanly and report (see Convergence & stop). Padding ticks with
   speculative checks to look busy is a contract violation; never invent work.
3. **EXECUTE.** Two shapes: *verify* the criterion adversarially against the **spec**, not the
   existing tests (degenerate-input sweep, not just the happy path); or, if it already failed, emit
   a **fix directive** to the orchestrator (`reference/orchestrator-handoff.md`) with supergoal
   discipline for any direct fix. Stay surgical - touch only what the directive requires.
4. **VERIFY.** Capture fresh ground-truth evidence this tick (command output, response body, DB
   read) - a criterion is `proven` only with this-tick evidence. Failed verification -> the
   criterion stays open; record the failure and what was learned.
5. **RECORD.** Append a tick entry to the ledger (criterion, verdict, evidence pointer, next
   action), advance the cursor, and bump the budget counters (ticks used, files changed, ticks
   since check-in). If a fix landed, also write the reasoning to
   `docs/changelog/changelog-YYYY-MM-DD.md`. Report the tick to the user in one short block
   (`templates/tick-report.md`), and emit a Board heartbeat (`sl-emit`,
   `reference/observability.md`) - best-effort, never gates.
6. **PACE.** Schedule the next tick per `reference/loop-runtime.md`: fixed-interval loops need
   nothing (cron refires); dynamic loops MUST end the turn with ScheduleWakeup carrying the
   original `/loop ...` prompt; event-gated waits (CI, Jenkins deploy, PR review) arm a Monitor
   instead of polling.

## Convergence & stop

- **`all_criteria_proven`** - every criterion has fresh proof -> success stop: final acceptance
  report, then end cleanly (omit the wakeup / `CronDelete`).
- **`orchestrator_cannot_close_gap`** - the same criterion still fails after the fix-directive
  limit (default 2) -> escalate `awaiting-approval` with the evidence trail; the approach is wrong,
  not the test.
- The loop must never fabricate the completion promise to escape it - a criterion is `proven` only
  with fresh this-tick evidence; anything less stays `unverified`.

## Safety rails (autonomy contract)

- **Consent gates.** Outward or destructive steps - push/merge to shared branches (`aidt-dev`,
  `aidt-stg`, `aidt-prd`), deploys, ticket transitions/comments, any data write, force ops -
  require **explicit consent** from the user. The loop runs unattended, so a gate means: mark the
  criterion `awaiting-approval` in the ledger, say exactly what approval is needed, and move on to
  the next criterion. A gate is never skipped because the loop is autonomous.
- **Circuit breaker.** 3 **consecutive failed ticks** on the same criterion -> mark it `blocked`
  with the failure trail and move on. 3 consecutive failed ticks across different criteria -> stop
  the loop (omit the wakeup / tell the user to `CronDelete`) and report; something systemic is
  wrong and iteration is making the context worse, not better.
- **Empty-queue backoff.** Nothing to verify or direct -> lengthen the delay (dynamic: 1200-1800s;
  fixed: suggest a longer interval). After 3 consecutive empty ticks, propose stopping the loop.
- **Tick budget.** A criterion must be verified - or its fix directed - inside one tick. If it
  can't, split it into sub-criteria in the ledger and complete the first - never leave a tick
  half-done with no record.
- **Budget ceiling.** The contract's `budget` bounds the loop's cumulative life, not just one
  criterion - `max_ticks`, `max_files_per_unit`, `max_runtime_per_tick`, `checkin_every_n_ticks`
  (`reference/loop-contract.md`). When any ceiling is hit, **stop cleanly and report** (or pause as
  `awaiting-approval(checkin)`); never widen the budget mid-run to "just finish."
- **Progressive autonomy & single-writer ownership.** New or custom verify loops start
  `mode: report-only` - propose the fix directive and gate every write; promote to `write` only
  once the signal is consistently useful. Each loop writes only what it names in the contract's
  `owns` (branch / ledger / worktree / file glob); concurrent loops stay read-only outside their
  owned scope and use distinct worktrees (`reference/loop-contract.md`).
- **Escalation triggers.** Beyond the failure counters, escalate to the user (mark
  `awaiting-approval` or stop) the moment: behavior is genuinely ambiguous; the safe action needs a
  permission the contract withholds; a fix would widen scope past `max_files_per_unit`; the spec
  and the tests contradict each other; or a green signal hides a wrong outcome (deploy healthy but
  the page is wrong). A surprising-but-not-failing state is a reason to ask, not to push on.

## Lineage

superloop's contract mirrors **Codex routines** (Boris Cherny): trigger + scope + budget + stop +
report, the loop as the manager of engineering work, not a one-shot script. Convergence is
**Ralph**'s completion-promise: never emit "done" unless it is unequivocally true. Execution
discipline - smallest correct change, failing test first, verify vs real tests/spec - is
**supergoal**'s throughout.

## Reference map (load only what the tick needs)

| Read this | When |
|---|---|
| `reference/mission-verify.md` | The verify tick - intent-to-criteria, the verify/direct shapes, convergence |
| `reference/orchestrator-handoff.md` | EXECUTE (direct shape) - the fix directive and fresh-context re-verify |
| `reference/prompting-insights.md` | How to run the loop the user's way - evidence over vibes, spec over tests |
| `reference/loop-runtime.md` | Launching a loop, PACE step, Monitor wiring, stopping |
| `reference/loop-runner-pitfalls.md` | Building your own dispatcher (not `/loop`) - shell bugs that silently drop work |
| `reference/loop-contract.md` + `templates/contract.md` | Before the first tick - the loop contract (scope, permissions, budget, stop, mode, owns) |
| `reference/state-ledger.md` + `templates/ledger.md` | ORIENT/RECORD - ledger schema and reconciliation |
| `templates/intent-spec.md` | ORIENT (first tick) - capturing the delivered intent and acceptance criteria |
| `reference/worktree.md` | EXECUTE (direct shape) - isolating a landed fix in a git worktree |
| `reference/observability.md` + `tui/` | Recording - the live Board (default surface) and `sl-emit` heartbeats |
| `templates/tick-report.md` | RECORD - user-facing tick summary |

## Per-tick checklist (before ending the tick)

- [ ] Ledger read at ORIENT and written at RECORD (cursor advanced or empty tick logged)
- [ ] Exactly one criterion attempted; no batching, no invented work
- [ ] Verification evidence captured (command output) or the criterion recorded as `unverified`
- [ ] No criterion marked proven without fresh this-tick evidence; completion promise never fabricated
- [ ] Consent gates respected - `awaiting-approval` recorded, nothing outward without explicit consent
- [ ] Failure counters updated; circuit breaker applied if tripped
- [ ] Budget counters bumped; loop stopped or paused for check-in if any contract ceiling is hit
- [ ] Next tick paced: cron refire / ScheduleWakeup as the last action / Monitor armed once
