#!/usr/bin/env bash
# /superloop JIRA mission contract.
# Fails if the ticket pipeline loses a stage, the aidt-prd branch base, the
# deploy consent gate, DB/API evidence, or post-deploy side-effect verification.

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
echo " /superloop JIRA mission contract   skill: $ROOT"
echo "=================================================================="

require_file "mission-jira reference exists" "reference/mission-jira.md"

# Stage pipeline is complete and ordered.
for stage in FETCH ANALYZE BRANCH FIX TEST BUILD "DB-CHECK" "API-CHECK" "LOCAL-VERIFY" "DEPLOY-GATE" "POST-DEPLOY" CLOSE; do
  require_text "stage $stage present" "reference/mission-jira.md" "$stage"
done

# One ticket per tick.
require_text "one ticket per tick" "reference/mission-jira.md" "one ticket per tick"

# Branch discipline.
require_text "branch base is origin/aidt-prd" "reference/mission-jira.md" "origin/aidt-prd"
require_text "branch naming fix/{TICKET}" "reference/mission-jira.md" "fix/{TICKET}"
require_text "git runs inside the service submodule dir" "reference/mission-jira.md" "service directory"

# Fix discipline: failing test first.
require_text "reproduce with a failing test first" "reference/mission-jira.md" "failing test first"

# Evidence gates.
require_text "DB evidence is read-only via sql-check" "reference/mission-jira.md" "sql-check"
require_text "API check asserts response body, not just 200" "reference/mission-jira.md" "not just 200"
require_text "local verify uses /verify" "reference/mission-jira.md" "/verify"

# Deploy gate: Jenkins via aidt-dev merge, human consent, no skip.
require_text "deploy trigger is aidt-dev merge/push (Jenkins)" "reference/mission-jira.md" "Jenkins"
require_text "deploy requires explicit APPROVED" "reference/mission-jira.md" "APPROVED"
require_text "gate cannot be skipped by autonomy" "reference/mission-jira.md" "cannot be skipped"
require_text "awaiting-approval pauses the ticket, loop stays alive" "reference/mission-jira.md" "awaiting-approval"

# Post-deploy verification on the deployed env.
require_text "post-deploy uses qa-engineer" "reference/mission-jira.md" "qa-engineer"
require_text "post-deploy log sweep via grafana-loki-proxy" "reference/mission-jira.md" "grafana-loki-proxy"
require_text "side-effect sweep beyond the changed flow" "reference/mission-jira.md" "side-effect"

# Reuse over reinvention.
require_text "heavy pipeline can delegate to /jira-resolve" "reference/mission-jira.md" "jira-resolve"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
