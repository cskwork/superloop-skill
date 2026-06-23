# superloop-skill

`/loop` 위에서 도는 반복 미션에 규율을 부여하는 Claude Code 스킬. [supergoal-skill](https://github.com/cskwork/supergoal-skill)의
"baseline-first" 원칙을 루프 환경(틱 단위 실행, 컨텍스트 압축, 무인 자율 동작)에 맞게 확장했다.

**랜딩 페이지**: https://cskwork.github.io/superloop-skill/ (한/영 토글) · **English**: [README.md](README.md)

## 개념

- **/loop** = 심장박동(언제 다시 깨어날지). **superloop** = 박동마다의 계약(무엇을, 얼마나, 어떻게 검증하고 기록할지).
- **계약 먼저**: 루프 시작 전 1페이지 계약(trigger·scope·permissions·budget·stop·report·mode·owns)을 원장 `## Contract`에 적고 매 ORIENT마다 읽는다. 무인 루프의 신뢰는 에이전트 수가 아니라 계약의 명확함에서 온다.
- 모든 틱은 `ORIENT -> PICK -> EXECUTE -> VERIFY -> RECORD -> PACE`를 따른다.
- 틱당 **작업 단위 1개**(one unit of work per tick). 배치 금지, 일거리 발명 금지.
- 상태는 컨텍스트가 아닌 디스크의 원장(`.superloop/<mission>/ledger.md`)에 남긴다.
- 실행 규율은 supergoal에 위임(최소 수정, 실패 테스트 먼저, 실제 테스트로 검증).
- **쓰기 미션은 worktree 격리**: `smells`/`jira`는 전용 git worktree에서 작업하고, green 검증 + 동의 후에만 작업 브랜치로 병합한다.
- **기본 기록 = 라이브 Board**: 모든 루프를 한눈에 보는 터미널(또는 웹) 대시보드. 틱마다 heartbeat 1개를 남기되 best-effort이며 절대 gate하지 않는다. 원장이 여전히 durable truth.

## 미션

| 호출 | 내용 |
|---|---|
| `/loop 1d /superloop docs` | 최근 커밋 기준 문서/체인지로그 자동 최신화 |
| `/loop 1h /superloop smells` | 최근 변경 코드에서 버그/코드스멜 1건 탐지 후 외과적 수정 |
| `/loop 30m /superloop qa` | 마지막 검증 SHA 이후 커밋 QA + 블라스트 레디우스/사이드이펙트 점검 |
| `/loop /superloop jira` | Jira 티켓 1건을 FETCH -> ... -> DEPLOY-GATE -> POST-DEPLOY -> CLOSE 파이프라인으로 해소 (동적 페이싱 + Monitor) |

## 안전 장치

- 외부로 나가는 행위(공유 브랜치 push/merge, aidt-dev 배포, Jira 전이, 데이터 쓰기)는 전부
  **동의 게이트** — `awaiting-approval`로 기록하고 사용자의 명시적 APPROVED를 기다린다.
- 서킷 브레이커: 같은 단위 3연속 실패 -> blocked, 미션 전체 3연속 실패 -> 루프 중단 후 보고.
- 빈 큐 3연속 -> 루프 중단 제안. 캐시 인지 페이싱(<=270s 또는 >=1200s, 300s 금지).
- **예산 상한**(누적): `max_ticks`/`max_files_per_unit`/`max_runtime_per_tick`/`checkin_every_n_ticks`. 어느 차원이든 소진되면 루프를 깨끗이 중단하고 보고(또는 체크인 대기). 무인 루프가 한 단위를 갈며 주말치 비용을 태우는 것을 막는다.

## 구조

```
SKILL.md                      # 미션 테이블 + 틱 해부 + 안전 장치
reference/loop-contract.md    # 1페이지 루프 계약: scope/permissions/budget/stop/mode/owns
reference/loop-runtime.md     # 내장 /loop 메커니즘(파싱, cron, 동적 모드, Monitor) 정제판
reference/state-ledger.md     # 원장 스키마/멱등성/조정 규칙
reference/worktree.md         # 쓰기 미션의 worktree 격리
reference/observability.md    # 라이브 Board producer 측(sl-emit heartbeat)
reference/mission-{docs,smells,qa,jira}.md
templates/{contract,ledger,tick-report}.md
templates/observability/{sl-emit.sh,heartbeat.schema.json}
tui/                          # superloop Board: Textual 리더(state/app/serve) + launch.sh
tests/*.test.sh               # 계약 테스트 100개 (bash tests/<t>.test.sh)
```

## 설치

```bash
ln -sfn "$(pwd)" ~/.agents/skills/superloop
ln -sfn ~/.agents/skills/superloop ~/.claude/skills/superloop
```
