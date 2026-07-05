# Verify Loop Overhaul — superloop as an orchestrator-supervising acceptance loop

**Status:** Proposed (Phase 0 — plan committed; implementation pending review)
**Date:** 2026-07-05
**Applies to:** the whole skill (full rewrite to a single `verify` mission)

## Context (why)

superloop today is a **generic recurring-mission runner** (docs / smells / qa / jira) with strong
contract discipline. Each tick does one unit of fresh work — it is a *worker* loop.

The requested reorientation: superloop should be the **quality gate that supervises an orchestrator**.
After supergoal or oh-my-symphony declares a feature / bug-fix / greenfield task "done", superloop's
`/loop` holds that delivery to its **original intent** — full QA of every feature, tests pass, correct
architecture — and when it finds a gap it **commands the orchestrator to fix it**, then re-verifies
with fresh eyes, looping until every requirement has a proof (or a budget / stop / escalation ends it).
It is a *prompter to improve quality*: it verifies and directs; the orchestrator executes.

This is the union of four proven ideas, three of which superloop or its sibling already embody:

- **Codex routines** (Boris Cherny): a loop = trigger + scope + action budget + stop + report; "Codex
  wins when it becomes the loop manager for engineering work." superloop's contract already mirrors this.
- **Ralph completion-promise**: never emit the "done" promise unless it is unequivocally true; the loop
  continues until genuine completion. superloop adopts this as its convergence rule.
- **supergoal adversarial critic**: fail the *spec*, not the existing tests; degenerate-input sweep.
- **The user's own "3 loops, fresh context, review→verify→improve"** pattern.

## Decisions locked

1. **Flagship = single mission `verify`.** Invoked `/loop /superloop verify`.
2. **Full rewrite.** `verify` becomes the *only* mission; docs / smells / qa / jira are removed as
   missions and their reusable protocols are *absorbed* into the verify loop.
3. **Direct + delegate.** superloop owns verify / direct / converge. The fix is executed by the
   orchestrator — supergoal DEBUG loaded in-tick, or a symphony ticket. `report-only` proposes the fix
   directive and gates the actual write. The next iteration re-verifies with fresh context.

Naming note (handled, not a blocker): the mission `verify`, the tick step `VERIFY`, and the built-in
`/verify` skill share a word. In context `/superloop verify` is unambiguous; the verify mission simply
spends most of each tick in the `VERIFY` step. Called out once in SKILL.md.

## New identity

Before: "a contract on every `/loop` tick" (generic mission runner).
After: "**hold an orchestrator's delivery to its intent until every requirement has a proof**."

`/loop` is the heartbeat; superloop is the acceptance loop that supervises the build.

## The verify loop (design)

### Ground truth: intent → acceptance criteria

The loop's unit-queue is **not** commits or files — it is the set of **acceptance criteria** derived
from the delivered intent. The first tick builds an **Intent Spec** from: the original request/ticket,
the orchestrator's own claims (what it says it built), and surfaced/implicit requirements (negative
constraints, must-preserve invariants, non-goals). Each explicit clause becomes one criterion with a
required proof type (test / build / HTTP body / DB read / architecture check). This is the
Intent-Contract → Requirement-to-Proof gate, made the loop's queue.

### Tick anatomy (adapted, same 6-step spine)

1. **ORIENT** — read ledger + contract; the first tick bootstraps both, builds the Intent Spec +
   criteria queue, starts the Board; reconcile against reality (git / running services win).
2. **PICK** — one criterion not yet `proven` / `blocked` / `awaiting-approval`. Empty queue → refresh
   from intent (did the orchestrator add scope?), else the loop has **converged** → success stop.
3. **EXECUTE** — one of two shapes for the picked criterion:
   - *verify shape* (default): adversarially test the criterion against the **spec**, not the existing
     tests — the qa three passes (intent / blast-radius / evidence) + degenerate-input sweep.
   - *direct shape* (criterion already failed): emit a **fix directive** to the orchestrator (see
     handoff). In `report-only` this is proposed and gated; in `write` it is dispatched.
4. **VERIFY** — capture ground-truth evidence (command output, response body, DB read). A criterion is
   `proven` only with fresh evidence this tick; `green_signal_wrong_outcome` (200 but wrong body) is a
   fail, not a pass.
5. **RECORD** — append a tick entry (criterion, verdict, evidence pointer, next action), advance the
   criteria cursor + budget counters; on a landed fix also write `docs/changelog/`; tick-report to the
   user; Board heartbeat (best-effort, never gates).
6. **PACE** — cron refire (fixed) / ScheduleWakeup with the verbatim `/loop` prompt (dynamic) / Monitor
   for event-gated waits (CI, deploy, PR review).

### Convergence (completion promise)

The stop set gains two semantic conditions:

- `all_criteria_proven` — every criterion has fresh proof → **success stop**, final acceptance report.
- `orchestrator_cannot_close_gap` — the same criterion fails after N fix directives (default 2) →
  escalate `awaiting-approval` with the evidence trail; the approach is wrong, not the test.

Ralph rule, stated explicitly: **never fabricate the completion promise to escape the loop.** A
criterion without fresh evidence is `unverified`, never `proven`.

## Orchestrator handoff protocol (new reference)

A **fix directive** is a structured, evidence-backed command — not "please fix":
`{ criterion, failing evidence (command + output), the exact spec clause, scope bound (max files),
acceptance test that must go green }`. Dispatch paths:

- **supergoal DEBUG in-tick** — load supergoal, hand it the directive as a DEBUG objective; execution
  discipline (failing test first, smallest change, verify vs real tests) is supergoal's, not
  superloop's. The fix lands in a dedicated **worktree** (reuse `reference/worktree.md`), never the
  working branch.
- **symphony ticket** — when an orchestrator swarm is live, file/append a ticket with the directive as
  acceptance criteria; superloop re-verifies when the ticket returns.
- **report-only** — write the directive to the ledger, mark the criterion `awaiting-approval`, propose;
  no write until the user consents.

Re-verification always happens in a **fresh loop iteration** (fresh context; the ledger is the memory).

## Prompting insights (mined from the user's past sessions)

A new `reference/prompting-insights.md`, derived from ~172 of the user's own prompts across the
supergoal / superloop / symphony ecosystem. It encodes how the user prompts and what "good" means, so
the verify loop behaves the user's way and future edits stay aligned:

1. **Evidence over vibes.** Every verdict cites command output / real numbers; "with actual numbers".
2. **Ground truth is the spec, not the tests.** Enumerate behaviors the tests don't exercise;
   degenerate-input sweep per parameter (null / undefined / empty / boundary).
3. **Intent integrity.** Preserve every explicit clause, negative constraint, assumption, and
   must-preserve invariant from prompt to proof; more tests never fix a misunderstood objective.
4. **Domain-generic.** The loop must add value in *any* domain; never inject domain-specific hints as
   the fix ("이 스킬은 어떤 도메인에서든 유의미하게 성과를 내야해").
5. **Succinct + DRY.** Agent-readable; prose lives only in the human-facing report (mattpocock
   writing-great-skills).
6. **QA toolkit.** playwright-cli as the default for web QA; real DB reads (seeded/synthetic when prod
   is not reproducible); assert the response **body**, not the status; cap QA actions (~100 default) so
   context doesn't drown; reports human-friendly, repeatable, indexed.
7. **Fresh context per pass.** Looped review/verify/improve beats single-pass; the ledger carries memory.
8. **Commit gate.** Block done/commit when QA fails, requirements are unmet, or uncertainty exists — ask
   the user rather than guess.
9. **Real loop failure modes to guard** (the user's own incidents): empty-response-loop
   (consecutiveEmptyTurns=3), stall→kill→re-dispatch (agent produced real output but tripped stall
   detection), worktree lock conflicts (don't lock shared branches; use distinct worktrees),
   budget-exceeded auto-block.
10. **The loop drives another agent.** superloop is the loop manager; it verifies and directs, the
    orchestrator executes.

## File-by-file change plan

**Rewrite**

- `SKILL.md` — single-mission `verify` identity; the frontmatter description leads with the acceptance
  use case, keeps the `Use when` prefix + trigger keywords (verify what supergoal/symphony built, QA the
  delivery, acceptance loop, drive fixes until tests pass and architecture is correct); core principles,
  tick anatomy, convergence, safety rails, lineage note, prompting-insights pointer, per-tick checklist.
- `README.md` + `README.ko.md` — reposition to the acceptance loop; the mission table collapses to `verify`.
- `docs/index.html` landing — headline + mode grid to the verify loop (mirror README).
- `tests/skill-contract.test.sh` — re-pin to the new invariants (see below).

**Create**

- `reference/mission-verify.md` — the single mission tick (intent→criteria, three passes, dispatch,
  convergence), absorbing qa's passes + smells' worktree fix + jira's deploy consent gate.
- `reference/orchestrator-handoff.md` — the fix-directive protocol + fresh-context re-verify.
- `reference/prompting-insights.md` — the mined-insights section above.
- `templates/intent-spec.md` — delivered-intent + acceptance-criteria capture (one page).

**Edit (keep, extend)**

- `reference/loop-contract.md` — add verify's stop conditions (`all_criteria_proven`,
  `orchestrator_cannot_close_gap`) and an `intent`/`acceptance` note.
- `reference/loop-runtime.md` — add a one-line Codex-routine lineage note.
- `reference/state-ledger.md` + `templates/ledger.md` — add the acceptance-criteria queue shape.
- `templates/contract.md` — add an `intent` + `acceptance criteria` block.

**Delete (absorbed)**

- `reference/mission-docs.md`, `reference/mission-smells.md`, `reference/mission-qa.md`,
  `reference/mission-jira.md` — protocols fold into `mission-verify.md` + `orchestrator-handoff.md`.

**Keep unchanged**

- `reference/worktree.md`, `reference/observability.md`, `reference/loop-runner-pitfalls.md`,
  `templates/tick-report.md`, `templates/observability/*`, `tui/*`.

## Contract test rewrite

The current 100-assertion test pins the four missions and their named stops. Re-pin to the new shape:

- frontmatter `name: superloop`, `description: Use when …` (kept).
- single mission `verify`; `reference/mission-verify.md` exists and is referenced.
- tick anatomy ORIENT/PICK/EXECUTE/VERIFY/RECORD/PACE (kept).
- one-criterion-per-tick; ledger under `.superloop/`; supergoal delegation for EXECUTE fixes (kept).
- convergence stops `all_criteria_proven` + `orchestrator_cannot_close_gap`.
- orchestrator handoff reference exists; the fix directive is evidence-backed.
- prompting-insights reference exists.
- contract / budget / worktree / consent-gate / single-writer rails (kept).
- drop assertions referencing the deleted mission files; keep the rail assertions.

## Safety & scope guards (unchanged rails, restated for verify)

Consent gates outrank autonomy (push / merge / deploy / issue-writes / data-writes pause
`awaiting-approval`); hard budgets (max_ticks, checkin cadence, per-unit files); the circuit breaker (3
consecutive fails); worktree-isolated fixes with distinct `owns`; never widen the budget mid-run;
`green_signal_wrong_outcome` and the new "never fabricate the completion promise" are first-class stops.

## Verification (how to test)

- `for t in tests/*.test.sh; do bash "$t"; done` → all green after the test rewrite.
- Dry-run a tick: `/superloop verify` in a repo where supergoal just delivered a small task; confirm it
  (a) builds an Intent Spec + criteria queue in `.superloop/verify/ledger.md`, (b) verifies one
  criterion with real evidence, (c) on a seeded failure emits a fix directive (report-only) rather than
  silently fixing, (d) paces the next tick.
- Grep guard: no dangling references to the deleted `mission-{docs,smells,qa,jira}.md` across the repo.

## Rollout (two-phase)

- **Phase 0 (this doc):** write this detailed plan to `docs/plans/2026-07-05-verify-loop-overhaul.md`
  and commit + push.
- **Phase 1 (after review):** execute the file plan above; run the contract tests; update README /
  landing / changelog; then commit / push / release on the user's word.

## Open questions / risks

- `verify` vs the built-in `/verify` skill wording — handled by context; flagged once, revisit if the
  name reads unclearly.
- Full deletion of the jira pipeline removes a capability the user has used; it is intentionally moved to
  the orchestrator (superloop now verifies that delivery). Reversible from git history if wanted.
