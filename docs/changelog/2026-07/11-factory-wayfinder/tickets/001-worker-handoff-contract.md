# FCT-001 - Uniform worker-skill handoff/receipt contract

- Route: GREENFIELD
- Blocked by: none
- Unblocks: FCT-002, FCT-003

## User story

As the factory router, I want one uniform contract to hand any ticket to any worker skill and get back a
typed integration receipt, so that deliver is not hardcoded to `supergoal` and can drive dev / docs /
design / PM work through the same seam.

## Scope

Define, as a reference doc + a contract test, two envelopes:

- **Dispatch envelope** (deliver -> worker): `{ticket_id, domain, route, destination_ref,
  acceptance_checks[], scope_grant_ref, durable_state_paths}`.
- **Receipt envelope** (worker -> deliver): `{ticket_id, output_kind, integration_proof, status,
  artifacts[]}` where
  - `output_kind` in {`code-diff`, `doc-artifact`, `design-artifact`, `published-url`, `data-artifact`},
  - `status` in {`integrated`, `integration-pending`, `blocked`, `scope-stop`, `needs-grounding`}.

Prove `supergoal`'s existing `reference/supergoal-handoff.md` maps onto this contract with no loss
(backward compatible).

## Acceptance criteria (EARS)

- WHEN a ticket is dispatched THEN the envelope SHALL carry every dispatch field above.
- WHEN a worker completes THEN it SHALL return a receipt whose `status` is in the closed set and whose
  `integration_proof` is present for `integrated`.
- WHEN the worker is `supergoal` THEN its current handoff SHALL map onto this contract with no loss.
- WHEN `status` in {`needs-grounding`, `scope-stop`, `blocked`} THEN the loop SHALL NOT mark the ticket
  integrated and the receipt SHALL name the unresolved decision.

## Edge cases

- Unknown domain / no registered skill -> `blocked` with reason (handled fully in FCT-002; contract must
  allow it).
- Provisional/partial worker output -> `integration-pending`, never `integrated`.
- Receipt missing `integration_proof` for an `integrated` claim -> fail-closed.

## Proof commands

- `bash tests/factory-handoff-contract.test.sh` (new) - validates both envelope shapes + the closed
  status set + the supergoal mapping.
- `bash tests/deliver-contract.test.sh` still green (backward compatibility).

## Non-goals

- The router (FCT-002) and meta-prompter (FCT-003). This ticket ships only the contract doc + test.
