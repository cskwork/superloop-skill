# FCT-003 - Meta-prompter: autonomous grounded ticket generation

- Route: GREENFIELD
- Blocked by: FCT-001
- Unblocks: FCT-004

## Slice

A generation step that, given `destination` + durable state + the closed-ticket trail, emits the next
unblocked vertical ticket(s) with acceptance checks + `domain`/`route` + `Blocked by` edges - grounded.
This is the "self-prompting" heart: no human-authored prompt required for well-grounded frontier work.

## Acceptance (EARS)

- WHEN the frontier is empty but the destination is unmet THEN generate >=1 grounded vertical ticket with
  acceptance checks, `domain`/`route`, and `Blocked by` edges.
- WHEN a required domain fact is absent THEN emit a `needs-grounding` decision (or a research ticket),
  NEVER a fabricated ticket.
- WHEN generating THEN dedupe against active/closed tickets and cite each ticket's grounding source.

## Guardrails

- Reuse supergoal's "do not guess the domain" rule; ambiguity that changes product behavior -> stop, not
  invent. Every generated ticket names the evidence it is grounded in.

## Proof commands

- Generation test on a seeded map: produces the expected next ticket; refuses (emits `needs-grounding`)
  on an ungrounded ask.

## Non-goals

- Routing/dispatch (FCT-002); feedback requeue (FCT-004).
