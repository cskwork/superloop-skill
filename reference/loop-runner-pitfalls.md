# Loop runner pitfalls - shell bugs that silently drop work

When you build your **own** dispatcher (a shell script that walks a work queue and shells out to
`claude -p` or another agent per unit) instead of driving the built-in `/loop`, three bugs recur.
All three share one nasty property: **the happy path and the dry-run both look correct**. They only
bite when the real child runs, a unit gates, or the backend is briefly flaky - so a runner that
only ever proves the happy path proves almost nothing about whether it drops work.

## 1. The child process drains the dispatch loop's stdin

```sh
while IFS= read -r unit; do
  run_agent "$unit"        # claude -p, ssh, ffmpeg - anything that reads stdin
done < <(produce_units)
```

If `run_agent` reads stdin, it consumes the **remaining lines of `produce_units`** from the shared
pipe. Result: only the first unit runs; every later unit vanishes with no error and exit 0. A
dry-run that prints commands instead of spawning the child can't reproduce it.

Fix - close the child's stdin (a headless agent should never read stdin anyway):

```sh
run_agent "$unit" </dev/null
# or give the loop its own fd so the body can't touch it:
while IFS= read -r unit <&3; do run_agent "$unit"; done 3< <(produce_units)
```

## 2. One unit's gate or error aborts the whole queue

If a unit needs human approval (a gate) or fails, do **not** `return`/`exit` from the dispatch loop
- that silently drops every remaining unit. A gate halts *that* unit, not the board. Continue the
loop; record the gate/failure and surface it through the exit code.

```sh
had_error=0
while IFS= read -r unit; do
  rc=0; run_unit "$unit" || rc=$?
  # GATE_RC is the "needs human approval" sentinel; treat it as an expected stop, not a failure.
  if [ "$rc" -ne 0 ] && [ "$rc" -ne "$GATE_RC" ]; then
    printf 'unit %s failed (rc=%s); continuing\n' "$unit" "$rc" >&2
    had_error=1
  fi
done < <(produce_units)
[ "$had_error" -eq 0 ] || exit 1
```

This is the runner-level mirror of superloop's "mark `awaiting-approval` and move on" rail: one
blocked unit must never stall the rest of the queue.

## 3. `set -e` is silently OFF inside `func || rc=$?`, so a failed step retries forever

Bash disables `set -e` inside **any function invoked as part of a condition** - including the common
`run_unit "$x" || rc=$?`. So a step that `die`s deep inside that function does **not** abort the
script. If the per-step loop re-derives "next step" from on-disk state and the failed step was never
marked done, it picks the **same step again** - an unbounded, no-backoff retry that can spin a paid
agent forever.

```sh
# main: set -e is OFF inside run_unit because of the `|| rc=$?`
run_unit "$file" || rc=$?

# run_unit: failed step left unmarked -> next_step() returns the same step -> infinite loop
"$RUNNER" --step "$step" ...        # dies on a transient 5xx, but the loop just comes back around
```

Fix - make step failure explicit, and make retries bounded and transient-only:

```sh
"$RUNNER" --step "$step" ... || return 1     # abort this unit; never silently re-loop

# inside the runner, retry only transient gateway errors, capped + backed off:
attempt=1
while :; do
  out=$("$AGENT" ... </dev/null) && break
  if printf '%s' "$out" | grep -qE '"api_error_status":(5[0-9][0-9]|429)' \
     && [ "$attempt" -lt "${MAX_ATTEMPTS:-3}" ]; then
    sleep $((attempt * 5)); attempt=$((attempt + 1)); continue
  fi
  die "step failed after $attempt attempt(s)"     # fail fast on timeouts/other - never spin
done
```

Retry only transient signals (HTTP 5xx / 429). Fail fast on a timeout, so a genuinely stuck step
can't burn attempts in a loop.

## Verify the failure paths cheaply (no agent spend)

The happy path is not evidence. Test each pitfall directly - all three are free and deterministic:

- **stdin drain**: `while read x; do echo "$x"; cat >/dev/null; done < <(printf 'a\nb\nc\n')` prints
  only `a`. Add `</dev/null` to the inner command and all three print.
- **gate/error blocks queue**: drive the dispatcher in dry-run with one unit pre-set to "gated";
  assert the later units still appear in the output.
- **unbounded retry**: stub the agent binary with a script on `PATH` that emits a fake 5xx and exits
  non-zero; assert the runner retries `MAX_ATTEMPTS` then stops in bounded wall-clock, and that a
  stub which fails N-1 times then succeeds recovers. A fake binary exercises the real retry path for
  $0.

## Why they hide

Pitfall 1 needs the real child to run; 2 needs a unit to gate or fail; 3 needs the backend to be
briefly flaky. None of those happen in a dry-run or a clean happy-path run. Build the failure-path
tests first - they are the only ones that tell you whether the loop quietly drops work.
