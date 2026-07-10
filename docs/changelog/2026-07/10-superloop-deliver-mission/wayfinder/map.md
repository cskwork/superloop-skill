# Frontier Map - superloop-driven LMS question bank

## Destination

Run a scheduled superloop for one or two days so fresh contexts repeatedly deliver every Figma-specified
LMS question-bank feature through supergoal, with PostgreSQL/Docker data behavior and exact UI/API/DB
proof, while improving superloop only through separately verified maintenance tickets.

## Current state evidence

- `SKILL.md`: current superloop has only the post-delivery `verify` mission.
- Figma visual file `Hri7ukgrnTDsPWIL3B8g23`: confirmed top-level pages `메인` (`295:578`) and `서브` (`525:1246`).
- Figma planning file `gf6Iu7KtW86YIHTghiveOP`: confirmed page `공통` (`0:1`); full feature-node inventory is not yet proven.
- Figma CLI daemon starts, but Desktop file attachment currently stops at `Open a file in Figma to connect`.
- The target repository currently has no LMS application code.

## Decisions so far

- Preserve `/superloop verify`; add `/superloop deliver` for project construction.
- One scheduled outer tick owns one vertical feature ticket; installed supergoal owns that ticket's full inner delivery loop.
- Disk artifacts, not prior chat, are the only cross-tick memory.
- Resume the active ticket before selecting a sibling; use an atomic lease to prevent duplicate dispatch.
- Put project-specific Figma, DESIGN.md, PostgreSQL, and Docker constraints in the program brief/tickets.
- Apply skill improvements only as separate maintenance tickets between product tickets.

## Not yet specified

- Complete planning-node and screen inventory from both Figma files.
- Product roles, authorization rules, question types, import/export formats, exam/assignment flows, and reporting semantics.
- Final app directory/name and framework, to be chosen after design/feature discovery rather than guessed.
- Scheduler cadence, total tick budget, and preauthorized local integration branch for the real LMS run.

## Out of scope

- Production deployment, shared-branch push/merge, destructive DB operations, and real user data without explicit consent.
- Guessing features from generic LMS conventions when the planning file can answer them.

## Ticket graph

- `SL-001` - in progress - Add scheduled fresh-context `deliver` mission. Blocked by: none. Unblocks: `DISC-001`, later product delivery.
- `DISC-001` - ready with tool blocker - Extract all Figma feature nodes and create `DESIGN.md` plus verified product inventory. Blocked by: Figma Desktop CLI attachment for CLI proof; remote read-only metadata may supplement but not replace requested CLI evidence.
- `APP-001` - planned - Bootstrap the smallest runnable LMS vertical foundation with PostgreSQL/Docker and real browser/API/DB health proof. Blocked by: `DISC-001`.
- `APP-*` - not yet cut - One ticket per Figma-grounded vertical feature. Blocked by: `DISC-001`; tickets are created only after the feature inventory is proven.
- `MAINT-*` - conditional - Independently test any superloop improvement surfaced during product ticks. Blocked by: no active product ticket.

## Frontier

1. `SL-001` - highest leverage: enables the requested scheduled fresh-context execution model.
2. `DISC-001` - can proceed once Figma CLI attaches; it determines all product tickets without domain guessing.

