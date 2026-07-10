#!/usr/bin/env bash
# Minimal executable model of the durable deliver transitions documented by the skill.

set -eu

die() {
  printf 'ERROR %s\n' "$1" >&2
  exit 1
}

write_atomic() {
  local path="$1" value="$2" tmp="${1}.tmp.$$"
  printf '%s\n' "$value" > "$tmp"
  mv "$tmp" "$path"
}

read_value() {
  [ -f "$1" ] || die "missing durable state: $1"
  cat "$1"
}

require_state() {
  [ -d "$1" ] || die "state is not initialized: $1"
  [ -f "$1/mode" ] || die "state is incomplete: $1"
}

require_active() {
  require_state "$1"
  [ -d "$1/active" ] || die "no active ticket"
}

ensure_running() {
  local state="$1"
  [ ! -f "$state/stop_reason" ] || die "durable stop: $(cat "$state/stop_reason")"
}

command_init() {
  local state="$1" mode="$2" launch="$3" payload="$4" dynamic="$5"
  case "$payload" in
    '/superloop deliver'|'/superloop deliver '*) ;;
    *) die "scheduled_payload must be the parsed /superloop deliver payload" ;;
  esac
  case "$payload" in '/loop'*) die "scheduled_payload must never be the original /loop invocation" ;; esac
  case "$mode" in
    fixed) [ "$dynamic" = none ] || die "fixed mode has no dynamic re-entry prompt" ;;
    dynamic)
      case "$dynamic" in '/loop '*) ;; *) die "dynamic_reentry_prompt must re-enter /loop" ;; esac
      [ "$dynamic" = "$launch" ] || die "dynamic re-entry must preserve the launch prompt"
      ;;
    *) die "unknown mode: $mode" ;;
  esac
  mkdir -p "$state"
  write_atomic "$state/mode" "$mode"
  write_atomic "$state/launch_prompt" "$launch"
  write_atomic "$state/scheduled_payload" "$payload"
  write_atomic "$state/dynamic_reentry_prompt" "$dynamic"
  printf 'initialized:%s\n' "$mode"
}

command_claim() {
  local state="$1" ticket="$2" current phase run tmp
  require_state "$state"
  ensure_running "$state"
  if [ -d "$state/active" ]; then
    current="$(read_value "$state/active/ticket_id")"
    [ "$current" = "$ticket" ] || die "another ticket is active: $current"
    phase="$(read_value "$state/active/phase")"
    run="$(read_value "$state/active/run_id")"
    printf 'resume:%s:%s:%s\n' "$ticket" "$phase" "$run"
    return
  fi
  run="run-$ticket"
  tmp="$state/.active.tmp.$$"
  mkdir "$tmp"
  printf '%s\n' "$ticket" > "$tmp/ticket_id"
  printf '%s\n' "$run" > "$tmp/run_id"
  printf '%s\n' "close-$ticket-$run" > "$tmp/close_key"
  printf 'claimed\n' > "$tmp/phase"
  printf '0\n' > "$tmp/failure_count"
  mv "$tmp" "$state/active"
  printf 'claimed:%s:%s\n' "$ticket" "$run"
}

command_start() {
  local state="$1" ticket phase
  require_active "$state"
  ensure_running "$state"
  ticket="$(read_value "$state/active/ticket_id")"
  phase="$(read_value "$state/active/phase")"
  case "$phase" in claimed|running) ;; *) die "cannot start from phase: $phase" ;; esac
  write_atomic "$state/active/phase" running
  printf 'running:%s\n' "$ticket"
}

command_inner_complete() {
  local state="$1" ticket run phase
  require_active "$state"
  ensure_running "$state"
  ticket="$(read_value "$state/active/ticket_id")"
  run="$(read_value "$state/active/run_id")"
  phase="$(read_value "$state/active/phase")"
  case "$phase" in running|inner-verified) ;; *) die "inner evidence is invalid in phase: $phase" ;; esac
  write_atomic "$state/provisional-evidence" "ticket=$ticket run=$run inner=verified"
  write_atomic "$state/active/phase" inner-verified
  printf 'inner-verified:%s\n' "$ticket"
}

command_resume() {
  local state="$1" ticket run phase stop
  require_active "$state"
  ticket="$(read_value "$state/active/ticket_id")"
  run="$(read_value "$state/active/run_id")"
  if [ -f "$state/stop_reason" ]; then
    stop="$(read_value "$state/stop_reason")"
    printf 'stop:%s:%s\n' "$stop" "$ticket"
    return
  fi
  phase="$(read_value "$state/active/phase")"
  case "$phase" in
    claimed) printf 'dispatch:%s:%s\n' "$ticket" "$run" ;;
    running) printf 'resume-running:%s:%s\n' "$ticket" "$run" ;;
    inner-verified) printf 'resume-inner-verified:%s:%s\n' "$ticket" "$run" ;;
    integration-pending) printf 'probe-integration:%s:%s\n' "$ticket" "$run" ;;
    integration-observed) printf 'finalize-close:%s:%s\n' "$ticket" "$run" ;;
    blocked) printf 'stop:active_ticket_blocked:%s\n' "$ticket" ;;
    *) die "unknown active phase: $phase" ;;
  esac
}

command_prepare_integration() {
  local state="$1" ticket phase
  require_active "$state"
  ensure_running "$state"
  ticket="$(read_value "$state/active/ticket_id")"
  phase="$(read_value "$state/active/phase")"
  case "$phase" in inner-verified|integration-pending) ;; *) die "cannot prepare integration from phase: $phase" ;; esac
  [ -f "$state/provisional-evidence" ] || die "inner evidence bundle is missing"
  write_atomic "$state/active/phase" integration-pending
  printf 'integration-pending:%s\n' "$ticket"
}

command_record_receipt() {
  local state="$1" receipt="$2" ticket phase existing
  require_active "$state"
  ensure_running "$state"
  ticket="$(read_value "$state/active/ticket_id")"
  phase="$(read_value "$state/active/phase")"
  case "$phase" in integration-pending|integration-observed) ;; *) die "receipt is invalid in phase: $phase" ;; esac
  if [ -f "$state/integration-receipt" ]; then
    existing="$(read_value "$state/integration-receipt")"
    [ "$existing" = "$receipt" ] || die "integration receipt changed"
    write_atomic "$state/active/phase" integration-observed
    printf 'integration-replayed:%s:%s\n' "$ticket" "$receipt"
    return
  fi
  write_atomic "$state/integration-receipt" "$receipt"
  write_atomic "$state/active/phase" integration-observed
  printf 'integration-observed:%s:%s\n' "$ticket" "$receipt"
}

command_finalize_close() {
  local state="$1" failpoint="${2:-}" ticket run close_key receipt phase tmp
  require_active "$state"
  ensure_running "$state"
  ticket="$(read_value "$state/active/ticket_id")"
  run="$(read_value "$state/active/run_id")"
  close_key="$(read_value "$state/active/close_key")"
  phase="$(read_value "$state/active/phase")"
  [ "$phase" = integration-observed ] || die "final close requires integration-observed"
  receipt="$(read_value "$state/integration-receipt")"
  [ -f "$state/provisional-evidence" ] || die "provisional evidence is missing"
  tmp="$state/.close-manifest.tmp"
  printf 'ticket=%s\nrun=%s\nclose_key=%s\nintegration_receipt=%s\n' \
    "$ticket" "$run" "$close_key" "$receipt" > "$tmp"
  [ "$failpoint" != before-rename ] || die "simulated crash before final manifest rename"
  mv "$tmp" "$state/close-manifest"
  write_atomic "$state/active/phase" integrated
  mv "$state/active" "$state/closed-active"
  printf 'integrated:%s:%s\n' "$ticket" "$receipt"
}

command_arm_pacing() {
  local state="$1" mode prompt
  require_state "$state"
  ensure_running "$state"
  mode="$(read_value "$state/mode")"
  if [ "$mode" = fixed ]; then
    prompt="$(read_value "$state/scheduled_payload")"
  else
    prompt="$(read_value "$state/dynamic_reentry_prompt")"
  fi
  [ "$prompt" != none ] || die "no pacing prompt for mode: $mode"
  write_atomic "$state/pacing.intent" "$prompt"
  printf 'paced:%s\n' "$prompt"
}

command_fail() {
  local state="$1" reason="$2" ticket count
  require_active "$state"
  ensure_running "$state"
  ticket="$(read_value "$state/active/ticket_id")"
  count=$(( $(read_value "$state/active/failure_count") + 1 ))
  write_atomic "$state/active/failure_count" "$count"
  write_atomic "$state/active/failure-$count" "$reason"
  if [ "$count" -lt 3 ]; then
    printf 'retry:%s:%s\n' "$ticket" "$count"
    return
  fi
  write_atomic "$state/active/phase" blocked
  write_atomic "$state/stop_reason" active_ticket_blocked
  [ ! -f "$state/pacing.intent" ] || mv "$state/pacing.intent" "$state/pacing.cancelled"
  printf 'stop:active_ticket_blocked:%s:%s\n' "$ticket" "$count"
}

command="${1:-}"
case "$command" in
  init) [ "$#" -eq 6 ] || die "usage: init STATE MODE LAUNCH PAYLOAD DYNAMIC"; command_init "$2" "$3" "$4" "$5" "$6" ;;
  claim) [ "$#" -eq 3 ] || die "usage: claim STATE TICKET"; command_claim "$2" "$3" ;;
  start) [ "$#" -eq 2 ] || die "usage: start STATE"; command_start "$2" ;;
  inner-complete) [ "$#" -eq 2 ] || die "usage: inner-complete STATE"; command_inner_complete "$2" ;;
  resume) [ "$#" -eq 2 ] || die "usage: resume STATE"; command_resume "$2" ;;
  prepare-integration) [ "$#" -eq 2 ] || die "usage: prepare-integration STATE"; command_prepare_integration "$2" ;;
  record-receipt) [ "$#" -eq 3 ] || die "usage: record-receipt STATE RECEIPT"; command_record_receipt "$2" "$3" ;;
  finalize-close) [ "$#" -eq 2 ] || die "usage: finalize-close STATE"; command_finalize_close "$2" ;;
  failpoint-before-final-rename) [ "$#" -eq 2 ] || die "usage: failpoint-before-final-rename STATE"; command_finalize_close "$2" before-rename ;;
  arm-pacing) [ "$#" -eq 2 ] || die "usage: arm-pacing STATE"; command_arm_pacing "$2" ;;
  fail) [ "$#" -eq 3 ] || die "usage: fail STATE REASON"; command_fail "$2" "$3" ;;
  *) die "unknown command: ${command:-<empty>}" ;;
esac
