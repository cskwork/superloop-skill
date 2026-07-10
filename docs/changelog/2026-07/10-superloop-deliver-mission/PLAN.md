# PLAN - scheduled fresh-context delivery

Frozen plan. A fresh-context implementer reads only this file and builds it.

## Approval

- Status: auto-approved
- Record: 2026-07-10T13:25:46Z; autonomous scheduled/background run pre-authorized by the user's request to continue for one or two days with fresh context per spec

## Intent

- Goal: add a backward-compatible `deliver` mission that lets the built-in scheduler advance one vertical project spec per fresh tick by delegating that spec to installed `supergoal`.
- Constraints: preserve `verify`; durable disk state is the only cross-tick memory; exactly one active ticket; no duplicate dispatch; outer superloop does not reimplement supergoal's role-loop; shared-branch merge, push, deploy, destructive operations, and data writes remain gated.
- Tradeoffs: add a second mission and separate delivery ledger instead of overloading criterion-shaped verify state. Use the host scheduler rather than inventing a process runner. Describe an atomic lease in the contract rather than add a new runtime daemon.
- Rejected: generalizing `verify` to mean both criteria and features (mixed state model); building a custom shell dispatcher now (unnecessary process/auth complexity); hot-patching the skill during an active product ticket (contract drift).
- Completion promise: the reusable skill can initialize a project frontier, resume or claim one ticket per scheduled fresh-context tick, invoke the complete installed supergoal workflow, close only on exact artifacts, update durable state, and stop safely. Proof is all contract tests, diff checks, and an independent context-free forward test. Stop when every GOAL criterion is proven, or after 4 Build/Verify iterations with forced reflection.

## Steps

1. Add `tests/deliver-contract.test.sh` and extend `tests/loop-runtime-contract.test.sh` with failing assertions for INIT/TICK separation, fresh-context disk-only state, one active vertical ticket, atomic lease, installed-supergoal handoff, exact completion artifacts, frontier update, and schedule/deadline stops.
2. Update `SKILL.md` to route `/superloop verify` unchanged and `/superloop deliver <project-brief>` to a feature-sized outer tick. Keep the common ORIENT/PICK/EXECUTE/VERIFY/RECORD/PACE spine, but make unit semantics mission-specific.
3. Add `reference/mission-deliver.md`, `reference/supergoal-handoff.md`, and `templates/delivery-ledger.md`. Define bootstrap once, active-ticket resume, atomic `mkdir` lease, one-ticket claim, installed-supergoal full contract, exact close evidence, frontier recomputation, maintenance-ticket boundaries, and safe stops.
4. Extend `reference/state-ledger.md`, `reference/loop-contract.md`, `templates/contract.md`, and `reference/loop-runtime.md` with delivery state, root-contract preauthorization, source/target refs, integration proof, deadline/duration, scheduler job id, fresh re-entry, and no-chat-memory rules.
5. Update `README.md`, `README.ko.md`, and `docs/changelog/changelog-2026-07-10.md` so operators can launch, understand, and audit the new mission and its alternatives.
6. Run all shell contract tests and `git diff --check`. Dispatch fresh-context full-spec improvement, edge-case improvement, adversarial review, and final verification. Run a clean forward test whose prompt supplies only the revised skill path and a synthetic multi-feature project objective.

## Tools & Skills

- Skills: `supergoal`, `skill-creator`, `codebase-memory`.
- Structural discovery: codebase-memory project `Users-danny-Documents-PARA-Resource-superloop-skill`; re-index after edits.
- Tests: `bash tests/deliver-contract.test.sh`; `for t in tests/*.test.sh; do bash "$t"; done`; `git diff --check`.
- No browser or DB proof is needed for this skill-contract slice.

## Verification strategy

- Before proof: the baseline suite is green, while `reference/mission-deliver.md`, `reference/supergoal-handoff.md`, `templates/delivery-ledger.md`, and deliver routing are absent.
- Step 1 -> criteria 1-5; Steps 2-4 -> criteria 1-5; Step 5 -> criterion 8; Step 6 -> criteria 6-7.
- Trusted commands: `for t in tests/*.test.sh; do bash "$t"; done` (frozen_repo); `git diff --check` (evaluator_owned).

## Priority Rules

Domain(s): scheduled agent orchestration + reusable skill contracts

1. Persist every cross-tick decision before pacing; chat context is never durable state.
2. Claim exactly one feature-sized unit and resume it before selecting a sibling.
3. Use a single atomic writer lease; overlap must fail closed, not dispatch twice.
4. Delegate ticket execution to supergoal without copying its internal delivery method.
5. Treat exact proof artifacts as completion authority, never an agent summary.
6. Keep outward, destructive, shared-branch, deploy, and data-write actions gated.
7. Preserve existing verify semantics and installed-skill compatibility.
8. Freeze an active ticket's contract; route skill changes through separate maintenance tickets.

## Domain Brief

- Knowledge path: ephemeral in this vault; no repo-local `.domain-agent/` store created for this focused skill-contract change.
- Stable terms: tick = one scheduler invocation; vertical ticket = demoable feature slice; active ticket = the only claimed unfinished spec; lease = atomic single-writer claim; inner loop = supergoal's full ticket workflow.
- Invariants: existing verify mission remains criterion-based; built-in `/loop` owns cadence; superloop owns durable frontier and handoff; supergoal owns code worktree and exact ticket verification.
- Current-code verification: `SKILL.md`, `reference/loop-runtime.md`, `reference/state-ledger.md`, `reference/loop-contract.md`, `reference/mission-verify.md`, and contract tests were read from `main` at `34eacc6`.
- Entry points: `/superloop verify`; new `/superloop deliver <project-brief>`.
- Test commands: shell contract suite and `git diff --check`.
- Gaps: host scheduler fresh-session guarantees vary; the contract therefore requires disk-only reconstruction and fresh supergoal role contexts even when the outer host reuses a session.

## Grounding ledger

- What is superloop today? -> A single post-delivery `verify` mission with one acceptance criterion per tick -> preserve it.
- What must continue for days? -> The project frontier, not one conversation -> persist root goal/map/tickets/active run in a delivery ledger.
- What is the outer unit? -> One unblocked vertical ticket, clarified by the user as one fresh context per spec -> exactly one active ticket per tick.
- Who implements a ticket? -> Installed supergoal already owns Frame through Exact Verify -> pass a self-contained handoff; do not duplicate it.
- What prevents cron overlap? -> Stable active-ticket key alone is insufficient -> require an atomic project-scoped lease and fail closed when held.
- Where do Figma/PostgreSQL constraints live? -> They vary per target project -> root project brief and selected tickets, passed through unchanged.

