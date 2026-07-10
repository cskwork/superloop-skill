# FCT-002 - Multi-domain router mission

- Route: GREENFIELD
- Blocked by: FCT-001
- Unblocks: FCT-004, FCT-005, FCT-008

## Slice

A router step in deliver TICK that classifies the active ticket's `domain` and dispatches to the
registered worker skill via the FCT-001 contract, replacing hardcoded `supergoal`. Includes a skill
registry (`domain -> skill`) with a `supergoal` fallback for `dev` and fail-closed on unknown domain.

## Acceptance (EARS)

- WHEN active ticket `domain=dev` THEN dispatch `supergoal`; `design` -> `superdesign`; `docs` ->
  `superoffice`; `pm` -> `superpm`.
- WHEN `domain` has no registered skill THEN record `blocked` (no gu; no silent fallback to dev).
- WHEN a worker returns a receipt THEN record it per FCT-001 and keep exactly one active ticket.

## Proof commands

- Router unit test over a `domain -> skill` table (each mapping + unknown-domain fail-closed).
- `bash tests/deliver-contract.test.sh` still green.

## Non-goals

- Generating tickets (FCT-003); scope enforcement beyond passing `scope_grant_ref` through (FCT-005).
