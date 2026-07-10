# FCT-008 - Factory observability (cross-domain ledger / dashboard)

- Route: GREENFIELD
- Blocked by: FCT-002
- Status: optional / parallel

## Slice

A cross-domain ledger/dashboard: per tick record `{domain, worker_skill, receipt_status, feedback_requeues,
scope_stops}`. Extend deliver's existing board overlay so a human can watch the factory across domains
without gating it.

## Acceptance (EARS)

- WHEN a tick completes THEN the ledger appends one row with the fields above.
- WHEN rendered THEN a multi-domain run shows per-domain throughput, requeue counts, and scope-stops.

## Proof commands

- Ledger schema test + a rendered snapshot over a seeded multi-domain run.

## Non-goals

- Gating the loop (observe only).
