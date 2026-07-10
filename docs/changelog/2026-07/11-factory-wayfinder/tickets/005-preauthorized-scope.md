# FCT-005 - Pre-authorized autonomy scope contract + gate

- Route: GREENFIELD
- Blocked by: FCT-002
- Unblocks: FCT-007

## Slice

A durable, user-signed scope doc (e.g. `.superloop/deliver/scope.md` or a contract field) enumerating
allowed external/irreversible actions + bounds: channels/accounts, spend caps, environments
(`staging`|`prod`), rate limits. A gate lets in-scope external actions run unattended and fail-closes /
`scope-stop`s outside scope. Realizes the user's "fully autonomous within a pre-authorized scope".

## Acceptance (EARS)

- WHEN an external action is within the signed scope THEN it executes unattended and is receipted.
- WHEN an external action is outside scope THEN record `scope_stop` and do NOT act.
- WHEN the scope doc is missing or unsigned THEN ALL external actions fail-closed.

## Proof commands

- Gate test: in-scope allow, out-of-scope `scope_stop`, missing-scope fail-closed.

## Non-goals

- Building the external channel skills (FCT-007); defining the concrete LMS scope contents (done when a
  domain first needs external actions).
