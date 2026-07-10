# 2026-07-11 - Factory WAYFINDER (platform track)

WAYFINDER map + FCT-001..008 tickets for evolving superloop into a self-prompting, multi-domain,
fully-autonomous (pre-authorized-scope) factory. Planning only; no skill code changed in this PR.

## Why

User directive (2026-07-11): the end goal is a self-driving AI factory - a meta-prompter generates the
prompts, routes work across super* skills (dev/design/docs/PM/marketing), self-corrects on feedback, and
runs unattended within a pre-authorized scope. Product (LMS) and platform tracks run in parallel.

## Rejected alternatives

- **Rewrite `deliver` into a monolithic factory mission** - rejected: preserve deliver's one-ticket-per-
  tick / lease / fail-closed invariants; evolve via a composable contract (FCT-001) + router (FCT-002).
- **Hardcode a `domain -> skill` switch inside deliver** - rejected: use a registry + the uniform FCT-001
  contract so new domains/skills plug in without editing the deliver core.
- **Per-action human approval for external actions** - rejected by user: pre-authorized scope (FCT-005),
  fully autonomous inside the signed boundary, `scope_stop` outside.
- **Free-generating meta-prompter** - rejected: a grounding contract + `needs-grounding` stop (FCT-003)
  prevents hallucinated scope; same "do not guess the domain" rule supergoal already enforces.
- **Put the LMS product frontier in superloop-skill** - rejected: product frontier lives in
  `lms-question-bank/.superloop/deliver/`; superloop-skill holds only the skill.

## Frontier

Next deliverable = FCT-001 (uniform worker handoff/receipt contract). Deliver via GREENFIELD in a fresh
context, verify, update `map.md`, then pick the next frontier.
