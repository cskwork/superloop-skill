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
| `## Config` | mission, scope (paths/services/JQL), tick budget, autonomy notes, started date |
| `## Cursor` | mission-specific progress marker: last verified SHA (`qa`), last doc sweep SHA (`docs`), current ticket + stage (`jira`), last scanned rev (`smells`) |
| `## Queue` | units with status: `open` / `in-progress` / `done` / `blocked(reason)` / `awaiting-approval(what)` / `unverified` |
| `## Ticks` | append-only log: `#N <date> <unit> -> <result> (evidence: path)` ; one line per tick, including empty ticks |
| `## Counters` | consecutive failures (per-unit and mission-wide), consecutive empty ticks |

## Rules

- **Append, don't rewrite.** `## Ticks` is append-only; statuses flip in place in `## Queue`.
- **Idempotency by key.** Every unit has a stable key (SHA, ticket ID, file path, smell ID). PICK
  skips keys already `done` - a re-fired tick after a crash must not redo finished work.
- **Reconcile at ORIENT.** Ledger says branch `fix/A20-999` but git says `aidt-prd`? Reality wins;
  log the drift as part of the tick and repair the queue before picking.
- **Evidence is a pointer, not a paste.** Store command output in `evidence/` files; the ledger
  line references the path. Keeps the ledger readable and the context cheap.
- **Counters drive the circuit breaker** (SKILL.md Safety rails). Reset the per-unit counter on any
  success; reset mission-wide counters on any successful tick.
- The `.superloop/` directory is local working state - add it to `.gitignore` unless the user wants
  the trail committed.
