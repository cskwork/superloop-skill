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

# Dynamic mode.
require_text "dynamic re-entry prompt keeps /loop prefix" "reference/loop-runtime.md" 'prefixed with `/loop `'
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

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
