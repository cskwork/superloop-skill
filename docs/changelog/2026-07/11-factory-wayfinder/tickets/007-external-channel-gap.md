# FCT-007 - External-channel skill gap (marketing / SNS / promo)

- Route: GREENFIELD | SKILL-MINE
- Blocked by: FCT-005
- Status: deferred (not the first frontier)

## Slice

New skill(s) / MCP integration for external publishing (SNS, marketing, promo), invoked by the router
within the FCT-005 pre-authorized scope. Fills the identified gap: no dedicated external-publish skill
exists today.

- Research: `reference/research.md -> which MCP servers / first-party APIs are available for the target
  channels (X, Instagram, blog, email)`; capture the answer as a linked asset before building.

## Acceptance (EARS)

- WHEN the router dispatches an external-publish ticket THEN the skill publishes ONLY within the signed
  scope and returns a `published-url` receipt.
- WHEN outside scope THEN `scope_stop` (per FCT-005).

## Non-goals

- Any action outside a defined + consented scope; channel-specific growth strategy (that is `superpm`).
