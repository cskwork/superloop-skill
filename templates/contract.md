# Loop contract - <mission>

<!-- Fill this before the first tick. The first tick copies it into the ledger ## Contract section.
     One page. No blank fields. Spec: reference/loop-contract.md. -->

- **intent**: <the delivery under verification - request/ticket/PR; acceptance criteria in `templates/intent-spec.md`>
- **trigger**: <fixed interval `/loop 30m` | dynamic `/loop` | event-gated Monitor on ...>
- **scope**:
  - include: <paths / services / JQL / branches the loop may touch>
  - exclude: <off-limits paths / vendored code / other teams' areas>
- **permissions**:
  - unattended: <read, test, build, local verify, ...>
  - gates (consent required): <push/merge to shared branches, deploy, Jira transitions/comments, any data write, force ops>
- **budget**:
  - max_ticks: <e.g. 50>
  - max_files_per_unit: <e.g. 10>
  - max_runtime_per_tick: <e.g. 20m>
  - checkin_every_n_ticks: <e.g. 10>
  - max consecutive failures: 3 per-unit / 3 mission-wide
- **stop**: <all_criteria_proven | orchestrator_cannot_close_gap | queue empty 3 ticks | budget hit | circuit breaker>
- **report**: <tick-report to user each tick; ledger; docs/changelog/; Board>
- **mode**: <report-only | write>   <!-- new/custom loops start report-only -->
- **owns**: <branches / ledger / worktree / file globs this loop exclusively writes>
