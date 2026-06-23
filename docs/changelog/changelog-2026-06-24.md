# 2026-06-24 - 계약 명문화 · 누적 예산 · worktree 격리 · 라이브 Board (+ Tier 2/3 · 랜딩)

## 배경

두 출처를 현재 superloop와 대조해 개선점을 도출했다.
- Boris Cherny의 agent loops/routines 정리글 (developersdigest, 인터뷰 2차 요약 — 개념 수준으로만 신뢰).
- supergoal-skill (superloop이 이미 실행 규율을 위임하는 베이스).

핵심 원칙(ground-truth 검증, ORIENT 재조정=freshness, ledger-before-memory, 실패경로 테스트)은 이미
갖췄거나 앞서 있었다. 남은 고가치 갭 4개(Tier 1)를 닫았다. 무인 루프의 **안전·정합성·관전성**을 직접
끌어올리는 변경이다.

## 변경

### A. Loop Contract 명문화 (출처1 핵심 주장)
"이기는 팀은 에이전트가 많은 게 아니라 contract가 가장 명확한 팀." 기존엔 `trigger/scope/permissions/
budget/stop/report` 재료가 SKILL 레일 + ledger Config + mission ref에 흩어져 감사가 불가능했다.
→ 1페이지 선언 산출물로 통합: `reference/loop-contract.md`(스펙, 7필드 = 6필드 + `mode` + `owns`),
`templates/contract.md`(빈칸 양식), ledger `## Contract` 섹션(durable, 매 ORIENT 읽힘).

### B. 누적 hard budget (출처1 "$400 overnight" 패턴)
기존 한계는 *유닛당* tick budget과 *연속 3실패* 차단기뿐 — 루프의 **누적 수명**엔 상한이 없었다.
→ contract `budget` 블록에 `max_ticks`/`max_files_per_unit`/`max_runtime_per_tick`/
`checkin_every_n_ticks` 추가, SKILL "Budget ceiling" 안전 레일, ledger `## Counters`에 누적 소비 추적.
상한 도달은 *실패가 아니라 깨끗한 stop*. 중간에 예산을 늘려 "그냥 끝내기"는 금지.

### C. write 미션 worktree 격리 (출처2 supergoal run-worktree)
기존 superloop엔 worktree 개념이 0건이었고 `smells`/`jira`가 작업 브랜치에 직결 기록했다. compaction을
사이에 둔 무인 다중 tick에서 가장 위험한 형태다. → `reference/worktree.md`: 쓰기 미션은
`.superloop/<mission>/worktree`에서 작업, green VERIFY + 동의 후에만 병합. jira BRANCH 스테이지와
smells RECORD를 이에 맞게 수정(핀 문자열 보존). 출처1의 ownership(명확한 write 공간)도 부분 충족.

### D. 터미널 Textual 라이브 Board (사용자 지시, 기본값)
supergoal `tui/` + `templates/observability/`를 **재사용 포팅**(재작성 아님). 기계적 rename
(SUPERGOAL_*→SUPERLOOP_*, ~/.supergoal→~/.superloop) + 어휘 적응(phase enum을 tick stage
ORIENT..PACE로, task status를 ledger queue 상태에 매핑). emit 기본 ON, board는 best-effort이며
**절대 gate하지 않음**. 신규: `tui/{state,app,serve,launch.sh,app.tcss,__init__}`,
`templates/observability/{sl-emit.sh,heartbeat.schema.json}`, `reference/observability.md`.

## 기각한 대안 (왜)

- **Tier 2(점진적 자율성 졸업 워크플로, cross-loop ownership 락-프리 규칙) / Tier 3(escalation 트리거
  명시 리스트, 미션별 named stop)**: 가치는 있으나 이번 안전·정합성 핵심보다 후순위. C의 worktree가
  ownership 핵심을 부분 충족하므로 Tier 2의 긴급도가 낮아졌다. 후속으로 미룸.
- **Board 기본 = 웹(브라우저) vs opt-in**: 사용자가 "터미널 자체 live board"를 명시. 웹은 textual-serve
  의존이 더 크고, opt-in은 "기본 기록=board" 요구와 어긋난다. → 터미널 Textual을 기본, 웹은 `--web`
  opt-in. 단 무인/cron 컨텍스트엔 TTY가 없어 TUI 자동 렌더가 불가능하므로, 그 경우 emit만 ON + 첫 tick
  report에 1-command 안내(정직성). reference/observability.md에 이 한계를 명시.
- **Contract를 별도 파일로만 두기 vs ledger에 기록**: 별도 파일만 두면 compaction 후 못 읽는다. →
  양식은 `templates/contract.md`, 실 기록은 ledger `## Contract`(durable). 둘 다 둔다.
- **Board가 supergoal과 코드 중복 — 신규 경량 구현 vs 재사용**: 재발명 금지 원칙에 따라 검증된 supergoal
  코드를 포팅. one-writer+atomic-rename 불변식을 그대로 유지.

## 검증

- 전체 contract test PASS: 69 → **100 assertions**, FAIL 0
  (loop-runtime 18 + mission-jira 29 + observability 22 신규 + skill-contract 31).
- 기존 핀 문자열 전부 보존(jira BRANCH `origin/aidt-prd`·`fix/{TICKET}`·`service directory` 등) —
  worktree/budget 문구는 가산만.
- Board 무비용 스모크: opt-in 게이트(미설정 시 무출력) → `SUPERLOOP_TUI=1 sl-emit` → 유효 heartbeat
  생성 → 두 번째 emit이 board carry-forward + 상태 전이 → `python3 -m tui.state`가 liveness 파생해
  읽음. (에이전트 비용 0)
- baseline-first 회귀: textual 미설치 환경에서도 contract test 전부 PASS — board 부재가 어떤 핀도
  깨지 않음.
- `sh -n`으로 launch.sh / sl-emit.sh 문법 통과, `from tui import state` 헤드리스 import OK.

## Tier 2/3 + 랜딩 (같은 날 추가 진행)

사용자 요청("남은 것도 진행")으로 처음 보류했던 Tier 2/3와 랜딩까지 마저 진행했다.

### Tier 2 - 점진적 자율성 + 단일 작성자 소유권
- 진보적 자율성: 신규/custom 루프는 `mode: report-only`로 시작(제안만, 모든 쓰기 게이트), 신호가 일관되게
  유용할 때 `write`로 승격, 품질이 떨어지면 강등. (`reference/loop-contract.md`)
- 소유권: 각 루프는 contract `owns`에 적은 리소스만 쓴다. 동시 루프는 소유 범위 밖 read-only + 별도
  worktree(`--slot`). C의 worktree가 write 공간, `owns`가 "그 외엔 안 쓴다"는 약속. SKILL 레일로 명문화.

### Tier 3 - escalation 트리거 + 미션별 named stop
- escalation 트리거를 SKILL 레일로 명시: 모호함, 권한 부족, max_files 초과, 테스트 모순,
  green-but-wrong(배포는 green인데 페이지가 틀림). "놀랍지만 실패는 아닌" 상태는 멈춰서 물어볼 신호.
- 미션별 named stop: jira(`merge_conflict_requires_product_decision`/`tests_fail_after_one_fix`/
  `green_signal_wrong_outcome`), qa(`same_regression_seen_twice`/`green_signal_wrong_outcome`),
  smells(`tests_fail_after_one_fix`/`fix_reverts_a_passing_test`). 서킷 브레이커(3연속)보다 싼, 첫
  원칙적 신호에서의 정지.

### 랜딩 docs/index.html
- 이중언어(ko/en) 디자인을 보존한 외과적 갱신: hero·tick(ORIENT/RECORD)·rails 4개 추가
  (계약/예산/worktree/자율성·소유권) + 서킷브레이커에 escalation + install에 board 레시피.
- `update-gh-pages` 스킬 대신 직접 외과 편집(스타일 보존·변경 최소화). 검증: stdlib HTMLParser 통과,
  ko/en span 55/55, div 41/41 균형, rail 8개.

### 테스트 델타
- skill-contract 31 → 40(+9, Tier 2/3 핀). 전체 **109 assertions**, FAIL 0
  (loop-runtime 18 + mission-jira 29 + observability 22 + skill-contract 40).

## 범위 밖 (후속)
- 실 무인 루프에서 board 자동시작(tmux 분할)의 현장 검증 — 코드 경로는 무비용 스모크로 확인했으나
  사용자 tmux 환경의 자동 렌더는 실사용에서 확인 권장.
