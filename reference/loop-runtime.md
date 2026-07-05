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
file is edited. To run the verify loop this way, put `/superloop verify` there.

## Launch recipes

| Want | Type |
|---|---|
| Verify a delivery every commit batch, office hours-ish | `/loop 30m /superloop verify` |
| Verify an orchestrator's delivery, event-driven | `/loop /superloop verify` (dynamic + Monitor on CI/deploy) |
| Nightly acceptance sweep | `/loop 1d /superloop verify` (or /schedule for a durable cloud routine) |
| One acceptance tick right now | `/superloop verify` |

Session-bound: /loop jobs die with the session and recurring jobs auto-expire after 7 days - for
durable schedules point the user at /schedule.
