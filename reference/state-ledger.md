# State ledger - durable loop memory

One ledger per mission at `.superloop/<mission>/ledger.md` in the project root (the repo the loop
works on, not the skill repo). Evidence files live next to it:
`.superloop/<mission>/evidence/<tick>-<slug>.txt`. Bootstrap verify from `templates/ledger.md` and
deliver from `templates/delivery-ledger.md`.

## Why a ledger

A loop outlives its context window. Compaction, restarts, scheduler session reuse, and long gaps
between ticks all destroy or contaminate in-context memory. Disk is the **only cross-tick memory**;
the next tick reconstructs from the contract, ledger, referenced specs, repository, and evidence.
Rule: **if RECORD didn't write it, it didn't happen.** Never fill a durable gap from chat history.

## Schema (sections of ledger.md)

| Section | Holds |
|---|---|
| `## Contract` | the one-page loop contract, copied from `templates/contract.md` on the first tick (`reference/loop-contract.md`): intent, trigger, scope, permissions, budget, stop, report, mode, owns. Read every ORIENT |
| `## Config` | mission, scope (paths/services/JQL), tick budget, autonomy notes, started date |
| `## Cursor` | progress marker: the current criterion and the last `proven` criterion in the Intent Spec queue |
| `## Queue` | acceptance criteria (from the Intent Spec) with status: `unverified` / `in-progress` / `proven` / `blocked(reason)` / `awaiting-approval(what)` |
| `## Ticks` | append-only log: `#N <date> <unit> -> <result> (evidence: path)` ; one line per tick, including empty ticks |
| `## Counters` | consecutive failures (per-unit and mission-wide), consecutive empty ticks, fix directives issued per criterion (vs the `orchestrator_cannot_close_gap` limit), and **cumulative budget consumption**: ticks used (vs `budget.max_ticks`), files changed, ticks since last check-in |

Deliver uses a separate state model rather than overloading criterion statuses:

| Section | Holds |
|---|---|
| `## Contract` | root brief/goal digests, verified refs, integration proof, immutable `deadline_at`, scheduler/re-entry identity, explicit local preauthorization, and gates |
| `## Project` | initialization status and the durable Frontier Map revision |
| `## Frontier` | vertical ticket ids, frozen spec paths/digests, dependencies, and `unclaimed` / `active` / `integrated` / `blocked` / `maintenance` status |
| `## Active ticket` | exactly one claimed ticket or `none`, plus its supergoal run, branch, worktree, and approval state |
| `## Ticket runs` | append-only exact supergoal artifact and integration evidence per attempt |
| `## Ticks` / `## Counters` | outer scheduling history, failures, integrated count, budget, and check-in cadence |

## Rules

- **Append, don't rewrite.** `## Ticks` is append-only; statuses flip in place in `## Queue`.
- **Idempotency by key.** Every criterion has a stable key (its Intent Spec clause or index). PICK
  skips keys already `proven` - a re-fired tick after a crash must not redo finished work.
- **Delivery idempotency by ticket.** Claim a stable ticket id in `## Active ticket` before dispatch,
  freeze its spec digest and preallocated supergoal run identity, then publish the complete ledger
  with a same-directory temporary file plus atomic rename. Re-read that committed claim before
  dispatch and resume it before selecting a sibling. Never infer completion from a supergoal
  summary; exact run and integration artifacts decide it.
- **Delivery recovery by phase.** Persist `claimed`, `running`, `inner-verified`,
  `integration-pending`, and `integration-observed` with one stable close key. A replay inspects the
  bound run and target receipt before repeating work, then atomically replays only the missing state
  transition.
- **Single delivery writer.** The deliver mission acquires the atomic project lease before reading
  state for mutation and releases it before PACE. A held or uncertain lease fails closed.
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
  the trail committed. The frozen brief, map, tickets, ledgers, and evidence remain durable even
  when ignored by git; back them up if the root contract requires recovery across machines.
