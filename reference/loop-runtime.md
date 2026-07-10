# Loop runtime - how /loop actually works (and how to drive it well)

Distilled from the built-in `/loop` prompt, plus the pacing/Monitor practice superloop adds.
Two modes: **fixed interval** (cron) and **dynamic** (self-paced via ScheduleWakeup). The
loop-as-routine model - trigger, scope, budget, stop, report - mirrors Codex routines; superloop's
version of that contract lives in `reference/loop-contract.md`.

## Parsing `[interval] <prompt...>` (priority order)

1. **Leading token**: if the first whitespace-delimited token matches `^\d+[smhd]$` (e.g. `5m`,
   `2h`), that is the interval; the rest is the prompt.
2. **Trailing "every" clause**: if the input ends with `every <N><unit>` or `every <N> <unit-word>`
   (`every 20m`, `every 5 minutes`), extract it as the interval and strip it from the prompt. Only
   when what follows "every" is a time expression - `check every PR` has no interval.
3. **No interval**: the whole input is the prompt -> dynamic mode.

Empty prompt -> show usage `/loop [interval] <prompt>` and stop.

## Fixed-interval mode (cron)

Convert the interval, then call CronCreate with `recurring: true` and the parsed prompt verbatim.

| Interval | Cron | Notes |
|---|---|---|
| `Nm`, N <= 59 | `*/N * * * *` | every N minutes |
| `Nm`, N >= 60 | `0 */H * * *` | round to hours; H must divide 24 |
| `Nh`, N <= 23 | `0 */N * * *` | every N hours |
| `Nd` | `0 0 */N * *` | midnight local |
| `Ns` | treat as `ceil(N/60)m` | cron granularity is 1 minute |

- If the interval doesn't cleanly divide its unit (`7m`, `90m`), round to the **nearest clean
  interval** and tell the user what you rounded to before scheduling.
- Confirm: cron expression, human cadence, that recurring jobs **auto-expire after 7 days**, and the
  job ID for CronDelete.
- **Then execute the parsed prompt immediately** - don't wait for the first cron fire.

For a new fixed-interval deliver loop, record CronCreate's id as `scheduler_job_id`, then execute the
prompt immediately: **deliver INIT runs immediately** and stops after durable bootstrap; it does not
dispatch a product ticket. The first cron fire re-enters TICK. If a ready delivery ledger already
exists, the immediate execution is a normal resume TICK.

## Dynamic mode (no interval - self-paced)

1. **Run the parsed prompt now** (slash command -> Skill tool; otherwise act directly).
2. **Event-gated next run?** (CI finishing, Jenkins deploy completing, a log line, a PR comment) ->
   arm a Monitor with `persistent: true`. Its `<task-notification>` events wake the loop
   immediately; you do not wait out the wakeup delay. Arm once: on later ticks check first whether a
   monitor is **already running** (TaskOutput/task list) and skip re-arming.
3. **Confirm briefly** - self-pacing, whether a Monitor is the primary wake signal, the fallback
   delay - as text *before* the wakeup call; the turn ends the moment that tool returns.
4. **ScheduleWakeup as the last action of this turn**, with:
   - `delaySeconds`: with a Monitor armed this is only the fallback heartbeat (1200-1800s); without
     one it is the cadence (see pacing below)
   - `reason`: one short specific sentence
   - `prompt`: the full original /loop input verbatim, **prefixed with `/loop `** (e.g.
     `/loop /superloop verify`) so the next fire re-enters the skill and continues the loop
5. **Woken by `<task-notification>`?** Handle the event in the loop's context, then call
   ScheduleWakeup again with the same prompt and the same 1200-1800s fallback - the Monitor stays
   the wake signal; this only resets the safety net.
6. **Stop the loop**: **omit the ScheduleWakeup call** and TaskStop any Monitor you armed. For cron
   loops, CronDelete the job ID.

## Delivery re-entry and duration

Launch fixed delivery with `/loop 30m /superloop deliver <project-brief>` (choose the interval that
fits the project's ticket size). INIT freezes that brief, the root contract, Frontier Map, tickets,
and delivery ledger. Every later fire must **reconstruct from disk** before selecting work and must
not depend on chat history, even when the host happens to reuse a session. The installed supergoal
still uses fresh role contexts for each active spec.

The root contract and delivery ledger record:

- `deadline_or_duration` - for a one- or two-day run, an exact deadline or duration bounded below
  the host's 7-day automatic expiry; INIT converts a duration once to immutable `deadline_at`;
- `scheduler_job_id` - the CronCreate id, or `dynamic` / `single-tick` when there is no cron; and
- `launch_prompt` - the original `/loop ...` launch message verbatim, kept for audit only and never
  re-parsed on re-entry;
- `scheduled_payload` - the parsed delivery prompt without the interval token, recorded in both
  modes; a fixed loop's CronCreate receives `scheduled_payload` and never receives `launch_prompt`;
  and
- `dynamic_reentry_prompt` - dynamic mode's exact wakeup prompt (the `/loop `-prefixed payload),
  `none` in fixed mode; plus the frozen project-brief and root-goal digests and current active
  ticket/run id.

At the start of ORIENT, check the deadline before a new claim. `deadline_reached`,
`all_tickets_integrated`, `active_ticket_blocked` (max consecutive failed ticks on one active
ticket), or another named delivery stop releases the lease and stops cleanly: dynamic mode omits
ScheduleWakeup; fixed mode calls CronDelete with the recorded job id. Never rely
on eventual auto-expiry as the normal stop. RECORD and lease release happen before dynamic
ScheduleWakeup, which remains the last action of the turn.

Each fixed re-entry also reconciles `scheduler_job_id` against the scheduler. If it is absent or its
status cannot be read, record `scheduler_job_missing`, release the lease, and stop before dispatch;
never create a replacement job silently. If the deadline or a mandatory check-in is reached while a
ticket is active, persist its phase, keep the active ticket unchanged, release the lease, and stop
pacing. A later explicitly authorized resume continues that ticket before any sibling.

## Cache-aware pacing

The Anthropic prompt cache has a **5-minute** TTL; sleeping past it makes the next wake re-read the
whole conversation uncached.

- **60-270s**: cache stays warm - only for actively polling external state a Monitor can't watch.
- **Don't pick 300s** - worst of both worlds (cache miss without amortizing it). Drop to <=270s or
  commit to >=1200s.
- **1200-1800s**: the idle default and the Monitor-fallback heartbeat.
- Polling something the harness already tracks (background Bash, subagents) is always wrong - you
  get re-invoked on completion; schedule only a long fallback.

## Monitor quality bar

- Filter must cover **every terminal state**, not just success - **silence is not success**. A
  watcher that greps only the success marker stays silent through a crashloop: widen the
  alternation (`Ready|Error|Traceback|FAILED|Killed`).
- Line-buffer every pipe stage (`grep --line-buffered`); selective output (lines you'd act on).
- One-shot waits ("tell me when the build finishes") use background Bash with an `until` loop, not a
  persistent Monitor.

## `.claude/loop.md` tasks file

Bare `/loop` (no prompt) looks for a loop-tasks file at `.claude/loop.md` (project) or `~/.claude/loop.md`
(capped at 25000 bytes) and runs its tasks each tick via a sentinel prompt that re-expands when the
file is edited. Put `/superloop verify` there for acceptance checks, or
`/superloop deliver <project-brief>` for durable project delivery.

## Launch recipes

| Want | Type |
|---|---|
| Verify a delivery every commit batch, office hours-ish | `/loop 30m /superloop verify` |
| Verify an orchestrator's delivery, event-driven | `/loop /superloop verify` (dynamic + Monitor on CI/deploy) |
| Nightly acceptance sweep | `/loop 1d /superloop verify` (or /schedule for a durable cloud routine) |
| One acceptance tick right now | `/superloop verify` |
| Initialize, then deliver one vertical ticket per 30-minute fire | `/loop 30m /superloop deliver <project-brief>` |
| Self-paced project delivery | `/loop /superloop deliver <project-brief>` |
| Initialize or resume one delivery tick now | `/superloop deliver <project-brief>` |

Session-bound: /loop jobs die with the session and recurring jobs auto-expire after 7 days - for
durable schedules point the user at /schedule.
