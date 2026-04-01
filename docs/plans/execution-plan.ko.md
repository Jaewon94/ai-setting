# ai-setting 실행 계획

> **운영 원칙:** 이 문서는 현재 시점의 상위 실행 계획이다. 세부 구현 계획은 각 하위 계획 문서로 분리하고, 실제 진행 순서는 이 문서를 기준으로 관리한다.

**목표:** 문서, 구현, 배포, 도구 특화가 서로 어긋나지 않도록 상위 우선순위를 고정하고 순차적으로 실행한다.

**운영 방식:** 큰 작업에 들어가기 전에는 먼저 공식 문서와 현재 저장소 상태를 확인한다. 문서 갱신이 필요한 작업은 시퀀셜 MCP로 근거를 확인한 뒤 반영한다.

**계획 저장 위치:** `docs/plans/`

**현재 상태 (2026-04-01):**
- 문서 최신화 루프를 계속 운영 중이며, `v1.2.0` 릴리스와 배포 문서 정리까지 반영됐다.
- 우선순위 2~5 범위의 구현은 저장소에 반영되어 있고 `./tests/run_all.sh` 기준 `PASS 258 / FAIL 0`이다.
- Phase 11 잔여 MCP preset(`brave-search`, `Agentation`)은 현재 라운드에서 진행하지 않는다.
  - `brave-search`: API 키 없이는 실사용 가치가 낮고, 키 주입 설계까지 추가로 필요하다.
  - `Agentation`: MCP preset만으로 끝나지 않고 앱 쪽 패키지 설치와 개발용 mount 기준까지 필요하다.

---

## 1. 최우선 원칙

1. 전체 문서 최신화를 가장 먼저 처리한다.
2. 문서와 실제 동작이 충돌하면 실제 동작을 먼저 확인하고 문서를 고친다.
3. 하위 계획 문서는 독립적으로 유지하되, 우선순위와 착수 순서는 이 문서에서 통제한다.

## 2. 1순위: 전체 문서 최신화

### 목적

- `README`, `usage`, `reference`, `roadmap`, `issues`, `distribution`, `field-test`가 현재 구현 상태와 일치하도록 맞춘다.
- 새 기능이나 리팩터링이 들어오면 구현보다 늦지 않게 문서를 정리하는 운영 리듬을 만든다.

### 범위

- 진입 문서:
  - `README.md`
  - `README.ko.md`
- 사용/구조 문서:
  - `docs/usage.md`
  - `docs/usage.ko.md`
  - `docs/reference.md`
  - `docs/reference.ko.md`
- 계획/상태 문서:
  - `docs/roadmap.md`
  - `docs/issues.md`
  - `docs/plans/*.md`
- 배포/운영 문서:
  - `docs/deployment-checklist.md`
  - `docs/distribution/*`
- 실전 검증 문서:
  - `docs/field-test-*.md`

### 실행 원칙

- 시퀀셜 MCP로 실제 상태를 확인한 뒤 수정한다.
- 공식 문서 기반으로 판단한 변경은 근거 링크와 확인일을 남긴다.
- 문서 간 source-of-truth를 정하고 중복 설명은 줄인다.
- README는 진입 문서로 유지하고, 상세 내용은 하위 문서로 내린다.
- 검증은 변경 범위 기반 빠른 스위트를 먼저 실행하고, `run_all.sh`는 마지막 1회만 사용한다.

### 완료 기준

- 주요 문서 사이에 현재 상태 불일치가 없다.
- 새로 반영된 AGENTS archetype, 도구별 특화, 배포 운영 상태가 문서에 반영된다.
- roadmap의 단계/완료 상태와 실제 구현 상태가 맞는다.

## 3. 2순위: 문서화 스킬 팩

상세 계획: [tool-specialization-plan.ko.md](/Users/jaewon/my-project/ai-setting/docs/plans/tool-specialization-plan.ko.md)

### 목표

- `document-feature`
- `document-infra`
- `document-security`

이 세 가지를 명시적 호출 skill로 설계하고, downstream 프로젝트에서도 구조화된 주제별 문서를 쉽게 만들 수 있게 한다.

### 완료 조건

- `docs/features/*`, `docs/infrastructure/*`, `docs/security/*` 구조를 표준화한다.
- 전역 문서와 주제별 문서의 역할 충돌을 해소한다.

### 현재 상태

- `document-feature`, `document-infra`, `document-security`가 Claude skill과 core plugin mirror에 반영됐다.
- 설치 경로, reference 문서, profile 테스트까지 연결된 상태다.

## 4. 3순위: 파일 보호 정책 재설계

### 목표

- 현재 `protect-files.sh`의 일괄 차단 방식을 `block / confirm / allow` 3단계 정책으로 재설계한다.
- 사용자가 자주 수정해야 하는 파일까지 과하게 막아 생산성이 떨어지는 문제를 줄인다.
- 동시에 실제 비밀값, 인증서, 키 파일, 파괴적 생성물 같은 고위험 자산은 계속 강하게 보호한다.

### 설계 방향

- 기본 원칙:
  - 진짜 고위험 자산만 `block`
  - 운영 중 자주 만지는 설정 파일은 `confirm`
  - 일반 소스/문서는 `allow`
- 재검토 대상 예:
  - `.env*`
  - `docker-compose*.yml`
  - `.github/workflows/*`
  - 배포 스크립트
  - lockfile
- 프로젝트별 override 가능성을 열어 둔다.

### 완료 조건

- 보호 정책이 위험도 기준으로 설명 가능해야 한다.
- 사용자 편의와 안전의 균형이 문서로 명확히 정리돼야 한다.
- 추후 구현 시 profile/manifest와 연결할 수 있는 구조가 정의돼야 한다.

### 현재 상태

- `protect-files.sh`는 `block / confirm / allow` 3단계 정책으로 동작한다.
- `.ai-setting/protect-files.json` override와 hard-block downgrade 불가 제약까지 문서/테스트에 반영됐다.

## 5. 4순위: 스킬/훅 메타데이터 표준화

상세 계획: [tool-specialization-plan.ko.md](/Users/jaewon/my-project/ai-setting/docs/plans/tool-specialization-plan.ko.md)

### 목표

- 공식 필드:
  - Codex skill `name`, `description`, `agents/openai.yaml`
  - Claude hook `type`, `matcher`, `timeout`, `async`
- 내부 운영 필드:
  - `profile_scope`
  - `required_tools`
  - `required_mcp`
  - `risk_level`
  - `blocking_or_async`

공식 필드와 내부 운영 필드를 분리해서 표준화한다.

### 완료 조건

- sidecar notes 또는 manifest 초안이 정의된다.
- 이후 doctor/test에서 metadata 기반 검증 확장이 가능해진다.

### 현재 상태

- `.claude/skills/metadata.json`, `.claude/hooks/metadata.json` manifest가 도입됐다.
- reference 문서와 tests가 핵심 필드를 검증한다.

## 6. 5순위: 테스트 자동화 강화

상세 계획: [docs/roadmap.md](/Users/jaewon/my-project/ai-setting/docs/roadmap.md)

### 목표

- 문서화 스킬과 metadata 표준화가 들어온 뒤에도 회귀가 없도록 테스트를 보강한다.
- `run_all.sh` 수준을 넘어, 문서/생성물/manifest까지 검증 범위를 넓힌다.

### 현재 상태

- `tests/run_all.sh`가 profile, hooks, tools, detect, sync, basic 흐름을 묶어 회귀를 검증한다.
- 2026-03-31 재실행 기준 `PASS 258 / FAIL 0`이다.

## 7. 하위 계획 문서

- [tool-specialization-plan.ko.md](/Users/jaewon/my-project/ai-setting/docs/plans/tool-specialization-plan.ko.md)
  - Phase 8 세부 실행 계획
- 추가 계획 문서는 필요 시 `docs/plans/` 아래에 계속 분리한다.

## 8. 진행 규칙

1. 큰 작업을 시작하기 전에 이 문서의 우선순위를 먼저 확인한다.
2. 하위 계획 문서를 수정하면, 필요할 경우 이 상위 계획도 함께 갱신한다.
3. 현재 턴의 목표가 문서 최신화라면 구현보다 먼저 문서 불일치 목록부터 만든다.
