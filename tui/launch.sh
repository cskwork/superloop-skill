#!/usr/bin/env sh
# Launch the superloop Board - the default recording surface for a loop. Best-effort, never gates.
#
# Two surfaces:
#   bash tui/launch.sh           # terminal Textual board (default) - the "own terminal live board"
#   bash tui/launch.sh --web     # browser board via textual-serve (multi-viewer)
#
# Either way it first ENABLES emission ($REGDIR/.enabled) so sl-emit starts recording heartbeats,
# even when no UI can render here. The ledger remains the durable record; this board is a live lens.
#
# Terminal mode resolves a place to render:
#   - inside tmux  -> split a detached pane running the board, return at once (true auto-start)
#   - a TTY on stdout -> take over THIS terminal with the board (run it in a spare pane)
#   - no TTY (cron / headless tick) -> print the one command to open it, exit 0 (emission still on)
#
# Env: SUPERLOOP_TUI_PORT (8000), SUPERLOOP_TUI_HOST (127.0.0.1), SUPERLOOP_RUN_DIR,
#      SUPERLOOP_TUI_PYTHON (python3), SUPERLOOP_TUI_NO_OPEN=1 (web: serve but do not open a browser).

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGDIR="${SUPERLOOP_RUN_DIR:-$HOME/.superloop/runs}"
PYTHON="${SUPERLOOP_TUI_PYTHON:-python3}"

# ---- enable emission first, in every mode (so heartbeats record even with no UI) --------------
mkdir -p "$REGDIR" 2>/dev/null || { echo "launch: cannot create $REGDIR" >&2; exit 0; }
: > "$REGDIR/.enabled"

# ============================ web board (opt-in): textual-serve + browser ======================
if [ "${1:-}" = "--web" ]; then
  HOST="${SUPERLOOP_TUI_HOST:-127.0.0.1}"
  PORT="${SUPERLOOP_TUI_PORT:-8000}"
  URL="http://$HOST:$PORT"
  PIDFILE="$REGDIR/.tui.pid"
  LOG="$REGDIR/.tui.log"

  port_up()  { command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; }
  running()  { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; }
  open_url() {
    [ "${SUPERLOOP_TUI_NO_OPEN:-0}" = "1" ] && return 0
    if command -v open >/dev/null 2>&1; then open "$URL"
    elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL"
    elif command -v wslview >/dev/null 2>&1; then wslview "$URL"
    fi 2>/dev/null
  }

  if [ "${2:-}" = "__child" ]; then
    cd "$SK_ROOT" || exit 0
    "$PYTHON" -m tui.serve >"$LOG" 2>&1 &
    serve_pid=$!
    echo "$serve_pid" > "$PIDFILE"
    i=0
    while [ "$i" -lt 30 ]; do port_up && break; sleep 0.2; i=$((i + 1)); done
    open_url
    wait "$serve_pid" 2>/dev/null
    rm -f "$PIDFILE" 2>/dev/null
    exit 0
  fi

  if running; then open_url; echo "superloop Board already running at $URL"; exit 0; fi
  nohup "$0" --web __child >/dev/null 2>&1 &
  echo "superloop Board (web) starting at $URL  (logs: $LOG)"
  exit 0
fi

# ============================ terminal board (default) =========================================
# tmux: spawn a detached split running the board, return at once. The cleanest auto-start.
if [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
  tmux split-window -d "cd '$SK_ROOT' && exec $PYTHON -m tui.app" 2>/dev/null \
    && { echo "superloop Board opened in a tmux split (emission on)"; exit 0; }
fi

# A real terminal here: hand it over to the board (run this in a spare pane).
if [ -t 1 ]; then
  cd "$SK_ROOT" || exit 0
  exec "$PYTHON" -m tui.app
fi

# Headless tick / cron: nowhere to render. Emission is on; tell the human the one command.
echo "superloop Board: no TTY here - emission is ON (ledger is the durable record)." >&2
echo "  open the live board in a spare terminal:  bash $SCRIPT_DIR/launch.sh" >&2
exit 0
