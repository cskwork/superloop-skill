# Frontier Map - superloop as a self-prompting multi-domain factory

Platform-track WAYFINDER. Evolves the superloop SKILL itself (ships via PR). The LMS product frontier
lives separately in `lms-question-bank/.superloop/deliver/`.

## Destination

superloop becomes a fully-autonomous, self-prompting, multi-domain AI factory:

- a **meta-prompter** generates the next cross-domain unit of work from the product destination +
  durable state + the closed-ticket trail (no human-authored prompt required),
- a **router** dispatches each ticket to the correct installed worker skill by domain
  (`supergoal`=dev, `superdesign`=design, `superoffice`=docs/reports, `superpm`=PM/GTM, ...),
- verification failures and surfaced improvements **auto-requeue** as new grounded tickets
  (feedback self-correction),
- every tick runs **fresh-context** and **scheduler-driven**,
- irreversible external actions run **unattended only within a user-defined pre-authorized scope**.

Provable endpoint: the loop, unattended, advances a real product (LMS) from frontier to N integrated
tickets across >=2 domains (e.g. dev + docs) with meta-prompter-generated tickets, stopping only at
scope boundaries or genuine grounding gaps.

## Current state evidence

- `SKILL.md`: two missions - `verify` (post-delivery) and `deliver` (scheduled fresh-context, one
  vertical ticket per tick).
- `reference/mission-deliver.md`: INIT/TICK state machine; deliver drives ONLY installed `supergoal`;
  tickets are human-authored under `wayfinder/tickets/`; durable state under `.superloop/deliver/`.
- `reference/supergoal-handoff.md`: deliver -> supergoal handoff contract (single worker skill).
- Product proof in progress: `lms-question-bank` APP-001 (dev domain) delivered via supergoal -
  validates the inner loop before automating the outer loop.
- Installed workers available: `supergoal`(dev), `superdesign`(design), `superoffice`(docs/reports),
  `superpm`(PM/GTM/growth/pricing/release), `superqa`(browser QA), plus `to-prd`/`to-issues`,
  `gh-release`, `dataviz`, `kakaocli`(messaging). External SNS/marketing publish: no dedicated skill (gap).
- User directives (2026-07-11): fully-automatic self-prompting meta-prompter; multi-domain; feedback
  self-improve; pre-authorized-scope autonomy for external actions; superloop changes via PR;
  product + platform tracks in parallel.

## Decisions so far

- Autonomy = fully autonomous within a user-defined **pre-authorized scope**; external/irreversible
  actions are bounded, not per-action human-gated (user, 2026-07-11).
- Meta-prompter **generates** tickets/prompts, not only selects human-authored ones.
- Router dispatches per-domain to the right worker via a **uniform handoff/receipt contract**
  (generalize `supergoal-handoff`).
- Feedback / verification failures **auto-requeue** as new grounded tickets.
- Evolution, not rewrite: preserve `verify` + `deliver` and deliver's one-ticket-per-tick / lease /
  fail-closed invariants.
- superloop changes ship via PR. Product frontier state lives in the product repo's `.superloop/deliver/`.
- Product-track (LMS) and platform-track (this) proceed in parallel.

## Not yet specified

- Concrete pre-authorized scope contents (channels/accounts, spend caps, staging vs prod) - defined when
  a domain first needs external actions.
- Meta-prompter grounding contract: derive cross-domain tickets from a destination WITHOUT inventing
  domain facts (same "don't guess domain" rule as supergoal); ambiguity -> scope-stop or research ticket.
- Router domain taxonomy + skill-registry format (how a ticket declares domain/route -> which skill).
- Uniform receipt contract across heterogeneous outputs (code diff vs doc artifact vs design artifact vs
  published URL) - integration proof differs per domain.
- Feedback taxonomy: what auto-requeues vs what triggers a scope-stop; convergence/de-dupe guard.
- Scheduler mechanism (deliver's own scheduler vs `/schedule` routine vs `/loop`) + cadence/budget.
- Cross-domain dependency semantics (e.g. a marketing ticket blocked by a release ticket).

## Out of scope

- Building all marketing/SNS integrations now (tracked as FCT-007; not the first frontier).
- Reimplementing supergoal/superoffice/etc. internals - the factory ORCHESTRATES, does not rewrite them.
- Real external publishing / spend before a scope is defined and consented.
- Autonomous production deploy of the LMS app.
- Guessing product-domain facts (features, business strategy) the meta-prompter cannot ground.

## Ticket graph

- `FCT-001` - ready - Uniform worker-skill handoff/receipt contract. Blocked by: none. Unblocks: FCT-002, FCT-003.
- `FCT-002` - blocked - Multi-domain router mission (dispatch by domain, not hardcoded supergoal). Blocked by: FCT-001. Unblocks: FCT-004, FCT-005, FCT-008.
- `FCT-003` - blocked - Meta-prompter: autonomous, grounded ticket generation. Blocked by: FCT-001. Unblocks: FCT-004.
- `FCT-004` - blocked - Feedback/improvement auto-requeue with convergence guard. Blocked by: FCT-002, FCT-003. Unblocks: FCT-006.
- `FCT-005` - blocked - Pre-authorized autonomy scope contract + gate. Blocked by: FCT-002. Unblocks: FCT-007.
- `FCT-006` - blocked - Scheduler / loop-task registration for autonomous ticks. Blocked by: FCT-004.
- `FCT-007` - blocked - External-channel skill gap (marketing/SNS/promo). Blocked by: FCT-005. (Deferred.)
- `FCT-008` - blocked - Factory observability (cross-domain ledger/dashboard). Blocked by: FCT-002. (Optional.)

## Frontier

1. `FCT-001` - highest leverage: defines the seam the whole factory routes through; unblocks router +
   meta-prompter; small and verifiable (contract doc + contract test).
2. `FCT-003` (meta-prompter, the self-prompting heart) and `FCT-002` (router, the multi-domain reach) -
   next, once the contract exists.

Frontier rule: one ticket per fresh context. Immediate deliverable = **FCT-001**. Deliver it via
GREENFIELD (supergoal), verify, update this map, then pick the next frontier in a fresh context.
