# GOAL - scheduled fresh-context delivery

Single source of done for the first frontier slice. Only the verifier ticks a box.

## Original Request

> make superloop 기능과 supergoal skill 이 있을 때 이거 두개 활용해서 supergoal로 지속적 스펙과 목표 설정 쪼개서
>   loop기반으로 작업할 걸 계속해서 이어서 구현 진행이 되게하고 싶어. 대형 규모의 프로젝트에서 기능 하나씩 추가되는 상황에서
>   사용. 실제 superloop 스킬 개선해서 내가 의도한 방식 workflow로 작동하게 해줘 그리고 실제 구현 테스트는 디자인은 이 figma 로
>   되어 있고 figma cli DESIGN.md 디자인 시스템은 이 느낌으로 잡고. 기능들은 전부 다 구현 db는 postgresql 활용 docker available.
>   작업 중간 중간 스킬 개선 점 있으면 개선하면서 LMS 문제은행 개발해줘 - figma cli utilize - https://www.figma.com/design/Hri7
>   ukgrnTDsPWIL3B8g23/%EB%AC%B8%EC%A0%9C%EC%9D%80%ED%96%89-%EB%94%94%EC%9E%90%EC%9D%B8%EA%B3%B5%EC%9C%A0?node-id=295-578 메인,
>   서브 페이지 디자인 . 그리고 기획은 여기 figma link -
>   https://www.figma.com/design/gf6Iu7KtW86YIHTghiveOP/-LMS-%EB%AC%B8%EC%A0%9C%EC%9D%80%ED%96%89?node-id=1-3 이거 말고
>   다른노드에 또 다른 기능들도 있어
>
> loop 는 스케줄 loop로 계속해서 작업을 진행하는 기능이야 하루건 이틀이건. fresh context로 각 스펙마다

## Spec

Preserve the existing `verify` mission and add a `deliver` mission for multi-feature projects.
Initialization creates one durable root goal, a supergoal Frontier Map, and vertical tickets. Every
scheduled tick must ignore conversational memory, acquire a project-scoped lease, read durable state,
resume the active ticket or claim exactly one unblocked frontier ticket, and hand that ticket to the
installed `supergoal` workflow. `supergoal` owns the ticket's Frame, Build, improvement passes,
adversarial review, and Exact Verify/QA in fresh role contexts. The outer tick closes the ticket only
from exact completion artifacts, updates the frontier and ledger, releases the lease, then schedules
the next tick. Local work explicitly granted by the root contract may auto-approve a scheduled ticket
plan; push, deploy, destructive operations, shared-branch merge, and data writes remain consent gates.

The Figma links, `figma-cli`, DESIGN.md, PostgreSQL, Docker, and LMS domain requirements belong in the
project brief and selected tickets. They are passed through by `deliver`; they are not hard-coded into
the reusable skill. Skill improvements discovered during product delivery become separate maintenance
tickets between product tickets so an active ticket's contract cannot change underneath it.

Non-goals for this slice: implementing LMS product screens, replacing the built-in scheduler, or
rewriting the existing `verify` mission.

## Success Criteria

- [x] `SKILL.md` routes `verify` and `deliver` without weakening the existing verify contract. - verify: `bash tests/skill-contract.test.sh && bash tests/deliver-contract.test.sh`
- [x] `deliver` initialization and ticks use a durable Frontier Map plus exactly one vertical ticket per scheduled fresh-context tick. - verify: `bash tests/deliver-contract.test.sh`
- [x] An active ticket is resumed before any sibling is selected, and an atomic lease prevents overlapping ticks from dispatching the same ticket. - verify: `bash tests/deliver-contract.test.sh`
- [x] The handoff invokes the installed `supergoal` contract and accepts completion only from GOAL, QA, run-state, DONE marker, commit gate, and named integration evidence. - verify: `bash tests/deliver-contract.test.sh`
- [x] The runtime documents immediate initialization, one-to-two-day scheduled re-entry, context-independent state, correct pacing, and clean stop/deadline behavior. - verify: `bash tests/loop-runtime-contract.test.sh`
- [x] Existing verify, runtime, and observability contracts remain green. - verify: `for t in tests/*.test.sh; do bash "$t"; done`
- [x] A fresh-context forward test can reconstruct the next action from the skill, contract, map, ticket, and ledger without chat history. - verify: independent subagent report
- [x] Decision rationale and rejected alternatives are recorded for the next maintainer. - verify: `test -f docs/changelog/changelog-2026-07-10.md`

## Decision Gates

| ID | Action | Status | Finding | Decision | Recheck |
|---|---|---|---|---|---|
| d1 | no-op | resolved | The repo has only `main`; the run still needs isolation. | Use `main` as source and target, work on `codex/superloop-deliver-lms`, merge only after acceptance. | `git branch --show-current` |
| d2 | no-op | resolved | Desktop Figma connection is not available yet. | Record it as design-discovery evidence; do not guess LMS features in this slice. | `figma-cli files` |
