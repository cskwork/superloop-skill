"""Pure reader for the superloop Board state files. No Textual imports - importable and
testable headless. The UI layer (app.py) consumes what this returns.

Liveness is timestamp-primary (pid is an advisory same-host refinement only), matching
reference/observability.md - Claude Code tool calls have no stable per-agent pid.
"""

from __future__ import annotations

import glob
import json
import os
import socket
from datetime import datetime, timezone

WARN_SECS = 45      # alive -> stale boundary
DEAD_SECS = 180     # stale -> dead boundary


def default_run_dir() -> str:
    return os.environ.get(
        "SUPERLOOP_RUN_DIR", os.path.join(os.path.expanduser("~"), ".superloop", "runs")
    )


def this_host() -> str:
    return socket.gethostname().split(".")[0]


def _parse_iso_z(ts: str) -> float | None:
    """Epoch seconds from an ISO-8601 'YYYY-MM-DDTHH:MM:SSZ' string, or None."""
    if not ts:
        return None
    try:
        return (
            datetime.strptime(ts, "%Y-%m-%dT%H:%M:%SZ")
            .replace(tzinfo=timezone.utc)
            .timestamp()
        )
    except (ValueError, TypeError):
        return None


def _pid_alive(pid: int) -> bool:
    """Same-host best-effort liveness. Advisory only."""
    if not pid or pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True   # exists, owned by another user
    except OSError:
        return False


def derive_liveness(hb: dict, now_epoch: float, host: str) -> str:
    """One of: done | dead | stale | alive. Timestamp is the primary signal."""
    if (hb.get("phase") or "") == "Done":
        return "done"
    updated = _parse_iso_z(hb.get("updated_at", ""))
    age = float("inf") if updated is None else max(0.0, now_epoch - updated)
    same_host = hb.get("host") in (host, None, "")
    pid = hb.get("pid") or 0
    # pid only DOWNGRADES to dead, never upgrades a stale clock to alive
    if age > DEAD_SECS:
        return "dead"
    if same_host and pid and not _pid_alive(int(pid)) and age > WARN_SECS:
        return "dead"
    if age > WARN_SECS:
        return "stale"
    return "alive"


def read_agents(run_dir: str | None = None, now_epoch: float | None = None) -> list[dict]:
    """All current heartbeats with derived `liveness` + `age_secs`, sorted by repo then id.

    Robust to a file vanishing mid-read (atomic rename can unlink the temp) and to a stray
    non-JSON file - such entries are skipped, never raised.
    """
    run_dir = run_dir or default_run_dir()
    import time

    now_epoch = time.time() if now_epoch is None else now_epoch
    host = this_host()
    out: list[dict] = []
    for path in glob.glob(os.path.join(run_dir, "agents", "*.json")):
        try:
            with open(path, "r", encoding="utf-8") as fh:
                hb = json.load(fh)
        except (OSError, ValueError):
            continue
        if not isinstance(hb, dict) or not hb.get("agent_id"):
            continue
        updated = _parse_iso_z(hb.get("updated_at", ""))
        hb["age_secs"] = None if updated is None else max(0.0, now_epoch - updated)
        hb["liveness"] = derive_liveness(hb, now_epoch, host)
        hb.setdefault("tasks", [])
        out.append(hb)
    out.sort(key=lambda h: (h.get("repo", ""), h.get("agent_id", "")))
    return out


def board_columns(tasks: list[dict]) -> dict[str, list[str]]:
    """Group task titles into the Jira columns, preserving order."""
    cols = {"backlog": [], "in-progress": [], "review": [], "done": [], "blocked": []}
    for t in tasks or []:
        cols.setdefault(t.get("status", "backlog"), []).append(t.get("title", ""))
    return cols


def counts(agents: list[dict]) -> dict[str, int]:
    live = sum(1 for a in agents if a.get("liveness") == "alive")
    stale = sum(1 for a in agents if a.get("liveness") == "stale")
    dead = sum(1 for a in agents if a.get("liveness") == "dead")
    done_tasks = sum(1 for a in agents for t in a.get("tasks", []) if t.get("status") == "done")
    total_tasks = sum(len(a.get("tasks", [])) for a in agents)
    return {
        "agents": len(agents),
        "alive": live,
        "stale": stale,
        "dead": dead,
        "tasks_done": done_tasks,
        "tasks_total": total_tasks,
    }


if __name__ == "__main__":   # tiny CLI: dump current state as JSON (no new mode, just a debug aid)
    import sys

    print(json.dumps(read_agents(sys.argv[1] if len(sys.argv) > 1 else None), indent=2))
