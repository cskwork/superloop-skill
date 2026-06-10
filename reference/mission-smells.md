# Mission: smells - hunt one bug or code smell, fix it surgically

Unit = **one confirmed smell or latent bug**, fixed with red-green and the real suite. This is a
quality loop, not a refactoring spree: each tick must leave the repo strictly better and fully green.

## Queue source (ORIENT/PICK)

Scan a **bounded slice** per tick - never the whole repo:

1. Recently-touched files first: `git log --since=<last scan> --name-only` ranked by churn.
2. Within the slice, detect with the clean-code skill's smell catalog (long function, duplicated
   logic, feature envy, dead code, swallowed exceptions, N+1 query, missing null/boundary guard...).
   `/code-review` on the recent diff is a valid detector too.
3. Rank: latent **bug** > correctness-adjacent smell (swallowed error, boundary) > readability smell.
   Key = `<file>:<symbol>:<smell>`.

Skip: smells in code the team is actively rewriting, style-only nits a formatter owns, and anything
that would force a wide rename across modules (log as `blocked(too-wide)` for a human decision).

## EXECUTE (supergoal DEBUG discipline)

- **Bug-shaped?** Reproduce with a failing test first; then the smallest fix to green.
- **Smell-shaped?** Confirm existing tests cover the behavior (add a pinning test if not), then
  refactor in safe behavior-preserving steps (clean-code skill techniques), keeping the diff minimal.
- Surgical scope: one smell per tick; do not "while I'm here" neighboring code. Match surrounding
  style; no whole-file rewrites; no new abstractions for a single call site.

## VERIFY

- Full relevant test suite green (service-level; aidt repos: standaloneSetup patterns per
  aidt-testing-patterns) plus build/type checks. Output to `evidence/`.
- For a bug fix: the new test demonstrably went red before the fix and green after - record both runs.

## RECORD

- Mark the unit `done` with the red->green evidence. Changelog entry: smell, why it was a risk, fix
  reasoning.
- Fixes land on the current working branch; pushing or merging anywhere shared is a consent gate.
