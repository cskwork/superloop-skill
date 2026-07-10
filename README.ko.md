# superloop-skill

오케스트레이터의 결과물을 원래 의도에 대조해 검증하거나, 대형 프로젝트를 수직 기능 한
개씩 이어서 구현하는 Claude Code 스킬.

`/loop`이 심장박동(언제 다시 깨어날지)이라면, superloop은 그 박동마다 실행할 단위와 종료
조건을 디스크에 고정한다. `verify`는 완성된 결과에서 인수 기준을 뽑아 검증한다. `deliver`는
불변 루트 목표와 프로젝트 프런티어에서 수직 티켓 한 개를 재개하거나 선택하고, 설치된
[supergoal-skill](https://github.com/cskwork/supergoal-skill)에 전체 구현 절차를 맡긴다.

**랜딩 페이지**: https://cskwork.github.io/superloop-skill/ (한/영 토글) · **English**: [README.md](README.md)

## 개념

- **/loop** = 심장박동(언제 다시 깨어날지). **superloop** = 그 박동마다 도는 인수 루프(무엇을 도출하고, 어떻게 검증하고 지시할지).
- **계약 먼저**: 루프 시작 전 1페이지 계약(trigger·scope·permissions·budget·stop·report·mode·owns)을 원장 `## Contract`에 적고 매 ORIENT마다 읽는다. 무인 루프의 신뢰는 에이전트 수가 아니라 계약의 명확함에서 온다.
- 모든 틱은 `ORIENT -> PICK -> EXECUTE -> VERIFY -> RECORD -> PACE`를 따른다.
- 틱당 **미션 단위 1개**. `verify`는 인수 기준 1개, `deliver`는 활성 수직 티켓 1개다.
- 상태는 컨텍스트가 아닌 디스크의 원장(`.superloop/<mission>/ledger.md`)에 남긴다.
- **진실은 의도**: 테스트가 아니라 원래 요청과 스펙에 대조해 검증한다. 기준 하나를 놓친 그린 스위트는 통과가 아니라 실패다.
- **고치지 않고 지시한다**: 기준이 실패하면 증거 기반 수정 지시를 오케스트레이터에게 보낸다. 조용한 패치는 없다.
- **착지한 수정은 worktree 격리**: 지시로 나온 수정은 전용 git worktree에서 작업하고, green 검증 + 동의 후에만 작업 브랜치로 병합한다.
- **기본 기록 = 라이브 Board**: 모든 루프를 한눈에 보는 터미널(또는 웹) 대시보드. 틱마다 heartbeat 1개를 남기되 best-effort이며 절대 gate하지 않는다. 원장이 여전히 durable truth.
- **deliver 단일 writer**: 원자적 `mkdir` lease를 얻은 틱만 원장과 활성 티켓을 바꾼다. 활성 claim은 실행 전에 원자적으로 기록하며, 겹치면 중복 실행하지 않고 닫힌 상태로 실패한다.
- **정확한 완료 증거**: GOAL, QA, run-state, DONE marker, commit gate, 통합 증거가 모두 맞아야 티켓을 닫는다. 에이전트 요약은 증거가 아니다.

## 미션

| 호출 | 내용 |
|---|---|
| `/loop 30m /superloop verify` | 고정 주기로 결과물을 검증: 틱당 인수 기준 1개 |
| `/loop /superloop verify` | 같은 루프를 동적 페이싱 + Monitor로 |
| `/superloop verify` | 지금 바로 단일 틱 |
| `/loop 30m /superloop deliver <project-brief>` | 지금 INIT, 이후 예약 재진입마다 수직 티켓 1개 |
| `/loop /superloop deliver <project-brief>` | 동적 페이싱으로 같은 프로젝트 전달 |
| `/superloop deliver <project-brief>` | 최초 INIT 또는 기존 프로젝트 TICK 1회 |

`verify` 계약은 그대로다. 전달된 의도에서 인수 기준을 뽑아 하나씩 검증하고,
`all_criteria_proven` 또는 `orchestrator_cannot_close_gap`에서 멈춘다.

`deliver`는 INIT/TICK을 분리한다. INIT은 루트 계약, 프로젝트 brief, 불변 루트 목표를 고정하고 supergoal
WAYFINDER로 의존성 맵과 수직 티켓을 만든 뒤 제품 티켓을 실행하지 않고 끝난다. 이후 TICK은
대화 기억을 쓰지 않고 `.superloop/deliver/`에서 상태를 복원하며, lease를 얻고, 활성 티켓을
형제 티켓보다 먼저 재개한다. 설치된 supergoal의 Frame부터 Exact Verify/QA까지 모두 실행한
뒤 정확한 통합 증거로만 티켓과 프런티어를 갱신한다. `all_tickets_integrated`,
`frontier_blocked`, `deadline_reached`에서 예약을 깨끗이 끝낸다.

## 안전 장치

- 외부로 나가는 행위(공유 브랜치 push/merge, aidt-dev 배포, Jira 전이, 데이터 쓰기)는 전부
  **동의 게이트** — `awaiting-approval`로 기록하고 사용자의 명시적 APPROVED를 기다린다.
- 서킷 브레이커: 같은 단위 3연속 실패 -> blocked, 미션 전체 3연속 실패 -> 루프 중단 후 보고.
- 빈 큐 3연속 -> 루프 중단 제안. 캐시 인지 페이싱(<=270s 또는 >=1200s, 300s 금지).
- **예산 상한**(누적): `max_ticks`/`max_files_per_unit`/`max_runtime_per_tick`/`checkin_every_n_ticks`. 어느 차원이든 소진되면 루프를 깨끗이 중단하고 보고(또는 체크인 대기). 무인 루프가 한 단위를 갈며 주말치 비용을 태우는 것을 막는다.
- 루트 계약이 명시한 로컬 작업만 자동 승인할 수 있다. push, deploy, 파괴/force 작업, 공유 브랜치 merge, 이슈 시스템 쓰기, 모든 데이터 쓰기는 계속 명시적 동의 게이트다.
- 진행 중 발견한 스킬 개선은 활성 제품 티켓이 끝난 뒤 실행할 별도 maintenance 티켓으로 만든다. 실행 중인 티켓의 계약을 중간에 바꾸지 않는다.

## 구조

```
SKILL.md                           # verify/deliver 라우터 + 틱 해부 + 안전 장치
reference/mission-verify.md        # verify 미션: ORIENT/PICK/EXECUTE/VERIFY, 종료 조건
reference/orchestrator-handoff.md  # 수정 지시 형식 + 전달 경로(worktree/티켓/보고 전용)
reference/mission-deliver.md       # INIT/TICK, 프런티어, lease, 활성 티켓, 종료 조건
reference/supergoal-handoff.md     # 설치된 supergoal 전달, 재개, 정확한 완료 증거
reference/prompting-insights.md    # 증거 기준, 의도 무결성, QA 툴킷, 루프 실패 모드
reference/loop-contract.md         # 1페이지 루프 계약: scope/permissions/budget/stop/mode/owns
reference/loop-runtime.md          # 내장 /loop 메커니즘(파싱, cron, 동적 모드, Monitor) 정제판
reference/state-ledger.md          # verify/deliver 원장 스키마/멱등성/조정 규칙
reference/worktree.md              # 착지한 수정의 worktree 격리
reference/observability.md         # 라이브 Board producer 측(sl-emit heartbeat)
templates/intent-spec.md           # 첫 틱에 고정하는 전달 의도 + 인수 기준 큐
templates/{contract,ledger,delivery-ledger,tick-report}.md
templates/observability/{sl-emit.sh,heartbeat.schema.json}
tui/                                # superloop Board: Textual 리더(state/app/serve) + launch.sh
tests/*.test.sh                     # 핵심 규칙을 고정하는 계약 테스트
```

## 설치

```bash
ln -sfn "$(pwd)" ~/.agents/skills/superloop
ln -sfn ~/.agents/skills/superloop ~/.claude/skills/superloop
```

`verify`는 단독 실행할 수 있다. `deliver`는 티켓 실행 전체를 위임하므로 설치된
[supergoal-skill](https://github.com/cskwork/supergoal-skill)이 필요하다.

## 계보

superloop의 계약은 **Codex 루틴**(Boris Cherny)을 따른다: trigger + scope + budget + stop + report. 수렴은 **Ralph**의 완료 선언 원칙과 같다 — 명백히 참일 때만 "done"을 말한다. 실행 규율(최소 수정, 실패 테스트 먼저)은 시종 **supergoal**의 것이다.
