# Mission: qa - verify recent commits and their blast radius

Unit = **one commit-group** (one ticket/topic) since `Cursor.last-verified-SHA`, assessed for
correctness AND side effects. Default posture is supergoal QA-ONLY: findings first; fixes only when
the finding is confirmed by a failing test.

## Queue source (ORIENT/PICK)

- `git log --oneline <last-verified-SHA>..HEAD` on the watched branch; group commits by ticket
  prefix (`[A20-…]`) or topic. One group per tick, oldest first. Key = head SHA of the group.
- Merge commits from upstream count too - other people's changes can break your flows.

## EXECUTE - three passes per commit-group

1. **Intent pass.** Read the diff + ticket/commit message: what behavior was supposed to change?
   (aidt: aidt-jira-change-review covers requirement-vs-diff matching.)
2. **Blast-radius pass.** Map what else the change can touch, beyond the changed lines:
   - callers/usages of changed symbols (LSP findReferences / grep)
   - shared DB tables the changed queries read/write - check other readers of the same columns
   - shared API contracts: who else calls this endpoint / consumes this DTO field
   - config, cache keys, async/batch consumers of the same data
3. **Evidence pass.** For the intended behavior AND the top blast-radius suspects:
   - run the targeted real tests + build for affected services
   - API: hit the endpoint locally (service-build to run, aidt-auth-bootstrap for auth) and assert
     the response **body**, not just the status code
   - DB: read-only checks via sql-check when persisted data is load-bearing
   - missing coverage on a risky path -> write the failing-test candidate (supergoal critic style)
     and log it as a surfaced requirement

## Findings and fixes

- Verdict per group: `pass` / `pass-with-notes` / `fail(finding)`. A `fail` becomes either a fix
  unit (failing test first, then smallest fix - only if the user asked the loop to fix) or an
  `awaiting-approval` escalation with the evidence.
- Side-effect findings name the *other* flow that breaks, with the test/query that proves it.

## VERIFY / RECORD

- Advance `Cursor.last-verified-SHA` only past groups with a recorded verdict + evidence path.
- Tick report lists: group, verdict, evidence, surfaced requirements. Changelog entry when any fix landed.
