# Mission: deliver - advance one vertical project ticket per scheduled tick

Unit = **one active vertical ticket**. `deliver` owns cadence, durable frontier state, claiming,
overlap protection, and integration accounting. The installed `supergoal` owns the ticket's complete
delivery workflow. This mission is separate from `verify`; it does not change verify's
one-acceptance-criterion unit.

Durable state lives under `.superloop/deliver/`:

- `contract.md` - the filled root loop contract.
- `project-brief.md` - the frozen root project brief and its digest.
- `root-goal.md` - the immutable destination, project completion promise, scope, and non-goals
  derived from that brief; its digest is independent of the mutable frontier.
- `wayfinder/map.md` - the dependency-aware Frontier Map.
- `wayfinder/tickets/<ticket-id>.md` - frozen, vertical ticket specs.
- `ledger.md` - project cursor, frontier status, active ticket, ticket runs, and counters.
- `lease/` - the atomic single-writer lease; it is not progress state.

## INIT - bootstrap once

INIT runs only while the delivery ledger is absent or marked `initializing`. It is idempotent: a
partial INIT resumes from the durable files already written and never creates a second project.

1. Acquire the project lease described below.
2. Validate the root project brief; verify `source_ref`, `target_ref`, and `target_is_shared`;
   resolve permissions, gates, `integration_proof`, `deadline_or_duration`, `scheduler_job_id`, the exact re-entry
   records (`launch_prompt` audit copy, `scheduled_payload`, `dynamic_reentry_prompt`),
   `lease_recovery_rule`, and `preauthorized_local_actions` from explicit user authority.
3. Freeze the brief at `.superloop/deliver/project-brief.md`. Derive one immutable
   `.superloop/deliver/root-goal.md` containing the destination, project-level success/stop
   conditions, constraints, scope, and non-goals. Record both digests. The root goal refines the
   brief but may not add product behavior. Normalize a relative duration once to an absolute
   `deadline_at`; never roll that deadline forward on re-entry.
4. Fill every delivery field in `templates/contract.md`, including both frozen paths/digests, refs,
   integration proof, deadline, scheduler identity, re-entry records, permissions, gates, and local
   preauthorization. No delivery field remains blank.
5. Invoke the installed `supergoal` WAYFINDER workflow in a fresh context, using the root goal and
   brief as its whole destination, to create
   `.superloop/deliver/wayfinder/map.md` and vertical specs under
   `.superloop/deliver/wayfinder/tickets/`. Each ticket must be independently demoable and name its
   dependencies, acceptance checks, constraints, required tools/skills, and integration proof.
6. Bootstrap `ledger.md` from `templates/delivery-ledger.md` with the contract digest and scheduler
   status, validate that root-goal, map, and ticket paths exist, then mark initialization ready.
7. Release the lease and PACE. INIT does not claim or dispatch a product ticket; the first
   scheduled re-entry starts TICK with a fresh, disk-reconstructed context.

Do not use chat history to fill a missing field, infer a completed step, or select a ticket. If a
required durable artifact cannot be reconstructed, stop with the missing path and required action.

## Lease - exactly one writer

Before INIT or TICK reads-and-mutates delivery state, create the parent directory and acquire the
lease with atomic `mkdir .superloop/deliver/lease`. On success, write owner metadata inside it:
run/tick id, process or host identity, `scheduler_job_id`, acquired time, and expiry derived from
`max_runtime_per_tick`.

- If `mkdir` reports that the lease exists, **fail closed**: do not claim, dispatch, close, or alter
  a ticket. Report the recorded owner and let the owning tick continue.
- Never break a lease merely because it is old. Recover only with objective proof that the owner is
  dead and the root contract's explicit `lease_recovery_rule`; otherwise mark
  `awaiting-approval(stale-lease)`. A recovery claimant must preserve the old owner metadata and
  proof, win an atomic rename of the old lease to a unique tombstone, then win a new `mkdir`; any
  lost race fails closed.
- Install cleanup before doing work and release the lease on every exit, including failure,
  deadline, and approval-gate exits. RELEASE happens before PACE schedules another dynamic tick.

The lease protects the ledger write transaction. Stable ticket ids provide idempotency after a
crash; they do not replace the lease.

## TICK - every scheduled re-entry

Every TICK reconstructs its next action from `contract.md`, `project-brief.md`, `root-goal.md`,
`ledger.md`, the Frontier Map, ticket files, git state, and the active supergoal run. Conversational
memory is neither read nor trusted.

### ORIENT

1. Acquire the lease.
2. Read and validate every durable file above. Verify the project-brief and root-goal digests,
   active ticket spec digest, `source_ref`, `target_ref`, immutable `deadline_at`, scheduler
   identity, re-entry records, and permissions. A changed brief/root/ticket is respectively
   `project_brief_mismatch`, `root_goal_mismatch`, or `ticket_spec_mismatch`; keep the active ticket
   unchanged and fail closed.
3. For fixed mode, verify that `scheduler_job_id` still names the recurring job. Missing or
   unreadable scheduler state is `scheduler_job_missing`: do not silently create a replacement or
   dispatch work whose next tick is not durable.
4. Check the deadline and `checkin_every_n_ticks` before EXECUTE or a new claim. If the deadline
   reached while a ticket is active, record its current phase, keep it unchanged, release the lease,
   and stop pacing. If a check-in is due while a ticket is active, mark it
   `awaiting-approval(checkin)`, keep it unchanged, release the lease, and stop pacing. Neither case
   may expose a sibling claim.
5. Reconcile the ledger with git and the named supergoal run artifacts. Resolve and compare the
   claimed source commit, target base commit, run branch/worktree, worktree diff, installed
   supergoal `SKILL.md`, and commit-gate digests. Expected ticket changes remain resumable; unknown
   movement is `ref_or_worktree_drift` and fails closed. Never clean, reset, or overwrite a dirty
   worktree to make the record match.

### PICK

Maintain **exactly one active ticket**. Always resume the active ticket before claiming a sibling.
If no ticket is active, select the highest-priority unblocked frontier ticket deterministically,
preallocate its stable idempotency key, run id, run-vault path, branch, and worktree, then render the
complete next ledger to a sibling temporary file. Validate that it contains exactly one active
ticket with the frozen spec digest, and publish it with a same-directory **atomic rename before
dispatch**. Re-read the committed active-ticket record and verify every id/path/digest before
starting the installed supergoal. Never edit the live active-ticket row in place.

A crash before the rename cannot have dispatched work; a crash after it leaves one durable active
ticket and one preallocated run for the next tick to resume. A claimed-but-not-started run launches
that same preallocated run id; it never allocates another. If the committed record is incomplete
or contradicts existing run artifacts, fail closed and repair that record under the lease; never
create a second run or claim a sibling.

If every ticket has exact integration evidence, stop at `all_tickets_integrated`. If unfinished
tickets remain but none is unblocked, stop at `frontier_blocked` with the dependency evidence. An
empty or malformed map is not permission to invent work.

### EXECUTE

Dispatch or resume only the active ticket through `reference/supergoal-handoff.md`. Use the complete
installed supergoal contract in fresh role contexts. The outer loop must not copy, shorten, or
replace supergoal's Frame/Build/Improve/Review/Exact Verify method.

Resume by durable phase, not by repeating the whole tick. `claimed` with no run artifacts dispatches
the preallocated run; `running` resumes it. If the bound run already has the complete exact inner
artifact set, atomically record `inner-verified`, skip EXECUTE and continue at VERIFY. This covers a
crash after inner completion without redispatching completed work.

Root-contract `preauthorized_local_actions` may auto-approve a scheduled ticket plan only while the
plan stays within those local actions and the exclusive worktree. Push, deploy, destructive or force
operations, shared-branch merge, ticket-system writes, and every data write remain consent gates.

### VERIFY

Read the machine-checkable artifacts listed in `reference/supergoal-handoff.md`. A ticket remains
active when an artifact is missing, inconsistent, red, or awaiting approval. An agent summary,
passing targeted test alone, or code present only on a run branch cannot close the ticket.

### RECORD

Append tick and supergoal run evidence to the active ticket's **provisional evidence bundle** under
its own run-vault path and stable close idempotency key; per-ticket paths keep one ticket's evidence
from ever overwriting another's. The provisional bundle never closes a ticket. Before repeating any
integration action, run the named read-only proof against the current target and look for an earlier
integration receipt. If the same verified ticket revision is already present, record
`integration-observed` and replay only the durable close transaction. A durable receipt that
contradicts the recorded one is fail-closed drift; never overwrite a recorded receipt. Never merge,
push, deploy, or write data again merely because RECORD crashed.

When integration is still needed, persist `integration-pending` and the close key before acting.
Consent-gated integration records `integration_requires_approval`, keeps the ticket active, releases
the lease, and stops pacing. After an authorized action, capture a durable integration receipt (or
target commit/tree) before publishing `integration-observed`. A non-idempotent integration that
cannot accept the close key or return a durable integration receipt is never automated; leave it at
an approval gate. Publish the final close only after the durable integration receipt (or captured
target commit/tree) exists:

1. render the complete close evidence (ticket revision, close key, receipt digest) from the
   provisional bundle to a sibling temporary file, validate it, and atomically rename it to the
   immutable final close manifest; if that manifest already exists, verify its digest and never
   overwrite it;
2. recompute the frontier from ticket dependencies and the actual integrated target ref, write it
   to a sibling temporary file, validate it, and atomically rename it over the map;
3. render the complete ledger with the active ticket integrated and cleared, the final-manifest
   digest, and the new map revision, then validate and atomically rename it over `ledger.md`; and
4. queue any discovered skill improvement as a separate maintenance ticket.

The ledger clear is last. A crash before the final rename publishes nothing immutable; a crash after
it leaves the same active ticket to resume and idempotently replay close. Neither can expose a
sibling claim against a half-recorded integration.

Freeze the active ticket and installed execution contract for its lifetime. A maintenance ticket may
change the skill only between product tickets, never while a product ticket is active. Do not start a
sibling ticket in the same tick; one close still consumes that tick's single unit.

### PACE

Release the lease, emit the tick report/Board heartbeat, then follow `reference/loop-runtime.md`.
Dynamic mode's ScheduleWakeup remains the last action. Fixed mode lets cron re-fire. Any named stop
omits the wakeup or deletes the recorded cron job.

## Named stops

- `all_tickets_integrated` - every frontier ticket is integrated with exact evidence; success.
- `frontier_blocked` - unfinished tickets exist but no dependency-safe ticket can run; report the
  blockers and stop.
- `deadline_reached` - the root deadline/duration expired before a new claim; record and stop.
- `project_brief_mismatch` - a re-entry prompt conflicts with the frozen brief; never overwrite it.
- `root_goal_mismatch` - the immutable root goal is missing or its digest changed; never derive a
  replacement from chat history.
- `ticket_spec_mismatch` - the active frozen ticket digest changed; never adopt it mid-run.
- `supergoal_unavailable` - the installed supergoal contract cannot be loaded; never improvise it.
- `supergoal_contract_changed` - the claimed installed skill or commit-gate digest changed before
  unfinished inner work could complete; never upgrade an active run implicitly.
- `ref_or_worktree_drift` - claimed commits or exclusive worktree state changed outside the named
  run; preserve it and require reconciliation instead of cleaning it.
- `scheduler_job_missing` - a fixed loop's recorded recurring job is absent or cannot be proven;
  never recreate it silently.
- `active_ticket_blocked` - the same active ticket failed the contract's max consecutive ticks;
  preserve the active ticket and its recorded phase, write this stop reason durably, and remove
  pacing: CronDelete the recorded fixed job or omit ScheduleWakeup. Later ticks only report the
  stop; they never re-arm pacing or claim a sibling until an explicit authorized resume clears it.
- `integration_requires_approval` - exact close needs a gated shared merge, push, deploy, or data
  write; keep the ticket active and await that approval.
