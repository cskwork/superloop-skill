#!/usr/bin/env bash
# /superloop deliver contract.
# Fails if scheduled project delivery loses its INIT/TICK split, durable frontier,
# single-ticket lease, installed-supergoal handoff, exact close evidence, or safe stops.

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
echo " /superloop deliver contract   skill: $ROOT"
echo "=================================================================="

# Backward-compatible routing: verify keeps its criterion unit; deliver owns feature tickets.
require_text "verify route remains available" "SKILL.md" "/superloop verify"
require_text "deliver route is discoverable" "SKILL.md" "/superloop deliver <project-brief>"
require_text "deliver mission referenced" "SKILL.md" "reference/mission-deliver.md"
require_file "deliver mission reference exists" "reference/mission-deliver.md"
require_file "supergoal handoff reference exists" "reference/supergoal-handoff.md"
require_file "delivery ledger template exists" "templates/delivery-ledger.md"
require_file "executable delivery recovery fixture exists" "tests/fixtures/delivery-state-machine.sh"
require_file "delivery recovery scenario exists" "tests/delivery-state-machine.test.sh"

# INIT is a once-only bootstrap; later TICKs reconstruct solely from durable project state.
require_text "INIT is explicitly once-only" "reference/mission-deliver.md" "INIT - bootstrap once"
require_text "TICK is a scheduled re-entry" "reference/mission-deliver.md" "TICK - every scheduled re-entry"
require_text "root project brief is frozen" "reference/mission-deliver.md" "root project brief"
require_text "durable root goal is distinct from the brief" "reference/mission-deliver.md" "root-goal.md"
require_text "frontier map is durable" "reference/mission-deliver.md" "wayfinder/map.md"
require_text "vertical tickets are durable" "reference/mission-deliver.md" "wayfinder/tickets/"
require_text "delivery ledger path is mission-specific" "SKILL.md" ".superloop/deliver/ledger.md"
require_text "chat history is not state" "reference/mission-deliver.md" "Do not use chat history"
require_text "disk is the cross-tick authority" "reference/state-ledger.md" "only cross-tick memory"

# One active vertical ticket is resumed first and protected by an atomic single-writer lease.
require_text "one active ticket invariant" "reference/mission-deliver.md" "exactly one active ticket"
require_text "active ticket resumes before a sibling" "reference/mission-deliver.md" "resume the active ticket before claiming"
require_text "lease acquisition uses atomic mkdir" "reference/mission-deliver.md" "mkdir .superloop/deliver/lease"
require_text "held lease fails closed" "reference/mission-deliver.md" "fail closed"
require_text "lease releases on every exit" "reference/mission-deliver.md" "release the lease on every exit"
require_text "stale lease age alone cannot authorize recovery" "reference/mission-deliver.md" "Never break a lease merely because it is old"
require_text "stale lease recovery is contract-bound" "templates/contract.md" "lease_recovery_rule"
require_text "claim is atomically published before dispatch" "reference/mission-deliver.md" "atomic rename before dispatch"
require_text "claim is reread before dispatch" "reference/mission-deliver.md" "re-read the committed active-ticket record"
require_text "claimed run resumes after pre-dispatch crash" "reference/mission-deliver.md" "claimed-but-not-started"
require_text "ledger records the active ticket" "templates/delivery-ledger.md" "## Active ticket"
require_text "ledger records active ticket id" "templates/delivery-ledger.md" "ticket id:"
require_text "ledger records active ticket digest" "templates/delivery-ledger.md" "ticket spec digest:"
require_text "ledger records one inner run id" "templates/delivery-ledger.md" "supergoal run id:"
require_text "ledger records recoverable active phase" "templates/delivery-ledger.md" "phase:"
require_text "ledger records immutable close key" "templates/delivery-ledger.md" "close idempotency key:"
require_text "active ticket contract is frozen" "reference/mission-deliver.md" "freeze the active ticket"
require_text "skill changes become maintenance tickets" "reference/mission-deliver.md" "maintenance ticket"

# The outer loop delegates the full inner workflow and trusts exact artifacts, never a summary.
require_text "installed supergoal is required" "reference/supergoal-handoff.md" "installed supergoal"
require_text "full supergoal role-loop is named" "reference/supergoal-handoff.md" "Build -> Improve full spec -> Improve edge cases -> Mandatory Adversarial Review -> Exact Verify/QA"
require_text "outer loop does not clone supergoal" "reference/supergoal-handoff.md" "do not reimplement"
require_text "each ticket starts in fresh context" "reference/supergoal-handoff.md" "fresh top-level ticket context"
require_text "handoff carries the root contract" "reference/supergoal-handoff.md" "root contract"
require_text "handoff carries the durable root goal" "reference/supergoal-handoff.md" "root goal path and digest"
require_text "handoff carries source ref" "reference/supergoal-handoff.md" "source_ref"
require_text "handoff carries target ref" "reference/supergoal-handoff.md" "target_ref"
require_text "GOAL is exact close evidence" "reference/supergoal-handoff.md" "GOAL.md"
require_text "QA is exact close evidence" "reference/supergoal-handoff.md" "QA.md"
require_text "run-state is exact close evidence" "reference/supergoal-handoff.md" "run-state.json"
require_text "DONE marker is exact close evidence" "reference/supergoal-handoff.md" "Z-<YYYY-MM-DD>.md"
require_text "commit gate is exact close evidence" "reference/supergoal-handoff.md" "commit gate"
require_text "integration proof is exact close evidence" "reference/supergoal-handoff.md" "integration proof"
require_text "agent summaries cannot close tickets" "reference/supergoal-handoff.md" "summary is not completion evidence"
require_text "close artifacts bind to one run" "reference/supergoal-handoff.md" "same active ticket, run id, run branch, and verified revision"
require_text "stale commit-gate proof is rejected" "reference/supergoal-handoff.md" "commit-gate proof is stale"
require_text "completed inner run is not redispatched" "reference/mission-deliver.md" "skip EXECUTE and continue at VERIFY"
require_text "supergoal upgrades cannot change an active run" "reference/supergoal-handoff.md" "supergoal_contract_changed"
require_text "ticket digest drift fails closed" "reference/mission-deliver.md" "ticket_spec_mismatch"
require_text "dirty ref or worktree drift fails closed" "reference/mission-deliver.md" "ref_or_worktree_drift"
require_text "dirty worktrees are never destructively cleaned" "reference/mission-deliver.md" "never clean, reset, or overwrite"

# RECORD updates the frontier only after exact close, and PACE stops cleanly at bounds.
require_text "frontier recomputed after close" "reference/mission-deliver.md" "recompute the frontier"
require_text "one ticket boundary survives close" "reference/mission-deliver.md" "Do not start a sibling ticket in the same tick"
require_text "delivery success stop is named" "reference/mission-deliver.md" "all_tickets_integrated"
require_text "blocked frontier stop is named" "reference/mission-deliver.md" "frontier_blocked"
require_text "deadline stop is named" "reference/mission-deliver.md" "deadline_reached"
require_text "deadline preserves an active ticket" "reference/mission-deliver.md" "deadline reached while a ticket is active"
require_text "check-in preserves an active ticket" "reference/mission-deliver.md" "check-in is due while a ticket is active"
require_text "consent-gated integration preserves active ticket" "reference/mission-deliver.md" "integration_requires_approval"
require_text "scheduler disappearance is a named stop" "reference/mission-deliver.md" "scheduler_job_missing"
require_text "close replay checks target before repeating integration" "reference/mission-deliver.md" "before repeating any integration action"
require_text "non-idempotent integration requires a receipt" "reference/mission-deliver.md" "integration receipt"
require_text "active-ticket breaker is a named durable stop" "reference/mission-deliver.md" "active_ticket_blocked"
require_text "blocked stop preserves the active ticket" "reference/mission-deliver.md" "preserve the active ticket"
require_text "blocked stop removes fixed pacing" "reference/mission-deliver.md" "CronDelete"
require_text "blocked stop omits dynamic pacing" "reference/mission-deliver.md" "omit ScheduleWakeup"
require_text "pre-integration evidence is provisional" "reference/mission-deliver.md" "provisional evidence bundle"
require_text "final close waits for durable integration proof" "reference/mission-deliver.md" "only after the durable integration receipt"
require_text "final close is atomically published" "reference/mission-deliver.md" "atomically rename it to the immutable final close manifest"

# Root delivery contracts and ledgers carry the fields a fresh scheduler tick must recover.
require_text "contract has project brief" "templates/contract.md" "project_brief"
require_text "contract has root goal" "templates/contract.md" "root_goal"
require_text "contract has source ref" "templates/contract.md" "source_ref"
require_text "contract has target ref" "templates/contract.md" "target_ref"
require_text "contract has integration proof" "templates/contract.md" "integration_proof"
require_text "contract has deadline or duration" "templates/contract.md" "deadline_or_duration"
require_text "contract has scheduler job id" "templates/contract.md" "scheduler_job_id"
require_text "contract records the original launch for audit only" "templates/contract.md" "launch_prompt"
require_text "contract records the parsed scheduled payload" "templates/contract.md" "scheduled_payload"
require_text "contract records dynamic-only re-entry" "templates/contract.md" "dynamic_reentry_prompt"
require_text "contract records local preauthorization" "templates/contract.md" "preauthorized_local_actions"
require_text "ledger records root goal digest" "templates/delivery-ledger.md" "root goal digest"
require_text "ledger records an absolute deadline" "templates/delivery-ledger.md" "deadline_at"
require_text "ledger records frontier" "templates/delivery-ledger.md" "## Frontier"
require_text "ledger records ticket runs" "templates/delivery-ledger.md" "## Ticket runs"
require_text "ledger records scheduler state" "templates/delivery-ledger.md" "scheduler_job_id"
require_text "ledger separates launch from fixed payload" "templates/delivery-ledger.md" "scheduled_payload"
require_text "ledger separates dynamic re-entry" "templates/delivery-ledger.md" "dynamic_reentry_prompt"
require_text "ledger records scheduler reconciliation" "templates/delivery-ledger.md" "scheduler status:"
require_text "ledger binds resolved ref commits" "templates/delivery-ledger.md" "source commit / target base commit:"
require_text "ledger freezes supergoal commit gate" "templates/delivery-ledger.md" "commit-gate path / digest:"

printf '\nSummary: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
