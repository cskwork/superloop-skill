# Changelog - 2026-07-10

## Scheduled fresh-context project delivery

Decision: preserve the criterion-based `verify` mission and add a separate feature-based `deliver`
mission. The models differ: verify proves one clause of an already delivered intent; deliver advances
one vertical project ticket through installed supergoal. Keeping separate ledgers preserves cohesion
and backward compatibility.

The outer loop owns cadence, durable frontier state, one-ticket claiming, overlap protection, and
convergence. The inner supergoal run owns Frame, implementation, improvement passes, adversarial review,
and Exact Verify. Completion requires its machine-checkable artifacts, not its summary.

Rejected alternatives:

- Generalize `verify` to accept criteria or features. This would mix incompatible unit states,
  completion rules, and direct-vs-build responsibilities.
- Add a custom process dispatcher immediately. The host `/loop` already supplies scheduling; another
  runtime would add authentication, lifecycle, retry, and process-drain failure modes before evidence
  shows it is needed.
- Modify the skill during an active LMS product ticket. That changes the executing contract mid-run;
  improvements instead become independent maintenance tickets between product tickets.

The portable fresh-context guarantee is deliberately stronger than a host-session promise: every tick
must reconstruct from disk and every supergoal role uses a fresh context. If a scheduler reuses the
outer session, correctness still cannot depend on it.

Implementation contract:

- INIT freezes the root contract, project brief, a distinct immutable root goal, Frontier Map, and
  vertical tickets, then exits without dispatching product work. Scheduled TICKs reconstruct solely
  from those disk artifacts.
- An atomic project-scoped `mkdir` lease serializes claims. The complete active-ticket/run record is
  atomically renamed into the ledger and re-read before dispatch, then always resumes before a sibling.
- The outer loop passes a self-contained frozen ticket to the installed supergoal workflow; it does
  not duplicate Frame, Build, improvement, review, or Exact Verify behavior.
- Ticket closure requires checked GOAL criteria, PASS QA with clean backward trace, completed
  run-state, a DONE marker, a passing current installed commit gate, and root-contract integration
  proof, all bound to the same ticket, run, and verified revision.
- Root contracts may preauthorize bounded local work. Push, deploy, destructive/force actions,
  shared-branch merge, issue-system writes, and data writes remain explicit consent gates.
