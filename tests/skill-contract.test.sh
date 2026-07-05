#!/usr/bin/env bash
# /superloop core contract - the single verify mission.
# Fails if the skill loses its verify identity, tick anatomy, one-criterion-per-tick rule,
# durable ledger, supergoal delegation, orchestrator handoff, convergence stops, or safety rails.

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
require_text "description names the orchestrator-delivery use case" "SKILL.md" "orchestrator"

# The single mission is verify: hold a delivery to its intent.
require_text "verify mission referenced" "SKILL.md" "reference/mission-verify.md"
require_file "verify mission reference exists" "reference/mission-verify.md"
require_text "unit-queue is acceptance criteria" "SKILL.md" "acceptance criteria"
require_text "criteria derive from an Intent Spec" "SKILL.md" "Intent Spec"

# Tick anatomy is the spine of every iteration.
require_text "tick anatomy ORIENT" "SKILL.md" "ORIENT"
require_text "tick anatomy PICK" "SKILL.md" "PICK"
require_text "tick anatomy EXECUTE" "SKILL.md" "EXECUTE"
require_text "tick anatomy VERIFY" "SKILL.md" "VERIFY"
require_text "tick anatomy RECORD" "SKILL.md" "RECORD"
require_text "tick anatomy PACE" "SKILL.md" "PACE"

# One smallest criterion per tick - never batch.
require_text "one unit of work per tick" "SKILL.md" "one unit of work per tick"
require_text "one criterion per tick" "SKILL.md" "One criterion per tick"

# Durable state ledger so ticks are idempotent across compaction.
require_text "ledger path under .superloop/verify" "SKILL.md" ".superloop/verify/ledger.md"
require_file "ledger reference exists" "reference/state-ledger.md"
require_file "ledger template exists" "templates/ledger.md"
require_text "ledger queue holds acceptance criteria" "reference/state-ledger.md" "acceptance criteria"

# Verify against the intent/spec, not merely the shipped tests.
require_text "intent is ground truth, not the tests" "SKILL.md" "not merely the existing tests"
require_text "a green signal can hide a wrong outcome" "SKILL.md" "green_signal_wrong_outcome"
require_text "verify mission names the green-but-wrong stop" "reference/mission-verify.md" "green_signal_wrong_outcome"

# Direct, don't do: a failed criterion becomes a fix directive to the orchestrator.
require_text "failed criterion becomes a fix directive" "SKILL.md" "fix directive"
require_file "orchestrator handoff reference exists" "reference/orchestrator-handoff.md"
require_text "handoff referenced from SKILL" "SKILL.md" "reference/orchestrator-handoff.md"
require_text "fix directive is evidence-backed" "reference/orchestrator-handoff.md" "fix directive"
require_text "execution discipline delegates to supergoal" "SKILL.md" "supergoal"
require_text "fixes isolate in a dedicated worktree" "SKILL.md" "dedicated worktree"
require_text "fixes never touch the working branch directly" "SKILL.md" "never the working branch"

# Convergence - the completion promise.
require_text "success stop is all_criteria_proven" "SKILL.md" "all_criteria_proven"
require_text "escalation stop is orchestrator_cannot_close_gap" "SKILL.md" "orchestrator_cannot_close_gap"
require_text "never fabricate the completion promise" "SKILL.md" "never fabricate the completion promise"

# Prompting insights - run the loop the operator's way.
require_file "prompting-insights reference exists" "reference/prompting-insights.md"
require_text "prompting-insights referenced from SKILL" "SKILL.md" "reference/prompting-insights.md"
require_text "insights: evidence over vibes" "reference/prompting-insights.md" "Evidence over vibes"
require_text "insights: ground truth is the spec, not the tests" "reference/prompting-insights.md" "not the tests"

# Intent Spec template - the first-tick capture.
require_file "intent-spec template exists" "templates/intent-spec.md"
require_text "intent-spec referenced from SKILL" "SKILL.md" "templates/intent-spec.md"
require_text "intent-spec captures acceptance criteria" "templates/intent-spec.md" "Acceptance criteria"

# Loop contract: one declarative page per loop (trigger/scope/permissions/budget/stop/report/mode/owns).
require_file "loop-contract reference exists" "reference/loop-contract.md"
require_file "contract template exists" "templates/contract.md"
require_text "contract bootstrapped before the first tick" "SKILL.md" "reference/loop-contract.md"
require_text "contract fields named" "SKILL.md" "permissions, budget, stop, report, mode, owns"
require_text "contract template carries the delivered intent" "templates/contract.md" "intent"
require_text "loop-contract names the convergence stop" "reference/loop-contract.md" "all_criteria_proven"

# Cumulative hard budget, beyond per-unit tick budget and consecutive-failure breaker.
require_text "cumulative budget ceiling rail" "SKILL.md" "Budget ceiling"
require_text "budget caps total ticks" "SKILL.md" "max_ticks"
require_text "budget forces periodic check-in" "SKILL.md" "checkin_every_n_ticks"

# Autonomous safety rails.
require_text "consecutive-failure circuit breaker" "SKILL.md" "consecutive failed ticks"
require_text "destructive/outward steps need consent" "SKILL.md" "explicit consent"
require_text "nothing-to-do backs off, never invents work" "SKILL.md" "never invent work"

# Write-side isolation in a worktree.
require_file "worktree reference exists" "reference/worktree.md"

# Progressive autonomy (start report-only) and single-writer ownership across concurrent loops.
require_text "loops can start report-only" "SKILL.md" "report-only"
require_text "single-writer ownership rail" "SKILL.md" "single-writer ownership"
require_text "ownership: one writer per resource" "reference/loop-contract.md" "one writer per resource"

# Escalation triggers beyond the failure counters.
require_text "escalation triggers enumerated" "SKILL.md" "Escalation triggers"
require_text "green signal can hide a wrong outcome" "SKILL.md" "page is wrong"

# Fix-side named stop conditions (escalate at the first principled signal), now homed in the handoff.
require_text "handoff stops after one failed fix" "reference/orchestrator-handoff.md" "tests_fail_after_one_fix"
require_text "handoff names a product-decision stop" "reference/orchestrator-handoff.md" "merge_conflict_requires_product_decision"
require_text "handoff names the cannot-close-gap stop" "reference/orchestrator-handoff.md" "orchestrator_cannot_close_gap"

# Lineage - Codex routines and Ralph's completion-promise.
require_text "lineage cites Codex routines" "SKILL.md" "Codex"
require_text "lineage cites Ralph completion-promise" "SKILL.md" "Ralph"

# Final checklist exists.
require_text "per-tick checklist present" "SKILL.md" "Per-tick checklist"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
