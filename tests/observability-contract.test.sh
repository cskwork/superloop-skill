#!/usr/bin/env bash
# /superloop observability (Board) contract.
# Fails if the live Board loses its files, its baseline-first invariant (best-effort, never gates,
# one-writer + atomic rename), or its default-recording wiring in SKILL.md.

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
echo " /superloop observability contract   skill: $ROOT"
echo "=================================================================="

# Board reader UI + producer files all present.
require_file "tui state reader exists" "tui/state.py"
require_file "tui app exists" "tui/app.py"
require_file "tui serve exists" "tui/serve.py"
require_file "tui launcher exists" "tui/launch.sh"
require_file "tui stylesheet exists" "tui/app.tcss"
require_file "heartbeat emitter exists" "templates/observability/sl-emit.sh"
require_file "heartbeat schema exists" "templates/observability/heartbeat.schema.json"
require_file "observability reference exists" "reference/observability.md"

# Baseline-first invariant: the Board never gates a run.
require_text "board is droppable / baseline-first" "reference/observability.md" "droppable"
require_text "no gate reads the heartbeat files" "reference/observability.md" "never a delivery gate"
require_text "one writer per file + atomic rename" "reference/observability.md" "one writer per file + atomic rename"

# Emitter is opt-in and best-effort, never aborts the tick.
require_text "emitter is opt-in via .enabled flag" "templates/observability/sl-emit.sh" ".enabled"
require_text "emitter is best-effort (exit 0 on failure)" "templates/observability/sl-emit.sh" "best-effort"
require_text "emitter self-derives identity from git" "templates/observability/sl-emit.sh" "self-derived"

# Heartbeat schema tracks superloop tick stages, not supergoal phases.
require_text "schema phase enum uses tick stages" "templates/observability/heartbeat.schema.json" "ORIENT"
require_text "schema run dir is SUPERLOOP" "templates/observability/heartbeat.schema.json" "SUPERLOOP_RUN_DIR"

# Launcher: terminal board is the default surface, web is opt-in.
require_text "terminal Textual board is the default" "tui/launch.sh" "terminal Textual board"
require_text "web board is opt-in via --web" "tui/launch.sh" "--web"
require_text "launcher enables emission for every mode" "tui/launch.sh" ".enabled"

# SKILL wires the Board as the default recording surface, emitted each tick.
require_text "SKILL: Board is the default recording surface" "SKILL.md" "default recording surface"
require_text "SKILL: tick emits a heartbeat, never gates" "SKILL.md" "never gates"
require_text "SKILL points at the observability reference" "SKILL.md" "observability.md"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
