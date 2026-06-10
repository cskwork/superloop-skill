# superloop-skill

A Claude Code skill that puts a contract on every `/loop` tick.

`/loop` is the heartbeat (when to wake up); superloop is the discipline behind each beat (what to do, how much, how to verify and record). Built as a loop-native extension of [supergoal-skill](https://github.com/cskwork/supergoal-skill)'s baseline-first principles.

**Landing page**: https://cskwork.github.io/superloop-skill/ (KO default, EN toggle) · **한국어 문서**: [README.ko.md](README.ko.md)

## Why

Unattended loops fail in predictable ways: they redo finished work after compaction, mark unverified work done, batch half-finished changes, or invent work to look busy. superloop prevents all four with one rule set:

- **One unit of work per tick** - the smallest independently verifiable unit; never batch.
- **Ledger before memory** - durable state in `.superloop/<mission>/ledger.md` survives context compaction; an idempotent queue means a re-fired tick never redoes finished work.
- **Ground truth per tick** - no `done` without test/build/HTTP/DB evidence.
- **Gates outrank autonomy** - pushes, merges, deploys, and issue transitions pause as `awaiting-approval`; the ticket pauses, the loop keeps working.

## Tick anatomy

Every tick, every mission:

```
ORIENT -> PICK -> EXECUTE -> VERIFY -> RECORD -> PACE
```

| Step | Does |
|---|---|
| ORIENT | Read the ledger; reconcile against reality (git wins) |
| PICK | One open unit; empty queue backs off, never invents work |
| EXECUTE | supergoal discipline: smallest correct change, failing test first |
| VERIFY | Real tests / builds / HTTP bodies / read-only DB evidence |
| RECORD | Append-only tick log, advance the cursor, point to evidence |
| PACE | Cache-aware delays; Monitor instead of polling for events |

## Missions

| Launch | Mission |
|---|---|
| `/loop 1d /superloop docs` | Keep changelog / wiki / READMEs in step with recent commits |
| `/loop 1h /superloop smells` | Find one bug or code smell in recently-touched code, fix it red-green |
| `/loop 30m /superloop qa` | QA commits since the last verified SHA: intent, blast radius, side effects |
| `/loop /superloop jira` | One ticket per tick through a 12-stage pipeline with a non-skippable deploy consent gate |
| `/superloop <mission>` | Single tick, right now |

## Structure

```
SKILL.md                      # mission table + tick anatomy + safety rails
reference/loop-runtime.md     # distilled built-in /loop mechanics + cache-aware pacing + Monitor rules
reference/state-ledger.md     # ledger schema, idempotency, reconciliation
reference/mission-{docs,smells,qa,jira}.md
templates/{ledger,tick-report}.md
tests/*.test.sh               # contract tests (69 assertions) pinning the core rules
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

Contract tests fail if the skill ever loses its mission table, tick anatomy, one-unit rule, ledger, consent gates, or the jira pipeline stages.
