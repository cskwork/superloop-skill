# Loop contract - one declarative page per loop

A loop is not a cron job. A cron job runs a fixed command; a loop is a recurring decision process -
inspect state, pick an action, apply bounded changes, verify, escalate if needed. The thing that
makes an unattended loop trustworthy is not capability, it is a **legible contract**: the teams that
win run the clearest loop contracts, not the most agents.

So before the first tick, write the contract. It fits on one page (`templates/contract.md`), and the
first tick copies it into the ledger's `## Contract` section so every later tick - and every fresh
context after compaction - reads the same rules. Fill it from the `/loop` invocation and the mission
reference; do not leave a field blank.

## The contract fields

| Field | What it pins | Example |
|---|---|---|
| **intent** | Verify: delivered intent and acceptance criteria. Deliver: frozen project brief and Frontier Map. | `templates/intent-spec.md`; `.superloop/deliver/project-brief.md` |
| **trigger** | What fires a tick: fixed interval, dynamic self-pace, or event-gated (Monitor). Mirrors the `/loop` launch. | `/loop 30m` ; `/loop` (dynamic) ; `Monitor on Jenkins deploy` |
| **scope** | `include` / `exclude` - the paths, services, JQL, or branches the loop may read and touch. Everything outside is off-limits. | include `services/lms/**`; exclude `infra/`, vendored code |
| **permissions** | What the loop may do **unattended** vs what **gates**. The gate list is the consent boundary (SKILL.md Safety rails). | unattended: read, test, build, local verify. gates: push/merge to shared branches, deploy, Jira writes, any data write |
| **budget** | The hard ceilings that stop a runaway loop. See below. | `max_ticks: 50`, `checkin_every_n_ticks: 10` |
| **stop** | The named conditions that end the loop (vs pause a unit). | queue empty 3 ticks; budget hit; mission-wide circuit breaker; mission complete |
| **report** | Where results land. | tick-report to user each tick; ledger; `docs/changelog/`; Board |
| **mode** | `report-only` or `write`. New or custom loops start `report-only` (read + propose, no writes); promote to `write` only after the signal is consistently useful. The verify loop starts `report-only` and earns `write` to dispatch fixes. | `mode: report-only` |
| **owns** | The writable resources this loop **exclusively owns** so concurrent loops never collide. Shared read is fine; shared write must be rare - one loop owns each writable thing. | owns: branch `fix/*`, the verify ledger, worktree `.superloop/verify/worktree` |

### Delivery extension

`deliver` fills the delivery extension in `templates/contract.md` before INIT is complete. These
fields are root-contract authority, not hints:

| Field | What it pins |
|---|---|
| `project_brief` | frozen path plus digest; a later mismatch stops instead of rewriting scope |
| `root_goal` | immutable destination/completion promise path plus digest; frontier revisions cannot rewrite it |
| `source_ref` | verified base ref from which each isolated supergoal run starts |
| `target_ref` / `target_is_shared` | intended integration ref and whether merging/pushing it is a consent gate |
| `integration_proof` | exact command/artifact proving a ticket is present on the intended target state |
| `deadline_or_duration` | hard project time bound; INIT converts duration once to immutable ledger `deadline_at` |
| `scheduler_job_id` | CronCreate id used for audit and CronDelete; use `dynamic` or `single-tick` when no cron exists |
| `launch_prompt` | original `/loop ...` launch message verbatim; audit only, never re-parsed |
| `scheduled_payload` | parsed delivery prompt (no interval token); the fixed cron payload |
| `dynamic_reentry_prompt` | `/loop `-prefixed dynamic wakeup prompt; `none` in fixed mode |
| `lease_recovery_rule` | objective owner-death proof, expiry grace, and actor allowed to recover a stale lease; age alone never authorizes recovery |
| `preauthorized_local_actions` | explicit unattended local actions; plan approval and local commit/non-shared integration acceptance are separate grants |
| `fresh_reentry` | reconstruct from disk and do not depend on chat memory |

Verify both refs before INIT writes tickets. `preauthorized_local_actions` cannot waive gates:
push, deploy, destructive/force operations, shared-branch merge, ticket-system writes, and every data
write still require explicit consent. Plan auto-approval is not commit acceptance. An unspecified
action is not preauthorized. An explicitly authorized scheduled delivery may start `mode: write`;
otherwise INIT records `report-only` and gates before product dispatch.

## Budget - hard ceilings (the "$400 overnight" guard)

An unattended loop with no ceiling can burn a weekend of spend grinding the same failure. The
per-unit tick budget and the consecutive-failure circuit breaker (SKILL.md) bound a *single* unit;
these bound the loop's *cumulative* lifetime. Record consumption in the ledger `## Counters` and stop
when any ceiling is hit.

| Budget | Meaning | On hit |
|---|---|---|
| `max_ticks` | total ticks before a mandatory stop + report | stop the loop, report; user restarts if wanted |
| `max_files_per_unit` | a single unit touching more files than this is over-scoped | abort the unit, mark `blocked(too-wide)`, escalate |
| `max_runtime_per_tick` | wall-clock a single tick may take | abort the unit this tick, record, move on |
| `checkin_every_n_ticks` | force a human check-in cadence | pause as `awaiting-approval(checkin)`, summarize, wait |
| max consecutive failures | per-unit and mission-wide (default 3 each) | per-unit -> `blocked`; mission-wide -> stop the loop |

A budget ceiling is a **stop**, not a failure: the loop ends cleanly and reports what it spent and
where it stopped. Never widen a budget mid-run to "just finish" - that is the exact behavior the
ceiling exists to prevent.

## Named stop conditions

The `stop` field should name **semantic** stops, not just "three failures". A named condition ends
the unit (or the loop) the first time it is true, instead of grinding to the circuit breaker. Each
mission reference lists its own; common ones:

- `tests_fail_after_one_fix` - one fix attempt didn't green the suite -> stop, don't iterate blindly.
- `merge_conflict_requires_product_decision` - a conflict needing a human call -> escalate, don't guess.
- `same_finding_seen_twice` - the same regression/smell resurfaces -> the approach is wrong; stop and report.
- `green_signal_wrong_outcome` - checks pass but the real result is wrong -> escalate (see SKILL.md Escalation triggers).
- `all_criteria_proven` - every acceptance criterion has fresh proof -> success stop; the verify loop is done.
- `orchestrator_cannot_close_gap` - the same criterion fails after the fix-directive limit -> escalate, don't grind.
- `all_tickets_integrated` - every delivery ticket has exact integration evidence -> success stop.
- `frontier_blocked` - incomplete delivery remains but no ticket is dependency-safe -> stop and report.
- `deadline_reached` - the delivery time bound expired before a claim -> stop and delete/omit pacing.

A named stop is cheaper than the circuit breaker: it halts at the first principled signal, before
three ticks of spend.

## Progressive autonomy - start report-only, earn write

The safest first loop is read-only. A new or custom loop starts `mode: report-only`: it runs the
full tick anatomy but **proposes instead of writes** - it surfaces findings, drafts the diff or the
doc, and records what it *would* do, gating every write as `awaiting-approval`. Promote it to
`mode: write` only after the signal has been consistently useful for several ticks (the user flips
the field in the ledger `## Contract`). Built-in defaults reflect this: `docs` and `qa` are
read-only, and the verify loop earns `write` to dispatch fixes but still gates every outward step.

Demote the same way: if a `write` loop starts producing low-value or wrong changes, drop it back to
`report-only` rather than stopping it - you keep the signal without the risk.

## Ownership - one writer per resource

Shared read access is fine; shared **write** access must be rare. Each loop names in `owns` the
writable resources it alone may change - a branch glob, its mission ledger, its worktree, a file
glob. Two loops may read anything, but no two loops write the same resource:

- A second loop on the same mission/repo uses a **distinct worktree** (and `--slot` so its Board
  heartbeat stays separate), or it waits.
- A loop never writes outside its `owns` set. Something it finds broken outside that set becomes a
  logged finding (a candidate unit for the loop that *does* own it), never a silent cross-write.
- The Board makes collisions visible: concurrent loops show as distinct rows with their own
  branch/worktree, so two writers aiming at one resource are obvious at a glance.

This is what makes it safe to run several superloops at once: the worktree (`reference/worktree.md`)
is the write space, and `owns` is the promise that nothing else writes there.

Deliver also uses a project-scoped atomic `mkdir .superloop/deliver/lease`. `owns` defines authority;
the lease serializes that authority. If the lease is held or ownership is uncertain, the new tick
fails closed without dispatching another ticket.

## Framing the loop's goal

Write the goal as a moving target, not a one-shot fix. Not "fix this bug" but "keep this unit moving
until it is either verified-done or blocked by a human decision." For the verify loop the target is
`all_criteria_proven` - keep each acceptance criterion of the delivered intent moving until it is
proven or escalated. The contract's `stop` and `permissions` fields are what let the loop run that
far unattended without overstepping.
