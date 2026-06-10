#!/usr/bin/env bash
# /superloop core contract.
# Fails if the skill loses its mission table, tick anatomy, one-unit-per-tick rule,
# durable ledger, supergoal delegation, or autonomous safety rails.

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
echo " /superloop core contract   skill: $ROOT"
echo "=================================================================="

# Frontmatter and discovery.
require_file "SKILL.md exists" "SKILL.md"
require_text "frontmatter name is superloop" "SKILL.md" "name: superloop"
require_text "description starts with Use when" "SKILL.md" "description: Use when"

# Mission table covers the four built-in missions.
require_text "mission DOCS in table" "SKILL.md" "mission-docs.md"
require_text "mission SMELLS in table" "SKILL.md" "mission-smells.md"
require_text "mission QA in table" "SKILL.md" "mission-qa.md"
require_text "mission JIRA in table" "SKILL.md" "mission-jira.md"

# Tick anatomy is the spine of every iteration.
require_text "tick anatomy ORIENT" "SKILL.md" "ORIENT"
require_text "tick anatomy PICK" "SKILL.md" "PICK"
require_text "tick anatomy EXECUTE" "SKILL.md" "EXECUTE"
require_text "tick anatomy VERIFY" "SKILL.md" "VERIFY"
require_text "tick anatomy RECORD" "SKILL.md" "RECORD"
require_text "tick anatomy PACE" "SKILL.md" "PACE"

# One smallest unit of work per tick - never batch.
require_text "one unit of work per tick" "SKILL.md" "one unit of work per tick"

# Durable state ledger so ticks are idempotent across compaction.
require_text "ledger path under .superloop/" "SKILL.md" ".superloop/<mission>/ledger.md"
require_file "ledger reference exists" "reference/state-ledger.md"
require_file "ledger template exists" "templates/ledger.md"

# Execution discipline delegates to supergoal, not a parallel invention.
require_text "EXECUTE delegates to supergoal" "SKILL.md" "supergoal"

# Autonomous safety rails.
require_text "consecutive-failure circuit breaker" "SKILL.md" "consecutive failed ticks"
require_text "destructive/outward steps need consent" "SKILL.md" "explicit consent"
require_text "nothing-to-do backs off, never invents work" "SKILL.md" "never invent work"

# Final checklist exists.
require_text "per-tick checklist present" "SKILL.md" "Per-tick checklist"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
