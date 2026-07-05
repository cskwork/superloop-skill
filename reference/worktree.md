# Worktree isolation - landed fixes get their own checkout

The verify loop's fix dispatch (from the first fix directive on) **never mutates the working branch
directly**. It works in a dedicated git worktree and merges back only after a green VERIFY and
explicit consent. Verify-only ticks, with no fix landed, need no worktree.

## Why

An unattended loop that edits the working branch directly, across many ticks with compaction in
between, is the riskiest shape of automation: it can leave the user's checkout half-changed, collide
with work the user is doing in the same tree, or lose track of what is staged after a restart. A
linked worktree gives the loop a checkout it owns and may mutate freely; the working branch stays
clean until the loop has something verified and consented to merge. This is also the loop's clear
**write space** - the `owns` field of the contract - so two loops never fight over one tree.

## Layout

One worktree per write mission, a linked worktree of the **target repo** (for aidt, the affected
**service** repo, not the monorepo root):

```
.superloop/<mission>/worktree/        # git worktree add <here> <branch>, off the mission's base
```

`.superloop/` is already loop-local working state (gitignored unless the user wants the trail). The
worktree root resolves to its own path, so `sl-emit` reports it distinctly on the Board.

## Lifecycle

1. **Create** when the first fix directive lands. `git worktree
   add .superloop/verify/worktree <branch>` from the verified base.
2. **Work** every tick inside that worktree - edits, tests, build, local verify all run there.
3. **Reconcile at ORIENT.** Confirm the worktree exists and sits on the expected branch; if git
   disagrees (user removed it, branch moved), reality wins - repair or recreate before picking.
4. **Merge** into the working or shared branch only after VERIFY is green **and** consent is given.
   Merging to a shared branch (`aidt-dev`, etc.) is already a consent gate (SKILL.md); the worktree
   does not change that - it just keeps the working branch clean until that gate passes.
5. **Remove** the worktree (`git worktree remove`) once the criterion's fix is merged and `proven`, so a
   stale checkout never lingers between loops.

## Failure / ownership notes

- A worktree that can't be created (dirty path, git too old) -> mark the unit `blocked(worktree)` and
  escalate; do not silently fall back to editing the working branch.
- One loop owns each worktree. A second loop on the same repo must use a distinct worktree
  path (or wait) - shared write is the thing isolation exists to prevent.
