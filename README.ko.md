# superloop-skill

오케스트레이터가 내놓은 결과물을 원래 의도에 붙들어 매는 Claude Code 스킬.

`/loop`이 심장박동(언제 다시 깨어날지)이라면, superloop은 그 박동마다 도는 인수 루프다: 전달된 결과에서 인수 기준을 뽑아내고, 각 기준을 스펙에 대조해 검증하며, 격차가 있으면 증명될 때까지 오케스트레이터에게 수정을 지시한다. [supergoal-skill](https://github.com/cskwork/supergoal-skill)의 "baseline-first" 원칙을 루프 환경에 맞게 확장했다. 빌드는 supergoal로, 빌드의 검증은 superloop으로.

**랜딩 페이지**: https://cskwork.github.io/superloop-skill/ (한/영 토글) · **English**: [README.md](README.md)

## 개념

- **/loop** = 심장박동(언제 다시 깨어날지). **superloop** = 그 박동마다 도는 인수 루프(무엇을 도출하고, 어떻게 검증하고 지시할지).
- **계약 먼저**: 루프 시작 전 1페이지 계약(trigger·scope·permissions·budget·stop·report·mode·owns)을 원장 `## Contract`에 적고 매 ORIENT마다 읽는다. 무인 루프의 신뢰는 에이전트 수가 아니라 계약의 명확함에서 온다.
- 모든 틱은 `ORIENT -> PICK -> EXECUTE -> VERIFY -> RECORD -> PACE`를 따른다.
- 틱당 **인수 기준 1개**(one acceptance criterion per tick). 배치 금지, 일거리 발명 금지.
- 상태는 컨텍스트가 아닌 디스크의 원장(`.superloop/verify/ledger.md`)에 남긴다.
- **진실은 의도**: 테스트가 아니라 원래 요청과 스펙에 대조해 검증한다. 기준 하나를 놓친 그린 스위트는 통과가 아니라 실패다.
- **고치지 않고 지시한다**: 기준이 실패하면 증거 기반 수정 지시를 오케스트레이터에게 보낸다. 조용한 패치는 없다.
- **착지한 수정은 worktree 격리**: 지시로 나온 수정은 전용 git worktree에서 작업하고, green 검증 + 동의 후에만 작업 브랜치로 병합한다.
- **기본 기록 = 라이브 Board**: 모든 루프를 한눈에 보는 터미널(또는 웹) 대시보드. 틱마다 heartbeat 1개를 남기되 best-effort이며 절대 gate하지 않는다. 원장이 여전히 durable truth.

## 미션

| 호출 | 내용 |
|---|---|
| `/loop 30m /superloop verify` | 고정 주기로 결과물을 검증: 틱당 인수 기준 1개 |
| `/loop /superloop verify` | 같은 루프를 동적 페이싱 + Monitor로 |
| `/superloop verify` | 지금 바로 단일 틱 |

superloop은 미션 하나, `verify`만 돈다: 전달된 의도에서 인수 기준을 뽑아내고, 각 기준을 스펙에 대조해 검증하며, 격차가 있으면 오케스트레이터에게 수정을 지시한다. 모든 기준이 증명되면 `all_criteria_proven`으로 깨끗이 멈추고, 같은 기준이 수정 지시 한도 안에서도 계속 실패하면 `orchestrator_cannot_close_gap`으로 에스컬레이션한다 — 완료 선언은 절대 지어내지 않는다.

## 안전 장치

- 외부로 나가는 행위(공유 브랜치 push/merge, aidt-dev 배포, Jira 전이, 데이터 쓰기)는 전부
  **동의 게이트** — `awaiting-approval`로 기록하고 사용자의 명시적 APPROVED를 기다린다.
- 서킷 브레이커: 같은 단위 3연속 실패 -> blocked, 미션 전체 3연속 실패 -> 루프 중단 후 보고.
- 빈 큐 3연속 -> 루프 중단 제안. 캐시 인지 페이싱(<=270s 또는 >=1200s, 300s 금지).
- **예산 상한**(누적): `max_ticks`/`max_files_per_unit`/`max_runtime_per_tick`/`checkin_every_n_ticks`. 어느 차원이든 소진되면 루프를 깨끗이 중단하고 보고(또는 체크인 대기). 무인 루프가 한 단위를 갈며 주말치 비용을 태우는 것을 막는다.

## 구조

```
SKILL.md                           # 미션 + 틱 해부 + 안전 장치
reference/mission-verify.md        # verify 미션: ORIENT/PICK/EXECUTE/VERIFY, 종료 조건
reference/orchestrator-handoff.md  # 수정 지시 형식 + 전달 경로(worktree/티켓/보고 전용)
reference/prompting-insights.md    # 증거 기준, 의도 무결성, QA 툴킷, 루프 실패 모드
reference/loop-contract.md         # 1페이지 루프 계약: scope/permissions/budget/stop/mode/owns
reference/loop-runtime.md          # 내장 /loop 메커니즘(파싱, cron, 동적 모드, Monitor) 정제판
reference/state-ledger.md          # 원장 스키마/멱등성/조정 규칙
reference/worktree.md              # 착지한 수정의 worktree 격리
reference/observability.md         # 라이브 Board producer 측(sl-emit heartbeat)
templates/intent-spec.md           # 첫 틱에 고정하는 전달 의도 + 인수 기준 큐
templates/{contract,ledger,tick-report}.md
templates/observability/{sl-emit.sh,heartbeat.schema.json}
tui/                                # superloop Board: Textual 리더(state/app/serve) + launch.sh
tests/*.test.sh                     # 핵심 규칙을 고정하는 계약 테스트
```

## 설치

```bash
ln -sfn "$(pwd)" ~/.agents/skills/superloop
ln -sfn ~/.agents/skills/superloop ~/.claude/skills/superloop
```

## 계보

superloop의 계약은 **Codex 루틴**(Boris Cherny)을 따른다: trigger + scope + budget + stop + report. 수렴은 **Ralph**의 완료 선언 원칙과 같다 — 명백히 참일 때만 "done"을 말한다. 실행 규율(최소 수정, 실패 테스트 먼저)은 시종 **supergoal**의 것이다.
