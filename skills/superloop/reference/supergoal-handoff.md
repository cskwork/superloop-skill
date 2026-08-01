# Supergoal handoff - deliver one frozen ticket

The delivery tick delegates its active ticket to the **installed supergoal** skill. Resolve and load
that installation at dispatch time. Do not vendor a snapshot, paste an abbreviated workflow into the
ticket, or reimplement supergoal in superloop. Missing or incompatible installation is
`supergoal_unavailable`.

## Handoff packet

Create a self-contained packet from disk; do not add conversational assumptions:

- root contract path and digest, frozen project brief path and digest;
- root goal path and digest, including its project-level completion promise and non-goals;
- Frontier Map revision, frozen ticket path/id/digest, dependencies, and acceptance checks;
- verified `source_ref` and `target_ref`, whether the target is shared, and the exclusive run branch
  and worktree;
- allowed `preauthorized_local_actions` plus every consent gate;
- required design, data, Docker, domain, skill, and tool constraints copied unchanged from the brief
  and ticket;
- exact test commands and the root contract's named `integration_proof`;
- resolved installed-supergoal path and `SKILL.md` digest, plus its commit-gate path and digest;
- durable supergoal run-vault path/id and, when resuming, its `run-state.json`, approved `PLAN.md`,
  and latest `R-LOOP.md` section.

The ticket, not this reference, defines product behavior. If the ticket is ambiguous in a way that
changes behavior or scope, keep it active at an `ask-user` gate.

## Required inner workflow

Start each newly claimed spec in a **fresh top-level ticket context** loaded only from the durable
handoff packet. Run supergoal's complete current contract: Frame, then **Build -> Improve full spec
-> Improve edge cases -> Mandatory Adversarial Review -> Exact Verify/QA**. Preserve its red-green
requirement, fresh-context role isolation, worktree isolation, plan approval gate, loop cap, and
commit gate. Do not reimplement, skip, or collapse those roles in the outer tick.

A scheduled/background plan may be auto-approved only when every proposed action is included in the
root contract's `preauthorized_local_actions` and remains local to the exclusive worktree. A plan
that crosses scope, changes the frozen ticket, writes data, or requires an outward/shared action is
`awaiting-approval`; root autonomy is not blanket consent.

Plan auto-approval alone does not satisfy supergoal's user-acceptance precondition for commit or
integration. A local commit or merge into a non-shared target may proceed unattended only when the
root contract records the user's prior explicit acceptance of that exact action class. Shared
merge/push and the other standing gates always require a new explicit approval.

On a later tick, resume the named active run from durable artifacts. Never start a second supergoal
run for the same active ticket, and never claim a sibling while that run is unfinished.

The active claim freezes both installed-supergoal digests. Recheck them before unfinished work or a
commit-gate rerun. If the installation disappears, stop at `supergoal_unavailable`; if it upgrades
or changes, stop at `supergoal_contract_changed` rather than mixing workflow versions. A previously
captured gate proof remains usable only when it already binds the frozen digests and the worktree has
not changed; otherwise require the frozen installation or an explicit decision before resuming.

## Exact close evidence

Build one close-evidence manifest that binds every item below to the **same active ticket, run id,
run branch, and verified revision**, plus the current root-contract, root-goal, and ticket-spec
digests. Evidence from another run, a superseded spec, or a changed worktree is not composable.

The outer tick may close the ticket only when all of these agree:

1. `GOAL.md` exists and every Success Criterion/QA Case is checked by Exact Verify.
2. `QA.md` says `Verdict: PASS`, reports `Backward-trace: clean`, and contains the promised real
   proof rather than a proxy-only or `not proven` result.
3. `run-state.json` reports the completion promise proven with no blocker or unresolved gate.
4. `Z-<YYYY-MM-DD>.md` exists for the run branch and completion timestamp.
5. The commit gate captured by the active claim,
   `templates/commit-gate.sh <vault> <browser|cli|none>`, passed for the verified worktree revision.
   Capture its frozen script digest, command, exit status, output, verified revision/diff digest, and
   timestamp. If any tracked or untracked ticket file changes afterward, the **commit-gate proof is
   stale**: rerun Exact Verify/QA and the gate using the same frozen installed contract.
6. The root contract's named integration proof passes against the current `target_ref`, proving that
   same verified revision (or its recorded ticket commit) is present in the intended integration
   state, not merely on the worktree branch. Capture the resolved target commit/tree; a branch name
   alone is not evidence.

An agent summary is not completion evidence. A green inner suite without the required integration
proof is not completion evidence. If `target_ref` is shared, the merge/push remains a consent gate;
record `integration_requires_approval` and keep the ticket active until approved and proven.

Record the evidence-manifest path/digest, artifact paths/digests, tested revision/diff, target
commit/tree, target ref, commands, exit statuses, and timestamps in the delivery ledger's `## Ticket
runs`. Any disagreement keeps the active ticket open for the next fresh re-entry or an explicit
decision gate.
