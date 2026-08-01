<p align="center"><img src="logo.png" width="120" alt="logo" /></p>

# superloop-skill

A Claude Code skill that verifies an orchestrator's delivery or advances a large project one
vertical feature at a time.

`/loop` is the heartbeat (when to wake up); superloop supplies the durable work contract on each
beat. `verify` derives acceptance criteria from completed work and proves them against the spec.
`deliver` freezes one root goal and its project frontier, resumes or claims one vertical ticket, and delegates the full
ticket workflow to installed [supergoal-skill](https://github.com/cskwork/supergoal-skill). Use
supergoal to deliver a ticket; use superloop to schedule, resume, integrate, and stop the project.

**Landing page**: https://cskwork.github.io/superloop-skill/ (KO default, EN toggle) · **한국어 문서**: [README.ko.md](README.ko.md)

## Why

Unattended loops fail in predictable ways: they redo finished work after compaction, mark unverified work done, batch half-finished changes, invent work to look busy, or grind one failure until they have burned a weekend of spend. superloop prevents these with one rule set:

- **Contract before the loop** - one declarative page (trigger, scope, permissions, budget, stop, report, mode, owns) recorded in the ledger and read every tick. The clearest contract, not the most agents, is what makes an unattended loop trustworthy.
- **One mission unit per tick** - one acceptance criterion for `verify`; one active vertical ticket for `deliver`; never batch.
- **Ledger before memory** - durable state under `.superloop/<mission>/` survives compaction and scheduler-session reuse; a re-fired tick reconstructs from disk, never chat.
- **Intent is ground truth, not the tests** - verify against the original request and spec, not merely the existing suite; a green suite that misses a clause is a fail, not a pass.
- **Direct, don't do** - a failed criterion becomes an evidence-backed fix directive to the orchestrator, never a silent patch.
- **Hard budgets** - cumulative ceilings (max ticks, files per unit, runtime, check-in cadence) stop a runaway loop cleanly instead of letting it spend unbounded.
- **A landed fix isolates in a worktree** - fixes land in a dedicated git worktree and merge back only after a green verify plus consent; the working branch stays clean.
- **Gates outrank autonomy** - pushes, merges, deploys, and issue transitions pause as `awaiting-approval`; the ticket pauses, the loop keeps working.
- **Live Board by default** - a terminal (or web) dashboard over every loop, fed one heartbeat per tick; best-effort and never gates - the ledger stays the durable record.
- **One delivery writer** - `deliver` acquires an atomic project lease, publishes the active claim atomically before dispatch, resumes it before a sibling, and fails closed on overlap.
- **Exact close** - a delivery ticket closes only when supergoal's GOAL, QA, run-state, DONE marker, commit gate, and named integration proof agree; summaries do not count.

## Tick anatomy

Every tick:

```
ORIENT -> PICK -> EXECUTE -> VERIFY -> RECORD -> PACE
```

| Step | Does |
|---|---|
| ORIENT | Read the mission ledger + contract from disk; deliver also acquires its lease and checks the deadline |
| PICK | Verify: one open criterion. Deliver: resume the active ticket, else claim one unblocked vertical ticket |
| EXECUTE | Verify/direct a criterion, or hand the frozen ticket to installed supergoal's complete role-loop |
| VERIFY | Verify: fresh real evidence. Deliver: exact supergoal artifacts plus integration proof |
| RECORD | Append evidence and counters; deliver clears the active slot and recomputes the frontier only after exact close |
| PACE | Cache-aware delays; Monitor instead of polling for events |

## Missions

| Launch | Mission |
|---|---|
| `/loop 30m /superloop verify` | Verify the delivery on a fixed cadence: one acceptance criterion per tick |
| `/loop /superloop verify` | Same loop, self-paced + Monitor instead of a fixed interval |
| `/superloop verify` | Single tick, right now |
| `/loop 30m /superloop deliver <project-brief>` | INIT now, then one active vertical ticket per scheduled re-entry |
| `/loop /superloop deliver <project-brief>` | Same project delivery with dynamic pacing |
| `/superloop deliver <project-brief>` | INIT once, or resume one existing delivery tick now |

`verify` remains backward-compatible: one acceptance criterion per tick, converging at
`all_criteria_proven` or escalating at `orchestrator_cannot_close_gap`.

`deliver` has two phases. INIT runs once: fill the root contract, freeze the brief and immutable root
goal, and use supergoal WAYFINDER to write a dependency map plus vertical tickets. Each later TICK acquires an atomic
`mkdir` lease, reconstructs only from `.superloop/deliver/`, resumes or claims exactly one ticket,
and runs installed supergoal from Frame through Exact Verify/QA in fresh role contexts. It stops at
`all_tickets_integrated`, `frontier_blocked`, or `deadline_reached`.

The root contract may preauthorize bounded local work and scheduled ticket-plan approval. Push,
deploy, destructive/force operations, shared-branch merge, issue-system writes, and every data write
remain explicit consent gates. Skill improvements discovered during product work become separate
maintenance tickets between active tickets, so the executing contract does not change mid-run.

## Structure

```
SKILL.md                           # verify/deliver router + shared tick anatomy + safety rails
reference/mission-verify.md        # the verify mission: ORIENT/PICK/EXECUTE/VERIFY, named stops
reference/orchestrator-handoff.md  # fix directive shape + dispatch paths (worktree, ticket, report-only)
reference/mission-deliver.md       # INIT/TICK, durable frontier, lease, active ticket, stops
reference/supergoal-handoff.md     # installed supergoal packet, resume, exact close evidence
reference/prompting-insights.md    # evidence bar, intent integrity, QA toolkit, loop failure modes
reference/loop-contract.md         # the one-page loop contract: scope, permissions, budget, stop, mode, owns
reference/loop-runtime.md          # distilled built-in /loop mechanics + cache-aware pacing + Monitor rules
reference/state-ledger.md          # verify/deliver ledger schemas, idempotency, reconciliation
reference/worktree.md              # worktree isolation for a landed fix
reference/observability.md         # producer side of the live Board (sl-emit heartbeats)
templates/intent-spec.md           # frozen delivered-intent + acceptance-criteria queue, built at first tick
templates/{contract,ledger,delivery-ledger,tick-report}.md
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

`verify` can run independently. `deliver` requires an installed
[supergoal-skill](https://github.com/cskwork/supergoal-skill), because ticket execution is delegated
to its complete current contract.

## Tests

```bash
for t in tests/*.test.sh; do bash "$t"; done
```

Contract tests pin the existing verify mission and the new delivery contract: INIT/TICK separation,
disk-only re-entry, one active ticket, atomic lease, installed-supergoal handoff, exact close evidence,
frontier update, scheduler/deadline stops, consent gates, and the Board's never-gates invariant.

## Lineage

superloop's contract mirrors **Codex routines** (Boris Cherny): trigger + scope + budget + stop + report. Convergence is **Ralph**'s completion-promise: never emit "done" unless it is unequivocally true. Execution discipline - smallest correct change, failing test first - is **supergoal**'s throughout.
