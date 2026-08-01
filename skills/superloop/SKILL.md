---
name: superloop
description: Use /loop to verify a delivery or advance a project one ticket per tick against acceptance criteria.
---

# /superloop - verify a delivery or advance a project frontier

/loop gives you a heartbeat; superloop gives each beat a durable unit and a stop condition. Use
`verify` to hold an orchestrator's completed delivery to its **original intent**. Use `deliver` to
advance one vertical project ticket through the installed `supergoal` workflow. Both reconstruct
from disk, use the same ORIENT/PICK/EXECUTE/VERIFY/RECORD/PACE spine, and keep mission-specific unit
and completion semantics.

**Invocation.**
- `/loop 30m /superloop verify` - fixed interval, one criterion checked per tick (see
  `reference/loop-runtime.md`)
- `/loop /superloop verify` - dynamic mode; the model self-paces and uses Monitor for event-gated
  waits (CI, deploy, PR review)
- `/superloop verify` - single tick now (also how every cron/wakeup fire re-enters)
- Put `/superloop verify` in `.claude/loop.md` to run it via the bare `/loop` default
- `/loop 30m /superloop deliver <project-brief>` - initialize now, then advance one active vertical
  ticket per scheduled re-entry
- `/loop /superloop deliver <project-brief>` - the same delivery mission with dynamic pacing
- `/superloop deliver <project-brief>` - run INIT once, or one TICK when its durable project already
  exists
- Naming: in `/superloop verify`, `verify` is the mission and `VERIFY` is the tick step; in
  `/superloop deliver`, `deliver` is the mission and `VERIFY` checks exact ticket-close artifacts.

**Recording.** The live **Board** is the default recording surface: the first tick starts it
(`bash tui/launch.sh`, opt-out, best-effort) and every tick emits a heartbeat. The ledger stays the
durable record; the Board is a live lens that never gates a tick (`reference/observability.md`).

## Missions and units

`verify` keeps its original criterion contract. Its unit-queue is not commits or files but the
**acceptance criteria** derived from the delivered intent - each a clause of an **Intent Spec**
(`templates/intent-spec.md`) with a required proof type (test / build / HTTP body / DB read /
architecture check). ORIENT builds the spec (below); full protocol: `reference/mission-verify.md`;
fix dispatch: `reference/orchestrator-handoff.md`. Custom scope: text after `verify`, or a path to a
criteria file, replaces the auto-derived source. Ledger: `.superloop/verify/ledger.md`.

`deliver` advances a multi-feature project. INIT freezes the root brief and one immutable root goal,
then creates a supergoal Frontier Map plus vertical ticket specs. Each later TICK resumes or claims exactly one active ticket,
then delegates the complete ticket workflow to installed supergoal. It closes only from exact
artifacts and named integration proof. Full protocol: `reference/mission-deliver.md`; handoff:
`reference/supergoal-handoff.md`; ledger: `.superloop/deliver/ledger.md`.

## Core principles

- **Contract before the first tick.** Each loop has a one-page contract - trigger, scope,
  permissions, budget, stop, report, mode, owns. The clearest contract (not the most agents) is what
  makes an unattended loop trustworthy. Write it from `templates/contract.md`, record it in the
  ledger's `## Contract`, read it every ORIENT (`reference/loop-contract.md`).
- **One mission-specific unit per tick.** For verify: **One criterion per tick**, one clause of the
  Intent Spec checked or fixed. For deliver: one active vertical ticket resumed or claimed, with no
  sibling started after it closes. This is one unit of work per tick; never batch to make a tick look
  busy.
- **Ledger before memory.** Durable state lives in `.superloop/<mission>/ledger.md`
  (`reference/state-ledger.md`; verify uses `templates/ledger.md`, deliver uses
  `templates/delivery-ledger.md`). Compaction or scheduler session reuse must never lose the cursor,
  queue/frontier, active ticket, or proof. Chat context is not cross-tick state.
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
- **Schedule, don't duplicate.** In deliver, superloop owns the outer lease/frontier/ticket cursor;
  installed supergoal owns Frame through Exact Verify/QA. Pass a self-contained frozen handoff and
  inspect its exact artifacts; do not copy or shorten its role-loop.
- **Converge or escalate.** A verify criterion is `proven` only with fresh this-tick evidence. A
  delivery ticket is integrated only with the exact artifact set plus target integration proof.
  Anything less stays open. Stop conditions are in Convergence & stop below.

## Tick anatomy (every tick)

1. **ORIENT.** Read the mission ledger and contract from disk; acquire deliver's atomic lease before
   mutation. First verify tick builds the Intent Spec/criteria queue. Deliver INIT freezes the root
   brief, root goal, and Frontier Map but dispatches no product ticket. Reconcile ledger vs git, services, and
   run artifacts - reality wins; record drift.
2. **PICK.** Verify selects one open criterion. Deliver resumes its active ticket before claiming
   the single highest-priority unblocked frontier ticket. An empty queue/frontier triggers the
   mission's convergence or blocked stop; never invent work.
3. **EXECUTE.** Verify checks the criterion or emits an evidence-backed fix directive. Deliver sends
   the frozen ticket to installed supergoal using `reference/supergoal-handoff.md`; never substitutes
   an outer-loop implementation.
4. **VERIFY.** Verify captures fresh ground-truth evidence for the criterion. Deliver reads GOAL,
   QA, run-state, DONE marker, commit-gate result, and named integration evidence. Missing or
   inconsistent evidence keeps the unit open.
5. **RECORD.** Append the unit verdict, evidence pointer, and next action; advance the mission cursor
   and budget counters. Deliver clears the active slot and recomputes the frontier only after exact
   integration proof. If a fix or implementation landed, also write the reasoning to
   `docs/changelog/changelog-YYYY-MM-DD.md`. Report the tick to the user in one short block
   (`templates/tick-report.md`), and emit a Board heartbeat (`sl-emit`,
   `reference/observability.md`) - best-effort, never gates.
6. **PACE.** Release any deliver lease, then schedule per `reference/loop-runtime.md`: fixed-interval loops need
   nothing (cron refires); dynamic loops MUST end the turn with ScheduleWakeup carrying the
   original `/loop ...` prompt; event-gated waits (CI, Jenkins deploy, PR review) arm a Monitor
   instead of polling.

## Convergence & stop

- **`all_criteria_proven`** - every criterion has fresh proof -> success stop: final acceptance
  report, then end cleanly (omit the wakeup / `CronDelete`).
- **`orchestrator_cannot_close_gap`** - the same criterion still fails after the fix-directive
  limit (default 2) -> escalate `awaiting-approval` with the evidence trail; the approach is wrong,
  not the test.
- **`all_tickets_integrated`** - every delivery ticket has exact integration proof -> success stop.
- **`frontier_blocked`** / **`deadline_reached`** - no dependency-safe ticket can move, or the root
  time bound expired -> report durable state and stop pacing.
- The loop must never fabricate the completion promise to escape it: a criterion without fresh
  proof stays `unverified`; a ticket without exact integration evidence stays active.

## Safety rails (autonomy contract)

- **Consent gates.** Outward or destructive steps - push/merge to shared branches (`aidt-dev`,
  `aidt-stg`, `aidt-prd`), deploys, ticket transitions/comments, any data write, force ops -
  require **explicit consent** from the user. The loop runs unattended, so a gate means: mark the
  current unit `awaiting-approval` in the ledger and say exactly what approval is needed. Verify may
  move to another criterion; deliver keeps the ticket active and never claims a sibling. A gate is
  never skipped because the loop is autonomous.
- **Circuit breaker.** 3 **consecutive failed ticks** on the same unit -> mark it `blocked`
  with the failure trail. 3 consecutive failed ticks across different units -> stop
  the loop (omit the wakeup / tell the user to `CronDelete`) and report; something systemic is
  wrong and iteration is making the context worse, not better.
- **Empty-work backoff.** Nothing to verify, direct, resume, or claim -> lengthen the delay (dynamic: 1200-1800s;
  fixed: suggest a longer interval). After 3 consecutive empty ticks, propose stopping the loop.
- **Tick budget.** Verify completes or splits one criterion. Deliver advances only the active ticket;
  if its supergoal run outlives the tick, RECORD its durable run state and resume next tick rather
  than changing the frozen ticket or claiming a sibling. Never leave a half-done tick unrecorded.
- **Budget ceiling.** The contract's `budget` bounds the loop's cumulative life, not just one
  criterion - `max_ticks`, `max_files_per_unit`, `max_runtime_per_tick`, `checkin_every_n_ticks`
  (`reference/loop-contract.md`). When any ceiling is hit, **stop cleanly and report** (or pause as
  `awaiting-approval(checkin)`); never widen the budget mid-run to "just finish."
- **Progressive autonomy & single-writer ownership.** New or custom verify loops start
  `mode: report-only` - propose the fix directive and gate every write; promote to `write` only
  once the signal is consistently useful. Each loop writes only what it names in the contract's
  `owns` (branch / ledger / worktree / file glob); concurrent loops stay read-only outside their
  owned scope and use distinct worktrees (`reference/loop-contract.md`).
- **Delivery lease & frozen unit.** Deliver acquires atomic
  `mkdir .superloop/deliver/lease` before any claim or state mutation and fails closed on overlap.
  Publish the complete active-ticket/run claim by same-directory atomic rename and re-read it before
  dispatch. Resume that one active ticket before any sibling. Freeze its spec and execution contract;
  discovered skill improvements become separate maintenance tickets between product tickets.
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
| `reference/mission-deliver.md` | Deliver INIT/TICK - frontier, lease, one active ticket, exact close, stops |
| `reference/supergoal-handoff.md` | Deliver EXECUTE/VERIFY - installed supergoal packet, resume, exact artifacts |
| `reference/prompting-insights.md` | How to run the loop the user's way - evidence over vibes, spec over tests |
| `reference/loop-runtime.md` | Launching a loop, PACE step, Monitor wiring, stopping |
| `reference/loop-runner-pitfalls.md` | Building your own dispatcher (not `/loop`) - shell bugs that silently drop work |
| `reference/loop-contract.md` + `templates/contract.md` | Before the first tick - the loop contract (scope, permissions, budget, stop, mode, owns) |
| `reference/state-ledger.md` + `templates/{ledger,delivery-ledger}.md` | ORIENT/RECORD - mission ledger schemas and reconciliation |
| `templates/intent-spec.md` | ORIENT (first tick) - capturing the delivered intent and acceptance criteria |
| `reference/worktree.md` | EXECUTE (direct shape) - isolating a landed fix in a git worktree |
| `reference/observability.md` + `tui/` | Recording - the live Board (default surface) and `sl-emit` heartbeats |
| `templates/tick-report.md` | RECORD - user-facing tick summary |

## Per-tick checklist (before ending the tick)

- [ ] Ledger read at ORIENT and written at RECORD (cursor advanced or empty tick logged)
- [ ] Exactly one mission unit attempted: verify criterion or deliver active ticket; no batching
- [ ] Verification evidence captured or the criterion/ticket left open
- [ ] No criterion proven or ticket integrated without its exact evidence; completion promise never fabricated
- [ ] Consent gates respected - `awaiting-approval` recorded, nothing outward without explicit consent
- [ ] Failure counters updated; circuit breaker applied if tripped
- [ ] Budget counters bumped; loop stopped or paused for check-in if any contract ceiling is hit
- [ ] Next tick paced: cron refire / ScheduleWakeup as the last action / Monitor armed once
- [ ] Deliver only: lease released; active ticket/frontier and exact integration evidence recorded
