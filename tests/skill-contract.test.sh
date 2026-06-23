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

# Loop contract: one declarative page per loop (trigger/scope/permissions/budget/stop/report/mode/owns).
require_file "loop-contract reference exists" "reference/loop-contract.md"
require_file "contract template exists" "templates/contract.md"
require_text "contract bootstrapped before the first tick" "SKILL.md" "loop-contract.md"
require_text "contract fields named" "SKILL.md" "permissions, budget, stop, report, mode, owns"

# Cumulative hard budget, beyond per-unit tick budget and consecutive-failure breaker.
require_text "cumulative budget ceiling rail" "SKILL.md" "Budget ceiling"
require_text "budget caps total ticks" "SKILL.md" "max_ticks"
require_text "budget forces periodic check-in" "SKILL.md" "checkin_every_n_ticks"

# Write missions isolate in a worktree, never the working branch directly.
require_file "worktree reference exists" "reference/worktree.md"
require_text "write missions isolate in a worktree" "SKILL.md" "isolate in a worktree"

# Progressive autonomy (start report-only) and single-writer ownership across concurrent loops.
require_text "loops can start report-only" "SKILL.md" "report-only"
require_text "single-writer ownership rail" "SKILL.md" "single-writer ownership"
require_text "ownership: one writer per resource" "reference/loop-contract.md" "one writer per resource"

# Escalation triggers beyond the failure counters.
require_text "escalation triggers enumerated" "SKILL.md" "Escalation triggers"
require_text "green signal can hide a wrong outcome" "SKILL.md" "page is wrong"

# Mission-specific named stop conditions (escalate at the first principled signal).
require_text "loop contract names semantic stops" "reference/loop-contract.md" "Named stop conditions"
require_text "jira names a product-decision stop" "reference/mission-jira.md" "merge_conflict_requires_product_decision"
require_text "qa names a green-but-wrong stop" "reference/mission-qa.md" "green_signal_wrong_outcome"
require_text "smells stops after one failed fix" "reference/mission-smells.md" "tests_fail_after_one_fix"

# Final checklist exists.
require_text "per-tick checklist present" "SKILL.md" "Per-tick checklist"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
