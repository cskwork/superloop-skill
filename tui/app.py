"""superloop Board - a live, in-terminal dashboard of every loop's mission + tick stage +
Jira-like unit board. Pure consumer of the state files written by templates/observability/sl-emit.sh.
It observes only; it never gates or blocks a superloop run.

Run in this terminal:   python -m tui.app
Serve in-browser:        python -m tui.serve   (or tui/launch.sh --web)
"""

from __future__ import annotations

from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.widgets import DataTable, Footer, Header, RichLog, Static

from tui import state

# The universal tick anatomy - every mission moves through these. Mission-specific stages
# (jira FETCH..CLOSE) ride in current_task / note.
STAGES = ["ORIENT", "PICK", "EXECUTE", "VERIFY", "RECORD", "PACE"]
GLYPH = {"alive": ("●", "green"), "stale": ("○", "yellow"),
         "dead": ("○", "dim"), "done": ("✓", "blue")}
BOARD_COLS = [("Backlog", "backlog"), ("In-Progress", "in-progress"),
              ("Review", "review"), ("Done", "done")]


class SuperloopBoard(App):
    CSS_PATH = "app.tcss"
    TITLE = "superloop Board"
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("p", "toggle_pause", "Pause refresh"),
        Binding("r", "refresh_now", "Refresh"),
    ]

    def __init__(self, run_dir: str | None = None, poll_secs: float = 1.0):
        super().__init__()
        self.run_dir = run_dir or state.default_run_dir()
        self.poll_secs = poll_secs
        self.paused = False
        self.selected: str | None = None
        self._roster_cols = []
        self._board_cols = []
        self._cell_cache: dict[tuple, str] = {}   # (agent_id, col_idx) -> last value, for diffing
        self._sel_sig: str | None = None          # selected agent's last updated_at logged
        self._log_seen: dict[str, str] = {}

    # ---- layout -------------------------------------------------------------------------------
    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal():
            yield DataTable(id="agents", cursor_type="row", zebra_stripes=True)
            with Vertical(id="detail"):
                yield Static(id="stages")
                yield DataTable(id="board", cursor_type="none")
                yield RichLog(id="events", highlight=False, markup=True, wrap=True)
        yield Footer()

    def on_mount(self) -> None:
        roster = self.query_one("#agents", DataTable)
        self._roster_cols = roster.add_columns(" ", "loop", "repo", "branch / worktree", "mission", "stage")
        board = self.query_one("#board", DataTable)
        self._board_cols = board.add_columns(*[c[0] for c in BOARD_COLS])
        self.query_one("#stages", Static).update(self._render_stages(None))
        self.set_interval(self.poll_secs, self.refresh_state)
        roster.focus()
        self.refresh_state()

    # ---- refresh ------------------------------------------------------------------------------
    def action_toggle_pause(self) -> None:
        self.paused = not self.paused
        self.sub_title = "PAUSED" if self.paused else ""

    def action_refresh_now(self) -> None:
        self.refresh_state(force=True)

    def refresh_state(self, force: bool = False) -> None:
        if self.paused and not force:
            return
        agents = state.read_agents(self.run_dir)
        by_id = {a["agent_id"]: a for a in agents}
        self._sync_roster(by_id)
        c = state.counts(agents)
        self.sub_title = (
            f"loops:{c['agents']} live:{c['alive']} stale:{c['stale']} dead:{c['dead']}  "
            f"units:{c['tasks_done']}/{c['tasks_total']}"
        )
        if self.selected is None and agents:
            self._select(agents[0]["agent_id"])
        self._render_detail(by_id.get(self.selected) if self.selected else None)

    def _sync_roster(self, by_id: dict) -> None:
        table = self.query_one("#agents", DataTable)
        existing = set(table.rows.keys())
        seen = set()
        for agent_id, hb in by_id.items():
            seen.add(agent_id)
            cells = self._roster_cells(hb)
            if agent_id not in existing:
                table.add_row(*cells, key=agent_id)
                for i, v in enumerate(cells):
                    self._cell_cache[(agent_id, i)] = _plain(v)
            else:
                for i, v in enumerate(cells):
                    if self._cell_cache.get((agent_id, i)) != _plain(v):
                        table.update_cell(agent_id, self._roster_cols[i], v)
                        self._cell_cache[(agent_id, i)] = _plain(v)
        for gone in existing - seen:          # agent file deleted -> drop the row
            try:
                table.remove_row(gone)
            except Exception:
                pass
            for i in range(len(self._roster_cols)):
                self._cell_cache.pop((gone, i), None)
            if self.selected == gone:
                self.selected = None

    def _roster_cells(self, hb: dict):
        glyph, color = GLYPH.get(hb.get("liveness", "alive"), ("?", "white"))
        style = "dim" if hb.get("liveness") == "dead" else ""
        br = hb.get("branch", "-")
        wt = hb.get("worktree", "") or ""
        brwt = f"{br}" if wt in (hb.get("repo_path", ""), "") else f"{br}  ({_short(wt)})"
        row = [
            Text(glyph, style=color),
            Text(hb.get("agent_id", ""), style=style),
            Text(hb.get("repo", ""), style=style),
            Text(brwt, style=style),
            Text(hb.get("mode") or "-", style=style),
            Text(hb.get("phase") or "-", style=style),
        ]
        return row

    # ---- detail panes -------------------------------------------------------------------------
    def on_data_table_row_selected(self, event: DataTable.RowSelected) -> None:
        if event.data_table.id == "agents" and event.row_key.value is not None:
            self._select(event.row_key.value)
            agents = {a["agent_id"]: a for a in state.read_agents(self.run_dir)}
            self._render_detail(agents.get(self.selected))

    def _select(self, agent_id: str) -> None:
        self.selected = agent_id

    def _render_detail(self, hb: dict | None) -> None:
        self.query_one("#stages", Static).update(self._render_stages(hb))
        self._render_board(hb)
        self._maybe_log(hb)

    def _render_stages(self, hb: dict | None) -> Text:
        cur = (hb or {}).get("phase")
        done = (hb or {}).get("liveness") == "done" or cur == "Done"
        cur_idx = STAGES.index(cur) if isinstance(cur, str) and cur in STAGES else -1
        t = Text()
        if hb is None:
            t.append("  (no loop selected)", style="dim")
            return t
        t.append("  ")
        for i, stage in enumerate(STAGES):
            active = stage == cur
            passed = cur_idx > i
            if active:
                t.append(f" {stage.upper()} ", style="bold reverse")
            elif passed or done:
                t.append(f" {stage} ", style="green")
            else:
                t.append(f" {stage} ", style="dim")
            if i < len(STAGES) - 1:
                t.append("›", style="dim")
        if done:
            t.append("   DONE", style="bold blue")
        return t

    def _render_board(self, hb: dict | None) -> None:
        board = self.query_one("#board", DataTable)
        board.clear()
        if hb is None:
            return
        cols = state.board_columns(hb.get("tasks", []))
        depth = max((len(cols.get(key, [])) for _, key in BOARD_COLS), default=0)
        blocked = cols.get("blocked", [])
        for r in range(max(depth, 1)):
            cells = []
            for _, key in BOARD_COLS:
                items = cols.get(key, [])
                cells.append(_short(items[r], 26) if r < len(items) else "")
            board.add_row(*cells)
        for title in blocked:                  # surface blocked units as a flagged row
            board.add_row(Text(f"! {_short(title, 24)}", style="red"), "", "", "")

    def _maybe_log(self, hb: dict | None) -> None:
        if hb is None:
            return
        aid = hb["agent_id"]
        sig = hb.get("updated_at", "")
        if self._log_seen.get(aid) == sig:
            return
        self._log_seen[aid] = sig
        log = self.query_one("#events", RichLog)
        clock = (sig or "")[11:19]
        phase = hb.get("phase") or "-"
        task = hb.get("current_task") or ""
        note = hb.get("note")
        line = f"[dim]{clock}[/] [b]{phase}[/]: {task}"
        if note:
            line += f"  [yellow]({note})[/]"
        log.write(line)


def _plain(v) -> str:
    return v.plain if isinstance(v, Text) else str(v)


def _short(s: str, n: int = 30) -> str:
    s = s or ""
    return s if len(s) <= n else s[: n - 1] + "…"


if __name__ == "__main__":
    SuperloopBoard().run()
