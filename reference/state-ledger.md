# State ledger - durable loop memory

One ledger per mission at `.superloop/<mission>/ledger.md` in the project root (the repo the loop
works on, not the skill repo). Evidence files live next to it:
`.superloop/<mission>/evidence/<tick>-<slug>.txt`. Bootstrap from `templates/ledger.md`.

## Why a ledger

A loop outlives its context window. Compaction, restarts, and long gaps between ticks all destroy
in-context memory; the ledger is the only thing the next tick can trust. Rule: **if RECORD didn't
write it, it didn't happen.**

## Schema (sections of ledger.md)

| Section | Holds |
|---|---|
| `## Contract` | the one-page loop contract, copied from `templates/contract.md` on the first tick (`reference/loop-contract.md`): intent, trigger, scope, permissions, budget, stop, report, mode, owns. Read every ORIENT |
| `## Config` | mission, scope (paths/services/JQL), tick budget, autonomy notes, started date |
| `## Cursor` | progress marker: the current criterion and the last `proven` criterion in the Intent Spec queue |
| `## Queue` | acceptance criteria (from the Intent Spec) with status: `unverified` / `in-progress` / `proven` / `blocked(reason)` / `awaiting-approval(what)` |
| `## Ticks` | append-only log: `#N <date> <unit> -> <result> (evidence: path)` ; one line per tick, including empty ticks |
| `## Counters` | consecutive failures (per-unit and mission-wide), consecutive empty ticks, fix directives issued per criterion (vs the `orchestrator_cannot_close_gap` limit), and **cumulative budget consumption**: ticks used (vs `budget.max_ticks`), files changed, ticks since last check-in |

## Rules

- **Append, don't rewrite.** `## Ticks` is append-only; statuses flip in place in `## Queue`.
- **Idempotency by key.** Every criterion has a stable key (its Intent Spec clause or index). PICK
  skips keys already `proven` - a re-fired tick after a crash must not redo finished work.
- **Reconcile at ORIENT.** Ledger says branch `fix/A20-999` but git says `aidt-prd`? Reality wins;
  log the drift as part of the tick and repair the queue before picking.
- **Evidence is a pointer, not a paste.** Store command output in `evidence/` files; the ledger
  line references the path. Keeps the ledger readable and the context cheap.
- **Counters drive the circuit breaker** (SKILL.md Safety rails). Reset the per-unit counter on any
  success; reset mission-wide counters on any successful tick.
- **Counters also drive the budget ceiling.** Bump `ticks used` and `ticks since last check-in` every
  tick, and `files changed` by the diff size. When any `## Contract` budget ceiling is reached, stop
  the loop (or pause for check-in) per SKILL.md - never silently widen the budget to keep going.
- The `.superloop/` directory is local working state - add it to `.gitignore` unless the user wants
  the trail committed.
