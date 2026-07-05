# Prompting insights - run the verify loop the way this operator does

Distilled from the operator's own loop / QA / orchestration sessions. This is how "good" is judged
here; apply it at VERIFY and when writing a fix directive. Rules, not history.

## Evidence over vibes

Every verdict cites command output or a real number. "Looks correct" is not a verdict. A criterion
with no this-tick evidence is `unverified`, never `proven`.

## Ground truth is the spec, not the tests

Tests can be as wrong as the code. Enumerate the behaviors the tests do NOT exercise; run a
degenerate-input sweep per parameter (null / undefined / empty / boundary, error paths, concurrency,
untrusted input). Fail the spec, not merely the suite.

## Intent integrity

Preserve every explicit clause, negative constraint, assumption, and must-preserve invariant from the
request through to proof. A misunderstood objective is never fixed by more tests - re-read the intent
before widening coverage. A requirement the delivery silently dropped becomes its own criterion.

## Domain-generic

The loop must add value in any domain. Never inject a domain-specific guess as the fix; verify against
the delivered spec, not against assumptions about the domain.

## Succinct and DRY

Ledger entries, directives, and reports are agent-first: dense, one concept per line. Prose lives only
in the human-facing tick report - never in the ledger or a directive.

## QA toolkit (web / data)

- Browser flows: drive them (playwright-cli, or the project's own e2e tool) and assert the rendered
  result, not just that the page loaded.
- APIs: assert the response **body** and side effects, not the status code.
- Data: read-only DB checks; when production state can't be reproduced, seed synthetic/representative
  data rather than guessing.
- Cap QA actions (~100 per tick) so one criterion can't drown the context; keep reports indexed and
  repeatable.

## Fresh context per pass

Looped review -> verify -> improve beats one long pass. Each iteration re-derives from the ledger, not
from a memory of the last tick, so a wrong earlier conclusion doesn't calcify.

## Commit / done gate

Block "done" when QA fails, a requirement is unmet, or anything is uncertain. Ask the user rather than
guess a requirement - an unresolved question is an `awaiting-approval`, not a silent assumption.

## Guard the loop's own failure modes

Real incidents this loop must not repeat:

- Empty-response loop (consecutive empty turns) - back off and stop, don't spin.
- Stall -> kill -> re-dispatch churn - an agent still producing output is not stalled; check its
  output before recycling it.
- Worktree lock conflict - never lock a shared branch; each loop uses a distinct worktree.
- Budget-exceeded grind - a hit ceiling is a clean stop, never widen it to "just finish".

## The loop drives another agent

superloop is the loop manager, not the fixer. It verifies and directs; the orchestrator executes. Its
leverage is a precise, evidence-backed directive - not doing the work itself.
