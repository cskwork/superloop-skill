# 2026-07-05 - verify 단일 미션 전환 (Intent Spec · 적대적 검증 · fix directive · 수렴 정지)

## 배경

기존 superloop은 미션 4개(docs/smells/qa/jira)를 도는 범용 러너였다. 2026-06-24에 계약·예산·
worktree·Board를 얹어 안전 규율은 갖췄지만, 그 규율이 성격이 다른 미션 4개에 흩어져 있었다 -
"실행"과 "검증"의 경계가 미션마다 달랐다. supergoal(및 oh-my-symphony)이 이미 실행을 맡는
오케스트레이터라면, superloop이 다시 실행 미션을 여러 개 갖는 것은 중복이다. superloop의
고유 가치는 "무엇을 하느냐"가 아니라 "전달된 결과가 원래 의도와 맞는지 판정하고, 아니면
고치라고 지시하는" 판단 규율에 있다. 미션을 `verify` 하나로 좁혀 그 규율을 선명하게 했다.

## 변경

### A. 미션 4개 -> 1개(`verify`)
`reference/mission-{docs,smells,qa,jira}.md` 삭제. 신규 `reference/mission-verify.md`가
ORIENT/PICK/EXECUTE/VERIFY와 named stop을 정의한다. SKILL.md의 `## Missions`는 launch
표 1개(고정 주기/동적 페이싱/단일 틱) + 수렴 설명 문단으로 축소.

### B. Intent Spec -> 인수 기준 큐 (신규 unit)
`templates/intent-spec.md`: 첫 틱 ORIENT에서 원 요청·오케스트레이터의 자체 주장·표면화된
암묵 요구사항 3곳에서 뽑아 고정하는 1페이지 산출물. 커밋/파일/티켓이 아니라 **인수 기준**이
틱당 처리 단위가 됐다 - 배치 금지, 기준 1개당 틱 1개는 그대로.

### C. EXECUTE의 두 형태 - 검증 아니면 지시
기준이 아직 안 틀렸으면 **검증 패스**(intent / blast-radius / evidence / degenerate-input,
전부 스펙 대조지 테스트 대조가 아님). 이미 실패했으면 **지시 패스** - 고치지 않고
fix directive를 오케스트레이터에게 보낸다. `green_signal_wrong_outcome`(그린인데 결과가
틀림)은 검증 쪽에서 유일하게 이름 붙은 정지 조건 - 항상 실패로 취급.

### D. Fix directive + 전달 경로 (신규 reference)
`reference/orchestrator-handoff.md`: directive 형식(기준/실패 증거/위반 조항/범위/인수
테스트) + 전달 경로 3개(supergoal DEBUG in-tick worktree `.superloop/verify/worktree`,
symphony 티켓, report-only). 조용한 패치를 구조적으로 막는다.

### E. 수렴/정지 이름 확정
`all_criteria_proven`(성공, 깨끗한 정지) / `orchestrator_cannot_close_gap`(같은 기준이
fix-directive 한도를 넘겨 계속 막힘 - 에스컬레이션). "완료" 선언은 이번 틱의 새 증거로
`proven`이 확정된 경우에만 - Ralph의 완료 선언 원칙 그대로.

### F. 신규 reference/prompting-insights.md
증거 기준(evidence bar), 의도 무결성(intent integrity), QA 툴킷, 루프 실패 모드를 한 곳에
정리 - 4개 미션 스펙에 흩어져 있던 "검증을 어떻게 신뢰할 것인가"를 통합.

### G. 계약 테스트 재고정
`tests/skill-contract.test.sh` 64 assertions PASS(0 FAIL) - verify 미션, 틱 해부, 기준
1개 규칙, Intent Spec/기준 큐, 원장, 동의 게이트, 루프 계약, 예산 상한, worktree 격리,
fix-directive handoff, Board never-gates를 전부 고정.

### H. 문서 재배치 (README / README.ko / 랜딩)
`README.md`·`README.ko.md`의 Missions 표를 4행 -> 1행(verify)으로, 구조 트리를 신규
reference/template 파일로 갱신, launch 예시를 `/superloop qa|jira|docs|smells` ->
`/superloop verify`로 교체. 두 파일 모두 새 `## Lineage`/`## 계보` 절 추가(Codex
routines · Ralph completion-promise · supergoal 실행 규율 - SKILL.md와 동일 계보).
`docs/index.html`: hero·터미널 목업·미션 그리드·worktree rail·launch 레시피를 verify
루프 서사로 교체 - 카드 4장(docs/smells/qa/jira)을 2장(검증/지시) + 와이드 카드 1장
(수렴 + 기준 상태 배지: unverified/in-progress/proven/blocked/awaiting-approval)으로.
HTML 구조·CSS·이중언어(ko/en) 토글은 손대지 않고 카피만 교체.

## 기각한 대안 (왜)

- **미션 4개를 유지하고 verify를 5번째로 추가**: superloop의 새 정체성은 "오케스트레이터를
  감독하는 검증 루프"다. 5번째 미션으로 얹으면 verify가 다른 4개와 동급 작업으로 보여
  그 경계가 다시 흐려진다. -> 완전 대체.
- **superloop이 직접 고침(in-loop 패치)**: "고치지 않고 지시한다" 원칙과 충돌 - 실행 규율은
  supergoal이 이미 맡는다. superloop이 다시 실행자가 되면 두 스킬의 책임이 겹친다. ->
  fix directive로 전달만.
- **구 미션 파일을 마이그레이션 경로로 남겨둠**: 남겨두면 "미션은 verify 하나"라는 서술과
  당장 모순되고, README/랜딩의 진실성 기준을 깬다. -> 완전 삭제, 하드 컷오버.
- **랜딩 미션 그리드를 4장 유지하고 라벨만 verify로 교체**: 여전히 "여러 미션 중 하나"로
  읽혀 실제 모델(미션 1개, 개념 3개)과 어긋난다. -> 카드 개수 자체를 줄임(2 + wide 1).
- **랜딩 미션 그리드를 3개 일반 카드로**: `.bento`가 고정 2열 그리드라 셀 3개는 두 번째
  행에 빈 칸을 남긴다(이번 세션 중 실제로 만들었다가 레이아웃 결함을 발견해 되돌림). ->
  2 + wide 1로 그리드를 항상 채운다.

## 검증

- `for t in tests/*.test.sh; do bash "$t"; done` 재실행: loop-runtime 18 passed,
  observability 22 passed, skill-contract 64 passed - 전부 0 failed. 합산 104 passed.
- `tests/mission-jira-contract.test.sh` 삭제(커밋 `c5d5198`) - jira 미션이 사라졌으므로
  그 파이프라인 테스트도 함께 제거. deploy-gate·동의·named stop 의미는
  `reference/orchestrator-handoff.md`로 이전됐고 `skill-contract.test.sh`가 이를 고정한다.
- 최종 적대적 리뷰(critic 서브에이전트) 수행 - 계획 대비 스펙 준수·진실성·DRY·루프 건전성·
  테스트 적정성 5개 축 점검. CRITICAL 0건. 지적된 문서 진실성 결함(체인지로그·state-ledger의
  구 미션 잔재)은 리뷰 직후 이 브랜치에서 수정.
- E2E 도그푸딩 - 씨앗 배송물(셔츠된 테스트 2/2 green이나 스펙 위반 내재)에 verify 루프를
  fresh 컨텍스트로 1틱 실제 실행. 루프가 입력 변형·source 앨리어싱·배열 병합·undefined
  덮어쓰기 4건(green_signal_wrong_outcome)을 잡고 report-only fix directive 발행, 소스 미수정.
  스킬을 따라가며 발견한 사용성 결함(Intent Spec 출력 경로 미명시, 실패 기준 status 매핑,
  첫 틱 스윕 예외, spec-silent degenerate 경계)을 mission-verify·contract 템플릿에 수정.
- `grep -rn "mission-docs\|mission-smells\|mission-qa\|mission-jira\|/superloop qa\|
  /superloop jira\|/superloop docs\|/superloop smells" README.md README.ko.md
  docs/index.html` - 결과 없음(구 미션 잔재 0건).
- README.md/README.ko.md 대조 - Missions 표·구조 트리·Lineage 내용 일치 확인(README.ko.md는
  기존에도 없던 `## Tests` 절만 비대칭으로 유지 - 선재 상태, 범위 밖).

## 후속 정리 (이 세션에서 완료)

- `tests/mission-jira-contract.test.sh` 삭제(커밋 `c5d5198`).
- `reference/{loop-contract,observability,worktree}.md`·`templates/observability/*`에 남아있던
  예시성 구 미션 이름(jira/smells 등) 제거 - verify 단일 미션 서사와 일치(커밋 `c5d5198`).
- 리뷰 후속(이 커밋): `reference/state-ledger.md`의 구 미션 어휘(`smell ID`/`done`) 정정,
  계약 `intent` 필드를 loop-contract·ledger 템플릿·state-ledger로 전파, fix-directive 카운터와
  `in-progress` 전이 명시, symphony 전달 경로 테스트 추가.
