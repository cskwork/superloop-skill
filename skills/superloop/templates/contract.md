# Loop contract - <mission>

<!-- Fill this before the first tick. The first tick copies it into the ledger ## Contract section.
     One page. No blank fields. Spec: reference/loop-contract.md. -->

- **intent**: <verify: delivery request/ticket/PR + Intent Spec; deliver: frozen root goal path + sha256>
- **trigger**: <fixed interval `/loop 30m` | dynamic `/loop` | event-gated Monitor on ...>
- **scope**:
  - include: <paths / services / JQL / branches the loop may touch>
  - exclude: <off-limits paths / vendored code / other teams' areas>
- **permissions**:
  - unattended: <read, test, build, local verify, ...>
  - gates (consent required): <push/merge to shared branches, deploy, Jira transitions/comments, any data write, force ops>
- **budget**:
  - max_ticks: <e.g. 50>
  - max_files_per_unit: <e.g. 10; 0 for a report-only verify loop - the orchestrator's fix touches files, the loop writes only .superloop/verify/>
  - max_runtime_per_tick: <e.g. 20m>
  - checkin_every_n_ticks: <e.g. 10>
  - max consecutive failures: 3 per-unit / 3 mission-wide
- **stop**: <mission completion/block stops | deadline | queue empty 3 ticks | budget hit | circuit breaker>
- **report**: <tick-report to user each tick; ledger; docs/changelog/; Board>
- **mode**: <report-only | write>   <!-- new/custom loops start report-only -->
- **owns**: <branches / ledger / worktree / file globs this loop exclusively writes>

## Delivery extension

<!-- Required for `deliver`; remove this section for `verify`. No blank values. -->

- **project_brief**: <`.superloop/deliver/project-brief.md` + sha256>
- **root_goal**: <`.superloop/deliver/root-goal.md` + sha256>
- **source_ref**: <verified base ref>
- **target_ref**: <verified integration ref>
- **target_is_shared**: <true | false>
- **integration_proof**: <exact command/artifact proving the ticket is on target_ref>
- **deadline_or_duration**: <absolute ISO-8601 deadline and/or duration>
- **scheduler_job_id**: <CronCreate id | dynamic | single-tick>
- **launch_prompt**: <original `/loop ...` launch message verbatim; audit only, never re-parsed>
- **scheduled_payload**: <parsed delivery prompt without the interval token; what a fixed cron re-fires>
- **dynamic_reentry_prompt**: <`/loop `-prefixed wakeup prompt | `none` in fixed mode>
- **lease_recovery_rule**: <objective owner-death proof, expiry grace, and actor authorized to recover; otherwise approval required>
- **preauthorized_local_actions**: <explicit local reads/writes/tests/builds; plan auto-approval; local commit/non-shared integration acceptance named separately>
- **fresh_reentry**: reconstruct from disk; no chat memory
