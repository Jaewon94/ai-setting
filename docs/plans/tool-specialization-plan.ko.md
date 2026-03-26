# 도구별 특화 강화 계획

## 목적

`ai-setting`이 현재 제공하는 멀티 도구 지원을 "설정 파일 생성" 수준에서 "도구별 고유 기능을 활용하는 운영 가능한 기본값" 수준으로 끌어올린다.

이번 단계에서는 구현보다 먼저 조사 근거와 실행 순서를 고정한다.

## 범위

대상 도구:

- Claude Code
- Codex CLI
- Cursor
- Gemini CLI
- GitHub Copilot

이번 문서의 범위:

- 현재 지원 상태 정리
- 공식 문서 기준 기능 확인
- 커뮤니티에서 많이 쓰이는 패턴 정리
- `ai-setting` 기준 갭 분석
- 구현 우선순위, 실행 단위, 검증 기준 정의
- 문서화 스킬 팩과 운영 메타데이터 확장 방향 정의

## 조사 기준

- 공식 문서에 명시된 기능을 우선 채택한다.
- 커뮤니티 자료는 "많이 쓰는 구성 방식"과 "실제 템플릿 패턴" 파악용으로만 사용한다.
- 각 도구에 공통으로 적용할 방향은 다음 네 가지다.

1. 공용 지침 파일을 얇고 명확하게 유지한다.
2. 경로별 또는 파일 타입별 규칙을 적극적으로 쓴다.
3. 실행 제어, 승인, sandbox, context 범위를 도구별 방식에 맞게 분리한다.
4. `AGENTS.md` / `CLAUDE.md`의 공통 규칙은 재사용하되, 각 도구의 고유 기능은 별도 레이어로 둔다.
5. 도구별 생성물 외에도 "문서화 workflow"와 "운영 메타데이터"를 별도 레이어로 관리한다.

## 현재 상태 요약

현재 `ai-setting`은 아래 자산을 생성한다.

| 도구 | 현재 생성물 | 현재 수준 |
|---|---|---|
| Claude Code | `.claude/settings.json`, hooks, agents, skills, `CLAUDE.md` | 가장 성숙 |
| Codex CLI | `.codex/config.toml`, `AGENTS.md` | 기본 설정 + MCP 중심 |
| Cursor | `.cursor/rules/*.mdc` | 공통 rule + 일부 stack rule |
| Gemini CLI | `.gemini/settings.json`, `GEMINI.md` | 기본 설정 + 컨텍스트 문서 |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | 저장소/경로별 지침 기본 제공 |

현재 구현은 "기본 파일 생성"과 "공통 규칙 이식"은 되어 있지만, 도구별 고유 기능을 체계적으로 활용하는 수준은 아직 부족하다.

## 공통 전략

### 1. 공통 규칙과 도구 특화 규칙을 분리한다

- 공통 규칙:
  - 커밋/테스트/문서/안전 규칙
  - 저장소 구조와 작업 원칙
- 도구 특화 규칙:
  - Cursor의 glob rule
  - Copilot의 `applyTo`
  - Codex의 config/rules/subagents
  - Claude의 hooks/subagents/memory
  - Gemini의 settings/context layer

### 2. archetype과 stack 감지를 더 적극적으로 연결한다

생성 전략을 아래 두 축으로 나눈다.

- stack 축:
  - TypeScript / JavaScript
  - Python
  - Docs-heavy
- archetype 축:
  - Web app
  - API/backend
  - CLI/tooling
  - library/package

각 도구의 규칙은 이 두 축 조합으로 생성한다.

### 3. "강제"와 "권장"을 분리한다

- 기본값으로 넣어도 되는 것:
  - 읽기 전용 규칙
  - 문서화된 지침
  - 컨텍스트 범위, path-specific instructions
- 옵션으로 둬야 하는 것:
  - 특정 모델 강제
  - 과도한 승인 정책
  - 팀 문화에 영향을 주는 커밋/리뷰 규칙

### 4. 문서화 스킬은 자동 생성이 아니라 명시적 실행 자산으로 둔다

- downstream 프로젝트의 기능/인프라/보안 문서를 강제 생성하지 않는다.
- 대신 필요할 때 호출할 수 있는 문서화 스킬 팩으로 제공한다.
- 문서화 스킬은 "어떤 폴더에 어떤 문서를 만들고, 각 문서가 무엇에 답해야 하는지"를 표준화하는 데 집중한다.

### 5. 메타데이터는 "도구가 읽는 필드"와 "운영을 위해 사람이 읽는 필드"를 구분한다

- 도구가 공식적으로 읽는 필드:
  - Codex skill의 `name`, `description`, `agents/openai.yaml`
  - Claude hook의 `type`, `matcher`, `timeout`, `async`
  - Claude agent/skill frontmatter
- 사람이 운영을 위해 필요한 필드:
  - 적용 프로필
  - 기본 활성화 여부
  - 위험도
  - 수동 입력 필요 여부
  - 의존 도구/MCP
- 공식 필드가 없는 경우에는 sidecar notes 또는 manifest로 관리한다.

## 우선순위

### 1순위

- Cursor
- Gemini CLI
- GitHub Copilot

이유:

- 현재 갭이 크다.
- 공식적으로 지원하는 규칙 계층이 분명하다.
- 생성 결과가 바로 체감되는 도구들이다.

### 2순위

- Codex CLI
- Claude Code

이유:

- 이미 기본 수준은 상대적으로 갖춰져 있다.
- 새 기능을 더 넣기보다 운영 기준을 정리하는 비중이 크다.

## 도구별 실행 계획

### 1. Cursor

### 공식 문서 기준

- Project Rules는 `.cursor/rules`에 두고 프로젝트와 함께 버전 관리한다.
- User Rules, Project Rules, `AGENTS.md`, legacy `.cursorrules`가 공존하되, Project Rules가 기본 축이다.
- Cursor는 재사용 가능한 scoped instruction과 파일 타입별 규칙 구성이 핵심이다.

### 커뮤니티에서 많이 쓰는 패턴

- 공통 rule 1개 + 언어별 rule + 테스트 rule + 문서 rule 조합이 가장 흔하다.
- `typescript.mdc`, `python.mdc`, `testing.mdc`처럼 glob 기준 rule 분리가 많이 쓰인다.
- 커뮤니티 curated repo와 rules generator가 널리 공유된다.

### 현재 갭

- 현재는 공통 rule 중심이고 archetype별 분화가 약하다.
- docs, backend, frontend, test 경로별 차등 규칙이 부족하다.
- Cursor에서 중요한 rule 적용 타입과 파일 패턴 전략이 문서화되어 있지 않다.

### 실행 항목

1. rule 체계를 2계층으로 재구성
- `ai-setting.mdc`: 저장소 공통 rule
- stack/archetype rule: `frontend.mdc`, `backend.mdc`, `docs.mdc`, `testing.mdc` 등

2. archetype 기반 생성
- Next.js/Vite 계열: frontend + typescript + testing
- Python API 계열: python + api + testing
- docs-first 계열: docs + writing

3. rule 적용 정책 명시
- 어떤 rule이 항상 적용되는지
- 어떤 rule이 파일 패턴에 따라 적용되는지
- `@file` 제약과 현재 제품 이슈를 주석으로 유지할지 재검토

### 완료 기준

- archetype별로 최소 3개 이상의 유효한 `.mdc` rule 생성
- TypeScript/Python/Docs 프로젝트에서 rule 차등 적용 확인
- Cursor 제품 이슈로 남아 있는 항목은 문서와 주석에 상태 반영

### 2. Gemini CLI

### 공식 문서 기준

- Gemini CLI는 설정 레이어가 명확하다.
- 설정은 기본값, 사용자 설정, 프로젝트 설정, 환경 변수, CLI 인자 순으로 덮어쓴다.
- 프로젝트 단위 `.gemini/settings.json`과 `GEMINI.md`를 함께 운용할 수 있다.

### 커뮤니티에서 많이 쓰는 패턴

- `GEMINI.md`에 역할/작업 방식/출력 형식 규칙을 두고, `settings.json`에는 context 및 실행 환경을 둔다.
- include directories, sandbox 성격 설정, 모델 선택을 프로젝트 수준에서 관리하려는 수요가 많다.
- 실제 사용자는 "CLI 옵션으로만 넘기지 말고 프로젝트에 남는 설정"을 선호하는 편이다.

### 현재 갭

- `settings.json`이 아직 최소 설정 수준이다.
- `GEMINI.md`는 공통 규칙 참조 비중이 크고 Gemini 특화 사용법이 약하다.
- context 범위, 응답 포맷, 경로 허용 범위를 archetype과 연결하지 않았다.

### 실행 항목

1. `settings.json` 템플릿 확장
- context 관련 기본값
- 프로젝트별 include directory 가이드
- sandbox/privacy 관련 옵션 주석 또는 notes 파일 정리

2. `GEMINI.md` 특화
- 도구 사용 전 확인 순서
- 긴 작업 시 진행 공유 방식
- 응답 형식과 수정 원칙

3. 옵션/수동 입력 분리
- 사용자가 직접 넣어야 하는 경로/키는 notes 문서로 분리
- 기본 템플릿은 안전한 값만 자동 생성

### 완료 기준

- 프로젝트 설정 레이어가 공식 문서 기준으로 설명 가능해야 함
- `GEMINI.md`가 단순 참조 파일이 아니라 Gemini 전용 작업 가이드를 포함해야 함
- 수동 입력이 필요한 값은 JSON 밖 notes로 안내돼야 함

### 3. GitHub Copilot

### 공식 문서 기준

- 저장소 전체 지침은 `.github/copilot-instructions.md`에 둔다.
- 경로별 지침은 `.github/instructions/*.instructions.md`에서 `applyTo` frontmatter로 지정한다.
- `AGENTS.md`는 AI agent용 별도 지침 계층으로 함께 사용할 수 있다.
- GitHub는 Customization library를 curated examples로 제공한다.

### 커뮤니티에서 많이 쓰는 패턴

- 테스트, API, 프론트엔드, 문서처럼 파일 성격별로 `applyTo`를 나눈다.
- 저장소 전역 지침은 짧게 유지하고, 구체 규칙은 path-specific instruction으로 분리한다.
- 프롬프트 파일과 경로 지침을 함께 두는 구성도 빠르게 퍼지고 있다.

### 현재 갭

- path-specific instructions는 있지만 archetype별 조합이 제한적이다.
- 저장소 전체 지침에 프로젝트 구조와 네이밍/테스트 흐름을 더 명시할 수 있다.
- Copilot Chat / coding agent / code review 상황별 분리를 아직 충분히 활용하지 않았다.

### 실행 항목

1. repository-wide instruction 다듬기
- 저장소 구조
- 우선 읽어야 할 문서
- 테스트/검증 기준

2. path-specific instruction 확장
- `**/*.test.*`
- `app/**`, `src/**`, `api/**`, `docs/**`
- archetype별로 필요한 instruction만 생성

3. Copilot 전용 prompt/pattern 검토
- 필요 시 prompt files 또는 추가 agent guidance를 옵션 문서로 설계

### 완료 기준

- 최소 4개 이상의 `applyTo` 기반 path-specific instructions 제공
- archetype에 따라 instruction 생성 조합이 달라져야 함
- repository-wide 지침은 짧고, 구체 규칙은 path-specific으로 빠져야 함

### 4. Codex CLI

### 공식 문서 기준

- `AGENTS.md`는 디렉토리 계층에서 자동으로 읽힌다.
- config file은 계층형 설정과 세부 옵션 제어가 가능하다.
- rules는 sandbox 외부 명령 허용 정책을 제어한다.
- skills와 subagents를 별도 계층으로 운용할 수 있다.

### 커뮤니티/실사용 패턴

- 공통 작업 원칙은 `AGENTS.md`에 두고, 실행 정책은 config/rules로 분리하는 방식이 자연스럽다.
- 자동 승인 범위는 팀 성향에 맞게 작게 열고, 반복 명령만 prefix rule로 올리는 패턴이 안전하다.
- 작업 유형별 subagent/skill 분리가 장기적으로 유지보수에 유리하다.

### 현재 갭

- 현재는 config와 AGENTS 중심이라 rules/subagents 계층 활용이 약하다.
- 프로필별로 승인/샌드박스 정책을 더 분명히 나눌 여지가 있다.
- archetype별 Codex guidance가 거의 없다.

### 실행 항목

1. 프로필별 config 차등 강화
- approval/sandbox 관련 정책 차등
- 팀용/엄격 모드와 개인용 기본값 분리

2. rules 전략 정리
- 반복 허용 prefix 후보 정의
- 과도한 자동 허용은 기본값에서 제외

3. archetype별 AGENTS 보강
- 문서 중심 프로젝트
- backend/API 프로젝트
- frontend 프로젝트

### 완료 기준

- 프로필별 config 차이가 명확히 설명 가능해야 함
- rules는 "기본 안전" 기준으로 설계돼야 함
- AGENTS.md가 공통 규칙만이 아니라 archetype 문맥까지 담아야 함

### 5. Claude Code

### 공식 문서 기준

- 프로젝트 기억과 지침은 `CLAUDE.md` 중심으로 운용한다.
- settings는 우선순위가 있고, hooks는 사용자 정의 shell command로 연결된다.
- subagents는 `.claude/agents`에 두고 프로젝트 단위로 버전 관리할 수 있다.

### 커뮤니티/실사용 패턴

- 공통 지침은 `CLAUDE.md`, 실행 제어는 settings/hooks, 역할 분리는 subagents/skills로 나눈다.
- 보안/리뷰/테스트 작성처럼 책임이 분명한 서브 에이전트 구성이 자주 쓰인다.
- 팀 환경에서는 로컬 오버라이드와 버전 관리 대상 파일을 분리하는 패턴이 많다.

### 현재 갭

- Claude 쪽은 상대적으로 성숙하지만 archetype별 지침이 아직 약하다.
- hooks와 skills가 많아졌지만 "언제 어떤 프로필에서 활성화되는지" 설명이 부족하다.
- Codex/Copilot/Cursor와의 역할 분담 문서가 약하다.

### 실행 항목

1. archetype별 `CLAUDE.md` 보강
- frontend/backend/docs/cli 차이 반영

2. profile별 hook/agent/skill 설명 정리
- standard/minimal/strict/team 차등 명확화

3. 다른 도구와의 역할 분담 문서화
- Claude 우선, Codex fallback
- Cursor/Copilot과의 중복 지침 정리

### 완료 기준

- 프로필별 활성 자산 차이가 문서와 생성 결과에서 일치해야 함
- `CLAUDE.md`가 archetype 문맥을 더 잘 반영해야 함
- hooks/agents/skills의 책임 경계가 문서에 명확해야 함

### 6. 문서화 스킬 팩

### 도입 배경

- 다른 프로젝트에서 검증된 문서화 스킬 패턴을 `ai-setting`의 선택형 자산으로 흡수한다.
- 목표는 README 장문화를 유도하는 것이 아니라, 주제별 문서를 구조적으로 정리하게 만드는 것이다.
- 초기 범위는 `feature`, `infra`, `security` 세 가지로 제한한다.

### 참고한 실사용 패턴

- `document-feature`
  - 출력: `docs/features/<slug>/`
  - 구성 예: `README.md`, `decisions.md`, `architecture.md`, `guide.md`
- `document-infra`
  - 출력: `docs/infrastructure/<slug>/`
  - 구성 예: `README.md`, `decisions.md`, `configuration.md`, `operations.md`
- `document-security`
  - 출력: `docs/security/<slug>/`
  - 구성 예: `README.md`, `decisions.md`, `implementation.md`, `operations.md`

### 현재 갭

- 현재는 배포/레퍼런스/이슈 문서는 잘 정리되어 있지만, 주제별 문서화 workflow는 스킬로 제공하지 않는다.
- `docs/decisions.md`, `docs/research-notes.md`는 전역 문서라 특정 기능/인프라 주제 문서와 역할이 다르다.
- downstream 프로젝트에서 기능/인프라/보안 정리를 시작할 때 사용할 수 있는 구조화된 템플릿이 부족하다.

### 실행 항목

1. 문서화 스킬 팩 설계
- `document-feature`, `document-infra`, `document-security` 3개로 시작
- 자동 생성이 아니라 명시적 실행 전용 skill로 둠

2. 출력 구조 표준화
- `docs/features/*`, `docs/infrastructure/*`, `docs/security/*` 폴더 규칙 고정
- 각 문서가 답해야 하는 질문을 skill 본문에 명시

3. 기존 문서 체계와의 연결
- 전역 ADR/연구 메모와 주제별 문서의 경계를 정의
- README에는 링크만 두고, 긴 설명은 주제별 폴더로 내림

4. 최소 템플릿과 notes 제공
- 너무 무거운 boilerplate는 피함
- 문서 생성 전에 필요한 입력과 작성 순서를 notes로 안내

### 완료 기준

- 3개 문서화 skill이 각각 명확한 호출 조건과 출력 폴더 규칙을 가짐
- 각 skill은 문서 3~4개 수준의 최소 구조만 강제함
- 전역 문서와 주제별 문서의 역할 충돌이 문서상 해소됨

### 7. 스킬/훅 메타데이터 고도화

### 공식 문서 기준

- Codex skills는 `SKILL.md`의 `name`, `description`을 필수로 요구하고, `agents/openai.yaml`로 UI metadata, invocation policy, tool dependency를 추가할 수 있다.
- Codex는 skill `description`을 기반으로 암묵 호출을 판단하므로, 설명 문구의 범위와 경계가 중요하다.
- Claude hooks는 이벤트별 `matcher` regex, `type`, `timeout`, `async`를 공식적으로 지원한다.
- Claude는 `prompt`/`agent` hook을 공식 지원하므로, 단순 shell command 외에 검증 hook 설계가 가능하다.
- Claude docs는 plugin의 `hooks/hooks.json`과 component frontmatter를 shareable metadata 경로로 다룬다.

### 현재 갭

- 현재 skill frontmatter는 대부분 `name`, `description`, `disable-model-invocation`까지만 사용한다.
- 어떤 skill이 명시적 호출 전용인지, 어떤 의존 도구를 전제로 하는지 파일 수준에서 드러나지 않는다.
- hooks는 동작은 명확하지만, 프로필 범위, 위험도, blocking/async 성격을 사람이 한눈에 보기 어렵다.
- Claude hook이 공식적으로 지원하는 `prompt`/`agent` 타입을 어디에 써볼지 기준 문서가 없다.

### 실행 항목

1. skill metadata 표준안 정의
- 공통 최소 필드: `name`, `description`
- Codex 확장 필드: `agents/openai.yaml`의 `interface`, `policy.allow_implicit_invocation`, `dependencies.tools`
- Claude/Codex 공통 운영 필드: notes 또는 manifest에 `category`, `explicit_only`, `profile_scope`, `required_tools`, `required_mcp`

2. hook metadata 표준안 정의
- 공식 필드 사용 원칙: `type`, `matcher`, `timeout`, `async`
- 운영용 sidecar manifest 또는 주석 필드:
  - purpose
  - enabled_profiles
  - blocking_or_async
  - risk_level
  - requires_network_or_secret

3. hook 타입 확장 후보 정리
- 현재 command hook 위주 구성을 유지
- 검증 가치가 큰 지점은 prompt/agent hook 후보로 문서화
- 예: Stop 시 테스트/상태 검증, PermissionRequest 시 민감 작업 점검

4. doctor/reference와의 연결
- doctor에서 metadata 기반 진단 항목을 확장할 수 있는지 검토
- `docs/reference*`에 "왜 이 hook/skill이 있는지"를 메타데이터 기준으로 설명

### 완료 기준

- skill metadata와 hook metadata의 표준 필드 목록이 문서로 고정됨
- 공식 지원 필드와 내부 운영용 필드가 구분돼 설명됨
- 최소 1개 이상 skill/Codex metadata, 1개 이상 hook metadata 적용 후보가 정의됨
- 추후 구현 시 lint/test 대상으로 삼을 수 있는 manifest 구조 초안이 생김

## 구현 순서

### Step 1. 설계 고정

- 이 문서를 기준 계획으로 둔다.
- `docs/roadmap.md` Phase 8은 요약만 두고 상세는 이 문서를 참조한다.

### Step 2. 생성 전략 정리

- `stack x archetype x tool` 매트릭스 정의
- 어떤 조건에서 어떤 파일을 생성할지 표로 고정

### Step 3. 템플릿 확장

- Cursor rules
- Copilot path-specific instructions
- Gemini settings/context
- Codex profile config / rules
- Claude archetype guidance

### Step 4. 테스트 추가

- archetype fixture별 생성물 검증
- 도구별 파일 수, 내용, notes 생성 여부 검증

### Step 5. 문서 반영

- README는 지원 수준 요약만 유지
- `docs/reference*`에 생성물 설명 반영
- 배포 문서는 변경 없으면 유지

### Step 6. 문서화/메타데이터 레이어 확장

- 문서화 skill pack 초안 작성
- skill/hook metadata 표준안과 sidecar manifest 초안 작성
- 공식 지원 필드와 내부 운영 필드를 구분해 정리

## 검증 기준

- 같은 archetype라도 도구별 생성물이 실제로 달라져야 한다.
- "공통 파일 복사"가 아니라 도구 고유 기능이 최소 2개 이상 반영돼야 한다.
- 수동 입력이 필요한 값은 config 파일 안이 아니라 notes 문서로 안내돼야 한다.
- `./tests/run_all.sh` 회귀 없이 통과해야 한다.

## 리스크

- 도구 공식 스키마가 빠르게 바뀔 수 있다.
- Cursor의 `@file`처럼 제품 이슈가 남아 있는 기능은 회피 전략이 필요하다.
- Copilot과 Codex는 기능이 겹쳐 보이지만 instruction 계층이 다르므로 공통화 과도 적용을 피해야 한다.
- 사용자가 원치 않는 강제 정책은 기본값에 넣지 말아야 한다.

## 이번 단계의 권장 산출물

1. Cursor rule 재구성안
2. Copilot instruction 분할안
3. Gemini settings/context 확장안
4. Codex config/rules 프로필안
5. Claude archetype guidance 정리안
6. 문서화 skill pack 설계안
7. skill/hook metadata 표준안
8. 테스트 매트릭스 초안

## 참고 자료

### 공식 문서

- Cursor Rules: https://docs.cursor.com/context/rules
- GitHub Copilot custom instructions: https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions?tool=visualstudio
- Claude Code memory: https://code.claude.com/docs/en/memory
- Claude Code settings: https://code.claude.com/docs/en/settings
- Claude Code hooks: https://code.claude.com/docs/en/hooks
- Claude Code hooks guide: https://code.claude.com/docs/en/hooks-guide
- Claude Code subagents: https://code.claude.com/docs/en/sub-agents
- Codex Skills: https://developers.openai.com/codex/skills
- Codex Rules: https://developers.openai.com/codex/rules
- Codex AGENTS.md: https://developers.openai.com/codex/guides/agents-md
- Codex Subagents: https://developers.openai.com/codex/subagents
- Codex Config Reference: https://developers.openai.com/codex/config-reference/
- Codex Prompting Guide: https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide
- Gemini CLI configuration: https://geminicli.com/docs/reference/configuration/
- Gemini CLI repository: https://github.com/google-gemini/gemini-cli

### 커뮤니티/실사용 패턴 참고

- awesome-cursorrules: https://github.com/PatrickJS/awesome-cursorrules
- awesome-cursor-rules-mdc: https://github.com/sanjeed5/awesome-cursor-rules-mdc
- GitHub Copilot Customization Library: https://github.com/github/awesome-copilot
- Cursor rules generator: https://cursorrules.org/
