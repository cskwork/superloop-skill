# superloop-skill

A Claude Code skill that holds an orchestrator's delivery to its original intent.

`/loop` is the heartbeat (when to wake up); superloop is the acceptance loop that runs on each beat: derive acceptance criteria from what was delivered, verify each against the spec, and direct the orchestrator to fix any gap until every criterion has a proof. Built as a loop-native extension of [supergoal-skill](https://github.com/cskwork/supergoal-skill)'s baseline-first principles. Use supergoal to build; superloop to verify the build.

**Landing page**: https://cskwork.github.io/superloop-skill/ (KO default, EN toggle) · **한국어 문서**: [README.ko.md](README.ko.md)

## Why

Unattended loops fail in predictable ways: they redo finished work after compaction, mark unverified work done, batch half-finished changes, invent work to look busy, or grind one failure until they have burned a weekend of spend. superloop prevents these with one rule set:

- **Contract before the loop** - one declarative page (trigger, scope, permissions, budget, stop, report, mode, owns) recorded in the ledger and read every tick. The clearest contract, not the most agents, is what makes an unattended loop trustworthy.
- **One acceptance criterion per tick** - the smallest independently provable clause from the Intent Spec; never batch.
- **Ledger before memory** - durable state in `.superloop/verify/ledger.md` survives context compaction; an idempotent queue means a re-fired tick never redoes finished work.
- **Intent is ground truth, not the tests** - verify against the original request and spec, not merely the existing suite; a green suite that misses a clause is a fail, not a pass.
- **Direct, don't do** - a failed criterion becomes an evidence-backed fix directive to the orchestrator, never a silent patch.
- **Hard budgets** - cumulative ceilings (max ticks, files per unit, runtime, check-in cadence) stop a runaway loop cleanly instead of letting it spend unbounded.
- **A landed fix isolates in a worktree** - fixes land in a dedicated git worktree and merge back only after a green verify plus consent; the working branch stays clean.
- **Gates outrank autonomy** - pushes, merges, deploys, and issue transitions pause as `awaiting-approval`; the ticket pauses, the loop keeps working.
- **Live Board by default** - a terminal (or web) dashboard over every loop, fed one heartbeat per tick; best-effort and never gates - the ledger stays the durable record.

## Tick anatomy

Every tick:

```
ORIENT -> PICK -> EXECUTE -> VERIFY -> RECORD -> PACE
```

| Step | Does |
|---|---|
| ORIENT | Read the ledger + contract; first tick bootstraps both, builds the Intent Spec + criteria queue, and starts the Board; reconcile against reality (git wins) |
| PICK | One open acceptance criterion; empty queue backs off, never invents work |
| EXECUTE | Verify the criterion against the spec, or - if it already failed - direct the orchestrator to fix it (supergoal discipline: smallest correct change, failing test first) |
| VERIFY | Real tests / builds / HTTP bodies / read-only DB evidence, fresh this tick; a green signal that hides the wrong outcome is a fail |
| RECORD | Append-only tick log, advance the cursor + budget counters, point to evidence, emit a Board heartbeat |
| PACE | Cache-aware delays; Monitor instead of polling for events |

## Missions

| Launch | Mission |
|---|---|
| `/loop 30m /superloop verify` | Verify the delivery on a fixed cadence: one acceptance criterion per tick |
| `/loop /superloop verify` | Same loop, self-paced + Monitor instead of a fixed interval |
| `/superloop verify` | Single tick, right now |

superloop runs one mission, `verify`: derive acceptance criteria from the delivered intent, verify each against the spec, and direct the orchestrator to fix any gap. It converges at `all_criteria_proven` (clean stop) or escalates at `orchestrator_cannot_close_gap` (same criterion still failing past the fix-directive limit) - it never fabricates the completion promise.

## Structure

```
SKILL.md                           # verify mission + tick anatomy + safety rails
reference/mission-verify.md        # the verify mission: ORIENT/PICK/EXECUTE/VERIFY, named stops
reference/orchestrator-handoff.md  # fix directive shape + dispatch paths (worktree, ticket, report-only)
reference/prompting-insights.md    # evidence bar, intent integrity, QA toolkit, loop failure modes
reference/loop-contract.md         # the one-page loop contract: scope, permissions, budget, stop, mode, owns
reference/loop-runtime.md          # distilled built-in /loop mechanics + cache-aware pacing + Monitor rules
reference/state-ledger.md          # ledger schema, idempotency, reconciliation
reference/worktree.md              # worktree isolation for a landed fix
reference/observability.md         # producer side of the live Board (sl-emit heartbeats)
templates/intent-spec.md           # frozen delivered-intent + acceptance-criteria queue, built at first tick
templates/{contract,ledger,tick-report}.md
templates/observability/{sl-emit.sh,heartbeat.schema.json}
tui/                                # superloop Board: Textual reader (state/app/serve) + launch.sh
tests/*.test.sh                     # contract tests pinning the core rules
```

## Install

```bash
git clone https://github.com/cskwork/superloop-skill
ln -sfn "$(pwd)/superloop-skill" ~/.agents/skills/superloop
ln -sfn ~/.agents/skills/superloop ~/.claude/skills/superloop
```

Pairs best with [supergoal-skill](https://github.com/cskwork/supergoal-skill) (execution discipline is delegated to it).

## Tests

```bash
for t in tests/*.test.sh; do bash "$t"; done
```

Contract tests fail if the skill ever loses the verify mission, tick anatomy, one-criterion rule, the Intent Spec / acceptance-criteria queue, the ledger, consent gates, the loop contract, the budget ceiling, worktree isolation, the orchestrator fix-directive handoff, or the Board's never-gates invariant.

## Lineage

superloop's contract mirrors **Codex routines** (Boris Cherny): trigger + scope + budget + stop + report. Convergence is **Ralph**'s completion-promise: never emit "done" unless it is unequivocally true. Execution discipline - smallest correct change, failing test first - is **supergoal**'s throughout.
