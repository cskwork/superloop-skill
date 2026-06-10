# Mission: docs - keep documentation in step with the code

Unit = **one documentation artifact** brought up to date and grounded in current code. Never a
repo-wide rewrite in one tick.

## Queue source (ORIENT/PICK)

Refresh the queue from, in priority order:

1. **Undocumented recent change**: commits since `Cursor.last-sweep-SHA`
   (`git log --oneline <sha>..HEAD`) with no matching entry in `docs/changelog/changelog-YYYY-MM-DD.md`
   -> one unit per commit-group (same ticket/topic groups into one unit).
2. **Stale doc**: a README / wiki page / API doc whose statements contradict current code (spot-check
   the anchors it cites). One page per unit.
3. **Missing doc**: a module/service with no README or onboarding note, recently touched first.

Key = doc path (or `changelog:<SHA-range>`). Skip generated files, vendored code, and anything the
repo already documents elsewhere (don't duplicate CLAUDE.md or git history).

## EXECUTE

- Ground every claim in code you read **this tick** - cite `file:line` anchors in the doc where the
  format allows. Supergoal LEARN-DOMAIN style: source-grounded, no speculation.
- Changelog entries record the **why** (decision and reasoning), not a diff restatement.
- Match the existing doc's language, tone, and structure; surgical edits over rewrites. Korean for
  team-facing prose if the surrounding docs are Korean; identifiers and paths stay English.
- Never invent behavior: if the code is ambiguous, write what is verifiably true and flag the open
  question in the doc or ledger instead of guessing.

## VERIFY

- Re-read each cited anchor: does the code still say what the doc now claims? Any dead
  anchor/contradiction -> fix before recording.
- Links resolve, code blocks are syntactically valid, file renders (markdown lint if the repo has one).
- Evidence: list of claims -> anchors checked, saved to `evidence/`.

## RECORD

Advance `Cursor.last-sweep-SHA` only when every commit up to it is either documented or explicitly
ledgered as `skip(reason)` (e.g. trivial typo commits).
