# Observability - the superloop Board (default recording surface)

A live, in-terminal dashboard of every loop's mission + tick stage + a Jira-like unit board, across
concurrent loops on different repos/branches/worktrees. This file is the **producer** side (state
emission); the reader UI lives in `tui/`. The loop emits; the board reads.

**Recording is two-layer.** The **ledger** (`reference/state-ledger.md`) is the durable record of
truth - it survives compaction and decides what a tick did. The **Board** is a live lens over the
loop, the default thing you watch while it runs. They are independent: the ledger never needs the
board, and the board never gates the ledger.

**Baseline-first invariant (load-bearing).** The board is **droppable**. No gate reads these files;
no mission fails when emission is absent, partial, or stale. If `textual` is not installed, or
`~/.superloop/runs` is deleted, every tick, gate, and verification still passes unchanged. The board
adds observability, never a delivery gate.

## The one load-bearing idea

Correctness comes entirely from **one writer per file + atomic rename**. Everything else (lock-free,
crash-safe, shared-branch-safe, tailable) follows, with no lock anywhere.

- One heartbeat JSON per loop, replaced atomically (`tmp.$$` -> `mv -f`). A reader's `read()` returns
  the old-complete or new-complete file, never a torn one.
- `branch` is a display field, never a mutex. Two loops on the same branch write two distinct files,
  so they never serialize and never lock.

## File layout

```
${SUPERLOOP_RUN_DIR:-$HOME/.superloop/runs}/
  .enabled                       # opt-in flag (tui/launch.sh creates it); absent => sl-emit no-ops
  agents/<agent_id>.json         # heartbeat, one per loop, replaced atomically
```

Registry lives **outside any target repo** on purpose: writing into the repo would dirty
`git status`, which the QA and worktree reconciliation treat as a baseline violation. Schema:
`templates/observability/heartbeat.schema.json`.

## Default-on, by design

superloop's default recording surface is the terminal board, so the loop turns emission on itself:

1. **First tick (ORIENT bootstrap):** best-effort `bash <skill>/tui/launch.sh &`. That creates the
   `.enabled` flag (emission on from now) and resolves a place to render:
   - inside **tmux** -> opens the board in a detached split (true auto-start), returns at once;
   - a **TTY** -> the board takes over that terminal (run it in a spare pane);
   - **no TTY** (cron / wakeup / headless tick) -> nowhere to render a TUI, so it just leaves
     emission on and the first tick report carries the one command to open it:
     `bash <skill>/tui/launch.sh` (terminal) or `... --web` (browser).
2. **Every tick:** the loop calls `sl-emit` at RECORD and PACE (below). With `.enabled` present this
   records; with no board it is a silent no-op.

Honesty about the limit: an unattended loop has no terminal of its own, so the board is something a
human opens in a spare pane to watch a running loop - the loop cannot conjure a TTY. Emission still
runs, so the moment anyone opens the board the full live state is there.

## Emitting - `templates/observability/sl-emit.sh`

```
sl-emit --phase EXECUTE [--mode verify] [--task "A20-812: null guard"] \
        [--task-status in-progress] [--note "tick #7, 1 red open"] [--slot verify] [--tasks-file board.json]
```

- **Opt-in:** emits only when `$REGDIR/.enabled` exists or `SUPERLOOP_TUI=1`. No Board => silent no-op.
- **Best-effort:** any failure (no `jq`, no disk, no perms) -> one stderr line + `exit 0`. Never aborts the tick.
- **Self-derived identity:** repo/branch/worktree come from `git` in the cwd on every call. Pass
  `--slot <id>` when several loops share one worktree+branch, to keep their files distinct.
- **Carry-forward:** without `--tasks-file`, the prior `tasks[]` board is preserved; a named `--task`
  updates that unit's `status` (or appends it). `started_at` is immutable across emits.
- **`jq` is a declared dependency** of the helper (used for the atomic merge).

## Status mapping (ledger queue -> board column)

The board columns are Backlog / In-Progress / Review / Done, plus a flagged Blocked row. Map the
ledger's queue status to a column when you emit `--task-status`:

| Ledger queue status | Board column |
|---|---|
| `open` | `backlog` |
| `in-progress` | `in-progress` |
| `awaiting-approval` / `unverified` | `review` |
| `done` | `done` |
| `blocked` | `blocked` |

## Lifecycle (the loop is its own conductor)

There is no separate orchestrator: the loop running each tick owns the loop boundary and makes the
emits. `phase` carries the universal tick stage; mission-specific detail rides in `--task`/`--note`.

| When | Emit |
|---|---|
| First tick (ORIENT) | `sl-emit --phase ORIENT --mode <mission> --task "<first unit>" --task-status backlog` |
| Tick stage moves | `sl-emit --phase PICK\|EXECUTE\|VERIFY` (carries the board forward) |
| Unit status changes | `sl-emit --task "<unit>" --task-status backlog\|in-progress\|review\|done\|blocked` |
| RECORD / PACE | `sl-emit --phase RECORD` then `--phase PACE --note "wakeup in Ns / cron / Monitor armed"` |
| Loop stops | `sl-emit --phase Done` |

## Viewing

```
bash tui/launch.sh           # terminal Textual board (default) - watch in a spare pane
bash tui/launch.sh --web     # browser board (textual-serve; multiple viewers)
python3 -m tui.state         # headless: dump current state as JSON (debug, zero deps beyond stdlib)
```

`textual` is required for the UI (`pip install textual`); `textual-serve` only for `--web`. Neither
is required for the loop to run - the board is optional throughout.
