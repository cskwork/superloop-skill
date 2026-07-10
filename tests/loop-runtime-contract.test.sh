#!/usr/bin/env bash
# /superloop loop-runtime contract.
# Fails if reference/loop-runtime.md drifts from the real built-in /loop mechanics
# (parsing, cron table, dynamic pacing, Monitor wiring, stop semantics, cache windows).

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

require_text() {
  local label="$1" file="$2" text="$3"
  local normalized
  normalized="$(tr '\n\t\r' '   ' < "$ROOT/$file" 2>/dev/null | tr -s ' ')"
  if printf '%s' "$normalized" | grep -Fqi -- "$text"; then
    PASS=$((PASS + 1)); printf '  PASS  %s\n' "$label"
  else
    FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$label"; printf '        missing in %s: %s\n' "$file" "$text"
  fi
}

require_file() {
  local label="$1" file="$2"
  if [ -f "$ROOT/$file" ]; then
    PASS=$((PASS + 1)); printf '  PASS  %s\n' "$label"
  else
    FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$label"; printf '        missing file: %s\n' "$file"
  fi
}

echo "=================================================================="
echo " /superloop loop-runtime contract   skill: $ROOT"
echo "=================================================================="

require_file "loop-runtime reference exists" "reference/loop-runtime.md"

# Parsing rules match the built-in /loop prompt.
require_text "leading interval token rule" "reference/loop-runtime.md" 'matches `^\d+[smhd]$`'
require_text "trailing every-clause rule" "reference/loop-runtime.md" "every <N><unit>"
require_text "every-PR counterexample kept" "reference/loop-runtime.md" "check every PR"

# Fixed-interval mode.
require_text "interval to cron table" "reference/loop-runtime.md" "*/N * * * *"
require_text "uneven interval rounding warned" "reference/loop-runtime.md" "nearest clean interval"
require_text "first run executes immediately" "reference/loop-runtime.md" "don't wait for the first cron fire"
require_text "recurring jobs auto-expire" "reference/loop-runtime.md" "auto-expire after 7 days"
require_text "fixed delivery cron receives parsed payload" "reference/loop-runtime.md" 'CronCreate receives `scheduled_payload`'
require_text "fixed delivery cron never receives launch prompt" "reference/loop-runtime.md" 'never receives `launch_prompt`'

# Dynamic mode.
require_text "dynamic re-entry prompt keeps /loop prefix" "reference/loop-runtime.md" 'prefixed with `/loop `'
require_text "dynamic wakeup uses dedicated prompt" "reference/loop-runtime.md" "dynamic_reentry_prompt"
require_text "ScheduleWakeup is the last action of the turn" "reference/loop-runtime.md" "last action of this turn"
require_text "stop by omitting ScheduleWakeup" "reference/loop-runtime.md" "omit the ScheduleWakeup call"

# Cache-aware pacing.
require_text "5-minute prompt-cache window" "reference/loop-runtime.md" "5-minute"
require_text "avoid the 300s worst case" "reference/loop-runtime.md" "don't pick 300s"
require_text "idle fallback 1200-1800s" "reference/loop-runtime.md" "1200"

# Event-gated waits use Monitor, not polling.
require_text "Monitor for event-gated ticks" "reference/loop-runtime.md" "persistent: true"
require_text "monitor armed once, checked before re-arming" "reference/loop-runtime.md" "already running"
require_text "monitor must cover failure states too" "reference/loop-runtime.md" "silence is not success"

# loop.md tasks-file mode.
require_text "loop.md tasks file documented" "reference/loop-runtime.md" ".claude/loop.md"

# Scheduled delivery initializes now, then every fire reconstructs from disk with bounded duration.
require_text "deliver launch recipe exists" "reference/loop-runtime.md" "/loop 30m /superloop deliver <project-brief>"
require_text "deliver INIT executes immediately" "reference/loop-runtime.md" "deliver INIT runs immediately"
require_text "deliver ticks reconstruct from disk" "reference/loop-runtime.md" "reconstruct from disk"
require_text "deliver re-entry ignores chat memory" "reference/loop-runtime.md" "must not depend on chat history"
require_text "delivery deadline is recorded" "reference/loop-runtime.md" "deadline_or_duration"
require_text "scheduler job id is recorded" "reference/loop-runtime.md" "scheduler_job_id"
require_text "original launch prompt is audit-only" "reference/loop-runtime.md" "launch_prompt"
require_text "parsed delivery payload is durable" "reference/loop-runtime.md" "scheduled_payload"
require_text "delivery deadline stops wakeups" "reference/loop-runtime.md" "deadline_reached"
require_text "delivery convergence deletes cron" "reference/loop-runtime.md" "all_tickets_integrated"
require_text "missing delivery cron is detected" "reference/loop-runtime.md" "scheduler_job_missing"
require_text "active ticket survives deadline or check-in stop" "reference/loop-runtime.md" "keep the active ticket unchanged"
require_text "blocked active ticket deletes or omits pacing" "reference/loop-runtime.md" "active_ticket_blocked"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
