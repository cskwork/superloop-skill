# Mission: jira - resolve one ticket end-to-end

Unit = **one ticket per tick**, advanced through a staged pipeline. A big ticket may take several
ticks; `Cursor` holds `<ticket>:<stage>` so a tick resumes exactly where the last one stopped.
For a fully scripted pipeline, delegating a ticket to the `jira-resolve` skill
(`/jira-resolve --issue KEY`) is a valid EXECUTE - superloop then owns only PICK, the gates, and
RECORD. Use the stages below when working a ticket directly.

## Stage pipeline (Cursor.stage values, in order)

| Stage | Do | Done when |
|---|---|---|
| **FETCH** | Pick the next ticket via jira-ascli (assigned, status To Do/Open, project per Config JQL; oldest-priority first). Pull description, comments, attachments. | Ticket key + acceptance criteria restated in one line in the ledger |
| **ANALYZE** | Reproduce/locate: trace API -> Controller -> Service -> DAO -> table (aidt-api-table-debugger), read related code, check DB state read-only. Classify frontend/backend/mixed. | Root cause or implementation point named, with file:line |
| **BRANCH** | From up-to-date `origin/aidt-prd`: `fix/{TICKET}` (or `feat/{TICKET}`), per the jira-feature command rules. Run git inside the affected **service directory** (each service is its own repo/submodule), never the monorepo root. | Branch checked out, base verified with `git log -1 origin/aidt-prd` |
| **FIX** | Supergoal DEBUG: reproduce with a **failing test first**, then the smallest change to green. Match surrounding style; no drive-by refactors. | New test red -> green; diff is minimal |
| **TEST** | Full relevant suite for the touched service (aidt: standaloneSetup patterns per aidt-testing-patterns). | Suite green, output saved to `evidence/` |
| **BUILD** | Build/boot the service per the service-build skill (run-server.sh / run-audit.sh, `GRADLE_USER_HOME` inside the service dir). | Build succeeds; app boots; health endpoint responds |
| **DB-CHECK** | When persisted data is load-bearing: read-only before/after evidence via **sql-check** (lms/lcms/sso2). Migrations or data fixes are SQL files for review, never executed by the loop. | Expected rows/values shown by query output |
| **API-CHECK** | Call the changed endpoint(s) on the locally running service (auth via aidt-auth-bootstrap / aidt-dev-token-acquire). Assert the response **body and side effects, not just 200**. Also re-call one adjacent endpoint sharing the code path. | Response bodies match expectation; saved to `evidence/` |
| **LOCAL-VERIFY** | Run **/verify** for the full local proof (it owns localhost verification end-to-end). UI-visible changes: aidt-lms-web-local-debug for a browser-level local pass. | /verify status pass |
| **DEPLOY-GATE** | Deploying to aidt-dev means pushing the branch and merging it into the `aidt-dev` branch, which **Jenkins** picks up and deploys automatically. This is outward-facing: set the unit `awaiting-approval(merge fix/{TICKET} -> aidt-dev)` and report exactly what will be pushed/merged. Proceed only on the user's explicit **APPROVED** (or a pre-recorded standing approval for this ticket in Config). This gate **cannot be skipped** - not by autonomy mode, not by "the tests are green", not by deadline pressure. While waiting, the loop stays alive and PICKs other tickets. | User approval recorded in the ledger, merge/push done, Jenkins build green |
| **POST-DEPLOY** | After Jenkins finishes (dynamic loops: arm a Monitor on the build/deploy rather than polling): (1) env health via aidt-audit-healthcheck; (2) browser-level E2E on the dev URL via **qa-engineer** (deployed-env gate - trace/video evidence); (3) log sweep via **grafana-loki-proxy** for new errors since deploy; (4) **side-effect** sweep - re-run the blast-radius flows from ANALYZE (adjacent endpoints, shared tables, other consumers), mission-qa.md pass-2 style, against dev. | All four green; any regression -> new FIX sub-unit on the same ticket |
| **CLOSE** | Jira comment with evidence summary + transition (jira-ascli) - both outward: same consent gate as deploy unless Config grants standing approval. Changelog entry with the fix reasoning. | Ticket transitioned/commented; ledger unit `done` |

## Gate and failure semantics

- `awaiting-approval` pauses **the ticket**, never the loop: PICK moves to the next ticket and the
  paused one resumes the tick after approval arrives.
- A stage failing 3 consecutive ticks marks the ticket `blocked` with the trail (circuit breaker,
  SKILL.md); escalate in the tick report rather than brute-forcing.
- Anything found broken on dev that this ticket didn't cause: log it as a finding (candidate new
  ticket), don't silently widen this ticket's scope.

## Per-stage record

Every tick appends `#N <ticket>:<stage> -> <result>` plus evidence paths. The ticket's queue entry
carries a stage checklist so a fresh context can resume mid-pipeline without re-deriving anything.
