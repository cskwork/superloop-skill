# changelog 2026-06-10

## superloop-skill 최초 작성

**무엇**: /loop 기반 반복 미션(docs/smells/qa/jira)에 틱 단위 계약을 부여하는 스킬.

**왜 이렇게 설계했나**

- **supergoal에 실행 규율 위임**: 최소 수정/실패 테스트 먼저/실측 검증은 supergoal이 이미
  정의한다. superloop이 별도 방법론을 만들면 두 스킬이 충돌하므로, superloop은 루프 고유 관심사
  (틱 경계, 영속 상태, 페이싱, 무인 안전 장치)만 담당한다. 같은 이유로 jira 미션은 전 단계를
  재발명하지 않고 jira-resolve/qa-engineer/sql-check/service-build/verify를 오케스트레이션한다.
- **loop-runtime.md는 바이너리에서 추출한 원본 /loop 프롬프트 기반**: claude v2.1.170 내장
  프롬프트(파싱 우선순위, interval->cron 표, 동적 모드 6단계, loop.md 센티널)를 정제하고
  캐시 인지 페이싱(5분 TTL, 300s 금지)과 Monitor 품질 기준(silence is not success)을 추가했다.
- **원장(ledger)이 1급 시민**: 루프는 컨텍스트 압축을 넘겨 살아남아야 한다. 멱등 키 기반 큐와
  append-only 틱 로그를 디스크에 두고, ORIENT에서 현실(git)과 조정한다.
- **틱당 1단위**: 배치는 반쯤 검증된 작업을 남기고, 자율 루프에서 미검증 작업은 부채다.
- **동의 게이트는 자율성보다 우선**: aidt-dev 머지(=Jenkins 자동 배포), Jira 전이 등 외부 행위는
  awaiting-approval로 멈추되 루프 자체는 다른 단위로 계속 진행한다(티켓만 멈춤).

**검증**: TDD로 작성 — 계약 테스트 3종(tests/) 69 assertion을 먼저 RED 확인 후 본문 작성,
전부 GREEN. supergoal의 skill-frontmatter-gate.mjs 통과(desc 480/1536자).
