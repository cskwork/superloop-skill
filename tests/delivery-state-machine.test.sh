#!/usr/bin/env bash
# Executable recovery proof for the deliver mission's durable state transitions.

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MACHINE="$ROOT/tests/fixtures/delivery-state-machine.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/superloop-delivery-state.XXXXXX")"
trap 'rm -rf -- "$WORK"' EXIT

assert_file() {
  [ -f "$1" ] || { printf 'FAIL missing file: %s\n' "$1" >&2; exit 1; }
}

assert_no_file() {
  [ ! -e "$1" ] || { printf 'FAIL unexpected file: %s\n' "$1" >&2; exit 1; }
}

assert_value() {
  local expected="$1" path="$2" actual
  actual="$(cat "$path")"
  [ "$actual" = "$expected" ] || {
    printf 'FAIL %s: expected <%s>, got <%s>\n' "$path" "$expected" "$actual" >&2
    exit 1
  }
}

assert_output() {
  local expected="$1"
  shift
  local actual
  actual="$(bash "$MACHINE" "$@")"
  [ "$actual" = "$expected" ] || {
    printf 'FAIL command output: expected <%s>, got <%s>\n' "$expected" "$actual" >&2
    exit 1
  }
}

assert_rejected() {
  if bash "$MACHINE" "$@" >/dev/null 2>&1; then
    printf 'FAIL command unexpectedly succeeded: %s\n' "$*" >&2
    exit 1
  fi
}

FIXED="$WORK/fixed"
LAUNCH='/loop 30m /superloop deliver LMS brief'
PAYLOAD='/superloop deliver LMS brief'

assert_output 'initialized:fixed' init "$FIXED" fixed "$LAUNCH" "$PAYLOAD" none
assert_value "$LAUNCH" "$FIXED/launch_prompt"
assert_value "$PAYLOAD" "$FIXED/scheduled_payload"
assert_value none "$FIXED/dynamic_reentry_prompt"
assert_rejected init "$WORK/bad-fixed" fixed "$LAUNCH" "$LAUNCH" none

DYNAMIC="$WORK/dynamic"
DYNAMIC_LAUNCH='/loop /superloop deliver LMS brief'
assert_output 'initialized:dynamic' init "$DYNAMIC" dynamic "$DYNAMIC_LAUNCH" "$PAYLOAD" "$DYNAMIC_LAUNCH"
assert_value "$PAYLOAD" "$DYNAMIC/scheduled_payload"
assert_value "$DYNAMIC_LAUNCH" "$DYNAMIC/dynamic_reentry_prompt"

# A process restart after claim publication reuses the same ticket/run instead of allocating another.
assert_output 'claimed:T-001:run-T-001' claim "$FIXED" T-001
assert_output 'resume:T-001:claimed:run-T-001' claim "$FIXED" T-001
assert_value run-T-001 "$FIXED/active/run_id"
assert_rejected claim "$FIXED" T-002

assert_output 'running:T-001' start "$FIXED"
assert_output 'inner-verified:T-001' inner-complete "$FIXED"
assert_output 'resume-inner-verified:T-001:run-T-001' resume "$FIXED"
assert_file "$FIXED/provisional-evidence"
assert_no_file "$FIXED/close-manifest"

assert_output 'integration-pending:T-001' prepare-integration "$FIXED"
assert_rejected finalize-close "$FIXED"
assert_no_file "$FIXED/close-manifest"

assert_output 'integration-observed:T-001:target-abc123' record-receipt "$FIXED" target-abc123
assert_output 'integration-replayed:T-001:target-abc123' record-receipt "$FIXED" target-abc123
assert_file "$FIXED/integration-receipt"
assert_no_file "$FIXED/close-manifest"

# A crash before the atomic rename cannot publish a partial immutable final manifest.
assert_rejected failpoint-before-final-rename "$FIXED"
assert_no_file "$FIXED/close-manifest"
assert_output 'integrated:T-001:target-abc123' finalize-close "$FIXED"
assert_file "$FIXED/close-manifest"
assert_no_file "$FIXED/active"
assert_value target-abc123 "$FIXED/integration-receipt"

# Three failures preserve the active ticket but durably stop all future pacing and sibling claims.
BLOCKED="$WORK/blocked"
assert_output 'initialized:fixed' init "$BLOCKED" fixed "$LAUNCH" "$PAYLOAD" none
assert_output 'claimed:T-009:run-T-009' claim "$BLOCKED" T-009
assert_output "paced:$PAYLOAD" arm-pacing "$BLOCKED"
assert_output 'retry:T-009:1' fail "$BLOCKED" first
assert_output 'retry:T-009:2' fail "$BLOCKED" second
assert_output 'stop:active_ticket_blocked:T-009:3' fail "$BLOCKED" third
assert_value T-009 "$BLOCKED/active/ticket_id"
assert_value blocked "$BLOCKED/active/phase"
assert_value active_ticket_blocked "$BLOCKED/stop_reason"
assert_no_file "$BLOCKED/pacing.intent"
assert_output 'stop:active_ticket_blocked:T-009' resume "$BLOCKED"
assert_rejected arm-pacing "$BLOCKED"
assert_rejected claim "$BLOCKED" T-010

printf 'PASS delivery state-machine crash recovery\n'
