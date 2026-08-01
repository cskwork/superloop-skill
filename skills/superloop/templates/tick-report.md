# Tick report (user-facing, one short block per tick)

**superloop <mission> tick #N** - <unit key>: <result in one sentence>.
- Did: <what changed / what was checked>
- Evidence: <test/build/HTTP/DB output summary + evidence file path>
- Queue: <X open, Y done, Z blocked/awaiting-approval>; next: <next unit or "empty - backing off">
- Pace: <cron refires | wakeup in Ns because ... | Monitor armed on ...>

Awaiting approval (if any): <exact action needing consent, e.g. "merge fix/A20-812 into aidt-dev">
