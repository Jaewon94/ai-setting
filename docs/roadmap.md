# ai-setting 고도화 로드맵

> 현재 상태: init.sh로 Claude Code + Codex 설정 복사 + AI 자동 채우기
> 목표: 프로젝트 로컬 MCP, 문서/구현 분기, 다양한 언어/프레임워크/프로젝트 유형 지원, 멀티 AI 도구 지원, 자동 동기화, 프로필 시스템

## 완료 체크

- [x] Priority 0: 프로젝트 로컬 MCP preset 도입
- [x] Priority 1: `blank-start / docs-first / hybrid / code-first` 분기 도입
- [x] Priority 2: archetype / stack 자동 감지 1차 도입
- [x] Priority 3: `doctor / dry-run / diff / backup-all / reapply` 도입
- [x] Phase 1: 멀티 도구 지원
- [ ] Phase 2: 동기화 시스템
- [x] Phase 3: 프로필 시스템 고도화
- [ ] Phase 4: 플러그인 마켓플레이스

## Priority 0: 프로젝트 로컬 MCP 도입

> "글로벌에만 있던 MCP를 새 프로젝트에서도 바로 쓴다"

### 왜 이걸 먼저 하나

현재 `ai-setting`은 Claude/Codex 기본 설정 파일은 프로젝트에 복사하지만, MCP는 사용자 글로벌 환경에 남아 있어 새 프로젝트마다 재현성이 떨어진다.

- 같은 저장소를 받아도 사람마다 쓸 수 있는 MCP 구성이 달라질 수 있음
- "이 프로젝트에서는 어떤 MCP를 기본으로 쓰는지"가 문서/설정에 남지 않음
- 매번 글로벌 설정을 수동으로 맞춰야 해서 온보딩 비용이 큼

따라서 고도화 1순위는 "이 프로젝트가 기본 제공하는 로컬 MCP preset"을 도입하는 것이다.

### 설계 결론 (1차)

- `init.sh`가 프로젝트 로컬 MCP 설정도 함께 생성한다
- 사용자 글로벌 설정을 읽어 복사하지 않고, 이 저장소가 소유한 템플릿/preset을 기준으로 생성한다
- Codex는 `.codex/config.toml`의 `mcp_servers.*`를 통해 관리한다
- Claude Code는 프로젝트 루트의 `.mcp.json`을 통해 팀 공유 가능한 project-scoped MCP 구성을 제공하는 방향으로 간다
- 1차는 "API 키 없이 바로 사용할 수 있는 MCP"만 포함한다

이 원칙으로 가면 결과가 항상 동일하고, 새 프로젝트를 만든 뒤 바로 재현 가능한 기본 환경을 제공할 수 있다.

### 1차 포함 범위

| preset | 서버 | 기본 포함 | 메모 |
|--------|------|-----------|------|
| `core` | `sequential-thinking` | ✅ | 거의 모든 프로젝트에 공통으로 유용 |
| `core` | `serena` | ✅ | 코드 심볼 탐색/리팩토링에 유용 |
| `core` | `upstash-context-7-mcp` | ✅ | 공식 문서 조회용 |
| `web` | `playwright` | 선택 | 웹/프론트 프로젝트에만 기본 추천 |
| `infra` | `docker` | 선택 | Docker 기반 프로젝트에서만 추천 |

기본 동작은 `core` 자동 포함, 필요 시 `web`, `infra`를 추가 선택하는 구조를 목표로 한다.

### 제외 / 보류

- 제외: `brave-search`
  - 이유: 현재 글로벌 설정에서 API 키가 필요하므로 1차 원칙과 맞지 않음
- 보류: `filesystem`
  - 이유: 키는 없지만 허용 루트/경로 스코프 설계를 같이 해야 해서 1차 범위로 넣기에는 보안/운영 판단이 더 필요함

### 후보 옵션 MCP (프로젝트 특화)

기본 preset과 별도로, 프로젝트 성격이 맞을 때만 붙일 후보 옵션은 아래처럼 관리한다.

| 분류 | MCP | 상태 | 메모 |
|------|-----|------|------|
| `frontend-addon` | `Agentation` | 후보 | React 18+ 앱 코드에 개발용 컴포넌트를 직접 심어야 하므로 공통 preset이 아니라 React/Next 전용 addon이 적합 |
| `web-debug` | `Chrome DevTools MCP` | 후보 | 브라우저 디버깅/네트워크/퍼포먼스 점검에 유용, Playwright와 성격이 다름 |
| `next-addon` | `Next.js DevTools MCP` | 후보 | Next.js 프로젝트 한정으로 가치가 높음 |
| `local-tools` | `git` | 후보 | 로컬 repo 분석/조작에 유용하지만 권한 정책을 먼저 정해야 함 |
| `local-tools` | `fetch` | 후보 | 단순 문서/웹 페이지 수집용, 기존 검색/브라우저 도구와 역할 중복 가능 |
| `local-tools` | `filesystem` | 보류 | 가장 유용할 수 있지만 허용 루트 정책 설계가 선행되어야 함 |
| `low-priority` | `memory`, `time` | 보류 | 무키/재현성은 좋지만 대부분 프로젝트에서 체감 가치가 낮음 |

### 구현 계획

1. Codex/Claude의 프로젝트 로컬 MCP 설정 방식과 공유 범위를 공식 문서 기준으로 확정한다.
2. 이 저장소 내부에 MCP preset 템플릿 구조를 만든다.
3. `init.sh`에 MCP 생성 단계를 추가한다.
4. 기본값은 `core` 자동 포함으로 두고, `web`, `infra`는 선택 옵션으로 연동한다.
5. README와 로드맵에 preset, 제외 항목, 선행 조건(`npx`, `uvx`, Docker 등)을 문서화한다.
6. 임시 프로젝트에서 초기화 후 Codex/Claude 양쪽 모두에서 설정 파일이 기대한 위치에 생성되는지 검증한다.

### 완료 기준

- 새 프로젝트 초기화 후, 글로벌 MCP 없이도 프로젝트 로컬 설정만으로 기본 MCP 구성이 재현된다
- 어떤 MCP가 기본/선택/제외인지 문서만 보고 이해할 수 있다
- 키가 필요한 MCP는 기본 포함되지 않는다
- 웹/인프라 성격에 따라 preset을 분리할 수 있다

---

## Priority 1: 문서/구현 기준 분기

> "문서만 있으면 문서를 따르고, 구현이 있으면 실제 상태를 먼저 보며, 아무 근거가 없으면 과추론하지 않는다"

### 왜 필요한가

현재 `init.sh`의 AI 자동 채우기는 프로젝트 구조와 주요 파일을 분석해 `CLAUDE.md`, `AGENTS.md`를 채우는 방식이다. 하지만 실제 프로젝트는 성숙도가 제각각이라, 항상 같은 기준으로 해석하면 아래 문제가 생긴다.

- 문서만 먼저 있는 초기 프로젝트에서 구현이 없다는 이유로 중요한 기획 맥락을 놓칠 수 있음
- 구현이 이미 많이 진행된 프로젝트에서 오래된 문서를 그대로 따르면 실제 상태와 어긋난 설정이 만들어질 수 있음
- 문서와 구현이 둘 다 있는 프로젝트에서 무엇을 우선해야 하는지 기준이 없으면 AI 출력 일관성이 떨어짐

따라서 프로젝트 상태에 따라 소스 오브 트루스를 다르게 보는 분기 전략이 필요하다.

### 설계 결론

`ai-setting`은 프로젝트를 아래 4가지 모드 중 하나로 분류해서 처리한다.

| 모드 | 언제 쓰나 | 우선 기준 | 처리 방식 |
|------|-----------|-----------|-----------|
| `blank-start` | 폴더만 있고 문서/구현 신호가 거의 없을 때 | 확인 가능한 사실만 | MCP, hooks, 템플릿만 안전하게 깔고 AI 자동 채우기는 보수적으로 처리하거나 건너뛴다 |
| `docs-first` | 문서/기획은 있지만 구현이 거의 없을 때 | 문서 | PRD, README, 설계 문서, 요구사항 문서를 기준으로 템플릿을 채우고 미구현 항목은 계획/가정으로 표시 |
| `hybrid` | 문서와 구현이 둘 다 의미 있게 있을 때 | 코드 + 문서 | 실행 가능한 코드/설정/테스트를 먼저 보고, 문서는 빈칸 보완 및 의도 확인용으로 사용 |
| `code-first` | 구현이 많이 진행되어 있고 문서는 참고 수준일 때 | 코드 | 실제 디렉토리 구조, 실행 명령, 테스트, 설정 파일을 기준으로 작성하고 문서와 다르면 차이를 명시 |

현재 상태:
- `init.sh`에서 기본 휴리스틱으로 `blank-start / docs-first / hybrid / code-first` 자동 감지를 수행
- AI 자동 채우기 프롬프트에 감지 모드와 근거 신호를 함께 주입
- 문서/구현 충돌 시 `CLAUDE.md`에 짧은 mismatch 섹션을 남기도록 1차 반영
- `blank-start`에서는 과추론을 피하기 위해 AI 자동 채우기를 기본적으로 건너뛰고 재실행을 안내
- `--project-name`, `--archetype`, `--stack` 힌트로 blank-start에서도 guided bootstrap 가능

### 공통 규칙

- 프로젝트 근거가 거의 없으면 추정 기반 자동 생성보다 안전한 초기화가 우선이다
- 실행 가능한 코드, 설정, 테스트가 있으면 그것이 1차 근거다
- 문서만 있고 구현이 약하면 문서를 1차 근거로 본다
- 문서와 구현이 충돌하면 조용히 한쪽을 무시하지 말고 불일치를 드러낸다
- 추정으로 채운 내용은 확정 사실처럼 쓰지 않고, 가정 또는 TODO로 표시한다

### 구현 계획

1. 프로젝트 성숙도를 판단하는 휴리스틱을 정의한다.
2. `init.sh`의 AI 프롬프트를 분기형으로 바꾼다.
3. 문서 탐색 우선순위를 정한다.
4. 구현 탐색 우선순위를 정한다.
5. 문서/구현 불일치 보고 형식을 템플릿에 반영한다.
6. 샘플 프로젝트를 만들어 3개 모드를 각각 검증한다.

### 프로젝트 성숙도 판단 휴리스틱

다음 신호를 조합해 `blank-start / docs-first / hybrid / code-first`를 정한다.

- 문서 신호
  - `README.md`, `docs/`, `spec/`, `prd/`, `requirements/` 존재 여부
  - 요구사항/아키텍처/와이어프레임 문서의 밀도
- 구현 신호
  - `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml` 존재 여부
  - `src/`, `app/`, `backend/`, `frontend/` 등 실제 코드 디렉토리 존재 여부
  - 테스트 디렉토리 및 CI 설정 존재 여부
- 운영 신호
  - Docker, env example, deploy/workflow 파일 존재 여부

초기안:
- 의미 있는 문서/구현/테스트/운영 신호가 모두 거의 없으면 `blank-start`
- 문서는 충분하지만 실행 가능한 코드가 거의 없으면 `docs-first`
- 문서와 구현이 모두 있으면 `hybrid`
- 실행 가능한 코드/테스트/설정이 풍부하면 `code-first`

### 프롬프트 반영 방향

AI 자동 채우기 시 아래 원칙을 명시한다.

- `blank-start`: 확인 가능한 사실만 반영하고, 스택/명령어/도메인은 추정하지 않는다. 필요 시 AI 자동 채우기를 건너뛰고 재실행을 안내할 것
- `docs-first`: 문서를 기준으로 작성하되, 아직 구현되지 않은 내용은 "예정", "가정", "TODO"로 드러낼 것
- `hybrid`: 코드/설정을 먼저 검증하고, 문서는 설계 의도와 누락 보완용으로 사용할 것
- `code-first`: 실제 코드 상태를 우선하며, 문서와 다르면 불일치 항목을 짧게 남길 것

추가 확장 후보:
- `--archetype`, `--stack`, `--project-name` 같은 힌트 옵션을 받아 blank-start에서도 의도 기반 초안 생성
- blank-start에서 최소 플레이스홀더만 채운 lightweight bootstrap 모드

### 완료 기준

- 초기 프로젝트와 진행 중 프로젝트에 서로 다른 기준이 안정적으로 적용된다
- 빈 폴더에서 init을 먼저 실행해도 과추론 없이 안전하게 초기화된다
- `CLAUDE.md`, `AGENTS.md`가 실제 프로젝트 성숙도에 맞는 내용으로 채워진다
- 문서와 구현이 어긋날 때 그 차이가 기록된다
- 같은 프로젝트를 다시 실행해도 해석 기준이 크게 흔들리지 않는다

---

## Priority 2: 다언어/프레임워크/비웹 프로젝트 확장

> "웹 프로젝트에만 맞춘 설정이 아니라, 프로젝트 유형 전반을 커버한다"

### 왜 필요한가

현재 로드맵과 실제 예시는 웹/프론트엔드 문맥이 강하다. 하지만 `ai-setting`의 장기 방향은 특정 UI 스택용 스타터가 아니라, 다양한 언어와 프레임워크, 그리고 비웹 프로젝트까지 커버하는 공통 부트스트랩이어야 한다.

- 백엔드 API 프로젝트는 프론트엔드와 필요한 명령어/검증 방식이 다름
- CLI, 배치, 워커, 라이브러리 프로젝트는 브라우저 계열 MCP나 웹 기준 템플릿이 중요하지 않을 수 있음
- 데이터/ML, 인프라, 모바일, 데스크톱 프로젝트는 구조와 문서 기준이 완전히 다를 수 있음
- 언어/프레임워크별로 테스트/린트/실행 명령어와 안전장치가 달라 placeholder, hook, template가 달라져야 함

따라서 이후 고도화는 "웹도 잘 되게"가 아니라 "웹을 포함한 다양한 프로젝트를 공통 구조로 지원"하는 방향이어야 한다.

### 지원 목표 범위

초기 지원 목표는 아래처럼 프로젝트 유형과 언어/프레임워크를 분리해서 본다.

| 축 | 1차 목표 |
|----|----------|
| 프로젝트 유형 | 웹 프론트엔드, 백엔드 API, CLI, 워커/배치, 라이브러리/SDK, 데이터/자동화 스크립트, 인프라/IaC |
| 언어 | TypeScript/JavaScript, Python, Go, Rust |
| 확장 후보 | Java/Kotlin, C#, Ruby, PHP, Swift |
| 프레임워크 예시 | Next.js, React, FastAPI, Django, Flask, Express/Nest, Gin/Fiber, Axum/Actix, Terraform/Ansible |

### 설계 결론

앞으로는 "웹인지 아닌지"보다 먼저 "프로젝트 archetype"을 식별하고, 그 archetype에 맞는 설정을 주입한다.

예시 archetype:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `library-sdk`
- `data-automation`
- `infra-iac`

각 archetype은 아래를 다르게 가진다.
- 기본 명령어 placeholder
- 권장 MCP preset
- 템플릿 문구와 예시
- hook 기본값
- 추천 agents / skills

현재 상태:
- `init.sh`에서 1차 archetype 자동 감지(`frontend-web`, `backend-api`, `cli-tool`, `worker-batch`, `data-automation`, `library-sdk`, `infra-iac`, `general-app`)를 수행
- Next.js/Vite/Node/Python/Go/Rust/Java-Kotlin/Ruby/PHP 기준의 주 스택 감지를 함께 수행
- 감지 결과를 AI 자동 채우기 프롬프트에 주입해 프로젝트 유형에 맞는 명령어와 설명을 유도
- `--auto-mcp`로 감지된 archetype 기반 MCP 추천 preset(`web`, `infra`)을 자동 적용 가능

### 구현 계획

1. 프로젝트 archetype taxonomy를 정의한다.
2. 언어/프레임워크 감지 규칙을 만든다.
3. archetype별 placeholder 표준 세트를 만든다.
4. MCP preset도 archetype 기준으로 재구성한다.
5. 비웹 프로젝트 샘플 fixture를 추가한다.
6. 각 archetype에서 `init.sh --skip-ai`와 AI 자동 채우기를 모두 검증한다.

### 자동 감지 신호 예시

- 웹 프론트엔드
  - `next.config.*`, `vite.config.*`, `src/app`, `src/pages`, `package.json`
- 백엔드 API
  - `app/main.py`, `manage.py`, `pom.xml`, `build.gradle`, `main.go`
- CLI / 워커
  - `cmd/`, `bin/`, `click`, `typer`, `cobra`, `cron`, `queue`, `worker`
- 라이브러리 / SDK
  - 배포용 package metadata와 예제/문서 비중, 실행 entry보다 export/public API 중심 구조
- 인프라 / 자동화
  - `terraform/`, `ansible/`, `helm/`, `docker-compose.yml`, `.github/workflows/`

### 완료 기준

- 웹 프로젝트 외에도 백엔드, CLI, 워커, 라이브러리, 인프라 프로젝트에 맞는 기본 설정을 생성할 수 있다
- 특정 웹 전용 가정 없이 placeholder와 템플릿이 채워진다
- archetype 판단 결과를 사용자가 확인할 수 있다
- 새로운 언어/프레임워크 지원을 추가할 때 구조적으로 확장 가능하다

---

## Priority 3: Doctor / Safe Reapply / Diff Preview

> "반복 실행해도 안전하고, 무엇이 문제인지 바로 진단할 수 있다"

### 왜 필요한가

프로젝트 초기화 도구는 "한 번 설치"보다 "다시 실행해도 안전한가"와 "문제 발생 시 바로 원인을 찾을 수 있는가"가 중요하다.

- 의존성 누락(`jq`, `npx`, `uvx`, `docker`) 때문에 일부 기능만 동작할 수 있음
- 사용자가 이미 수정한 `.claude/`, `.codex/`, `.mcp.json`을 덮어쓸 수 있음
- MCP preset이나 hooks가 생성됐더라도 실제로 쓸 수 있는 상태인지 바로 알기 어려움
- diff 없이 재적용하면 어떤 파일이 바뀌는지 파악하기 힘듦

### 설계 결론

향후 `ai-setting`은 설치 도구가 아니라 "설치 + 진단 + 안전 재적용" 도구가 되어야 한다.

핵심 기능:
- `doctor`
  - 필수 바이너리, 설정 파일, hook 실행 가능 여부, placeholder 미치환 여부 점검
- `--dry-run`
  - 실제 파일 변경 없이 무엇이 생성/수정될지 출력
- `--backup-all`
  - `.claude`, `.codex`, `.mcp.json` 등 관리 대상 전체 백업
- `--reapply`
  - 기존 파일과 비교 후 안전하게 재적용
- `--diff`
  - 변경 전/후 차이를 미리 보여주기

현재 상태:
- `init.sh --doctor`로 기본 진단 실행 가능
- `init.sh --dry-run`으로 실제 변경 없는 작업 미리보기 가능
- `init.sh --diff`로 관리 대상 파일의 변경 내용을 unified diff로 확인 가능
- `init.sh --backup-all`로 관리 대상 전체 snapshot 백업 가능
- `init.sh --reapply`로 `CLAUDE.md`/`AGENTS.md` 재생성 + AI 채우기 재실행 가능
- 필수 바이너리, 핵심 파일 존재 여부, `.mcp.json` 형식, 플레이스홀더 잔존 여부를 점검
- `blank-start` 모드는 doctor에서도 예외 처리하여 플레이스홀더 잔존을 정상으로 간주

### 구현 계획

1. 관리 대상 파일 목록을 명시적으로 정의한다.
2. `doctor` 진단 규칙을 만든다.
3. `--dry-run`, `--diff`, `--backup-all` 흐름을 설계한다.
4. `init.sh` 반복 실행 시 overwrite 정책을 통일한다.
5. 결과 리포트 형식을 만든다.
6. 정상/부분 설치/충돌 상태 fixture로 회귀 검증한다.

### 완료 기준

- 사용자가 설치 전후 상태를 스스로 진단할 수 있다
- 반복 실행 시 기존 수동 수정이 예기치 않게 사라지지 않는다
- 어떤 파일이 왜 바뀌는지 미리 확인할 수 있다
- 문제 발생 시 "무엇이 빠졌는지"를 문서가 아니라 명령으로 확인할 수 있다

## 현재 상태 (v1-beta)

```
init.sh 실행 → profile 적용 → 로컬 MCP preset 생성 → 템플릿 복사 → 프로젝트 모드/archetype 감지 → AI가 템플릿 채우기
```

- Claude Code: `standard` / `minimal` profile, hooks, agents 4개, skills 5개
- Multi-tool: Cursor, Gemini CLI, GitHub Copilot 1차 지원
- Codex: `config.toml` + 프로젝트 로컬 MCP preset
- Safety: `doctor`, `dry-run`, `diff`, `backup-all`, `reapply`
- Detection: `blank-start / docs-first / hybrid / code-first`, archetype / stack 자동 감지, `--auto-mcp`
- Templates: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `docs/decisions.md`
- 현재 한계: 동기화 시스템 미구현, 플러그인/배포 경로 미구현

---

## Phase 1: 멀티 도구 지원

> "AI 도구가 뭐든 같은 규칙이 적용된다"

현재 상태:
- Cursor 지원: `.cursor/rules/ai-setting.mdc` 생성
- Gemini CLI 지원: `.gemini/settings.json`, `GEMINI.md` 생성
- GitHub Copilot 지원: `.github/copilot-instructions.md` 생성
- `doctor / diff / backup-all / reapply`도 새 관리 대상 파일을 함께 인식

### 1-1. Cursor 지원 추가
- `.cursor/rules/*.mdc` 파일 생성
- AGENTS.md 템플릿의 Coding Rules를 `.mdc` 형식으로 변환
- init.sh에 `.cursor/rules/` 복사 추가
- **난이도**: 쉬움 (포맷 변환만)
- **참고**: cursorrules.org, awesome-cursorrules

### 1-2. Gemini CLI 지원 추가
- `.gemini/settings.json` 템플릿
- `GEMINI.md` (= CLAUDE.md의 Gemini 버전)
- init.sh에 `.gemini/` 복사 추가
- **난이도**: 쉬움 (JSON 템플릿)
- **참고**: geminicli.com/docs/reference/configuration/

### 1-3. GitHub Copilot 지원 추가
- `.github/copilot-instructions.md` 생성
- AGENTS.md의 규칙을 Copilot 형식으로 변환
- **난이도**: 쉬움

### 결과
```
init.sh 실행 후:
  .claude/      → Claude Code
  .codex/       → Codex CLI
  .cursor/      → Cursor
  .gemini/      → Gemini CLI
  .github/      → GitHub Copilot
```

---

## Phase 2: 동기화 시스템

> "한 곳을 고치면 모든 프로젝트에 반영된다"

### 2-1. Symlink 기반 동기화 (stow 패턴)
현재 방식 (복사):
```
ai-setting/ --cp--> project-a/.claude/
            --cp--> project-b/.claude/
            --cp--> project-c/.claude/
# ai-setting 업데이트해도 프로젝트에는 반영 안 됨
```

개선 방식 (심링크):
```
~/.ai-setting/claude/ <--symlink-- project-a/.claude/
                      <--symlink-- project-b/.claude/
                      <--symlink-- project-c/.claude/
# ai-setting 업데이트하면 모든 프로젝트에 즉시 반영
```

- `init.sh --link` 옵션 추가 (복사 대신 심링크)
- 프로젝트별 오버라이드: `.claude/settings.local.json` 같은 로컬 설정
- **난이도**: 쉬움
- **참고**: GNU Stow, agentsync, AI dotfiles 패턴

### 2-2. 업데이트 명령
```bash
# 원본이 업데이트된 후 프로젝트에 반영
ai-setting update /path/to/project

# 또는 심링크 모드에서는 git pull만 하면 됨
cd ~/.ai-setting && git pull
```

---

## Phase 3: 프로필 시스템

> "프로젝트 성격에 따라 다른 설정을 적용한다"

현재 상태:
- `init.sh --profile standard|minimal|strict|team` 지원
- `standard`는 기존 전체 설정을 유지
- `minimal`은 `protect-files + auto-format`만 활성화하고 managed agents/skills는 복사하지 않음
- `strict`는 branch 보호 hook을 추가
- `team`은 `strict` 기반 + PR 템플릿 생성

### 프로필 구조
```
ai-setting/
├── profiles/
│   ├── standard/     # 현재 기본값 (균형잡힌 설정)
│   ├── strict/       # 보안 강화, 모든 체크 활성화
│   ├── minimal/      # 최소 설정 (hooks + 포맷터만)
│   └── team/         # 팀 프로젝트용 (리뷰 강화, PR 규칙)
```

### 프로필별 차이

| 항목 | minimal | standard | strict | team |
|------|---------|----------|--------|------|
| protect-files hook | ✅ | ✅ | ✅ | ✅ |
| block-commands hook | — | ✅ | ✅ | ✅ |
| auto-format hook | ✅ | ✅ | ✅ | ✅ |
| notification / stop / reminder | — | ✅ | ✅ | ✅ |
| agents 4개 | — | ✅ | ✅ | ✅ |
| skills 5개 | — | ✅ | ✅ | ✅ |
| branch 보호 hook | — | — | ✅ | ✅ |
| PR 템플릿 | — | — | — | ✅ |

### 사용법
```bash
# 기본 (standard)
init.sh /path/to/project

# 프로필 지정
init.sh --profile minimal /path/to/project
init.sh --profile standard /path/to/project
init.sh --profile strict /path/to/project
init.sh --profile team /path/to/project
```

- **난이도**: 중간
- **참고**: rulebook-ai의 packs 시스템, Trail of Bits 보안 프로필

---

## Phase 4: 플러그인 마켓플레이스

> "다른 사람들이 만든 에이전트/스킬을 설치하고, 내 것도 공유한다"

### Claude Code 플러그인 형식
```json
// .claude-plugin/marketplace.json
{
  "name": "ai-setting",
  "version": "1.0.0",
  "description": "AI 코딩 도구 공통 설정",
  "components": {
    "agents": ["security-reviewer", "architect-reviewer", ...],
    "skills": ["deploy", "review", "gap-check", ...],
    "hooks": ["protect-files", "block-dangerous-commands"]
  }
}
```

### 사용법 (마켓플레이스 등록 후)
```
/plugin marketplace add jaewon/ai-setting
/plugin marketplace update
```

- init.sh 없이 Claude Code 안에서 바로 설치
- 업데이트 자동 전파
- **난이도**: 중간
- **참고**: anthropics/claude-plugins-official, SkillsMP

---

## Phase 5: 고급 hooks

> "더 똑똑한 자동화"

### 5-1. 브랜치 보호 hook
```bash
# main/master 브랜치에 직접 커밋 차단
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "Blocked: 직접 커밋 금지. feat/fix 브랜치에서 PR로 머지하세요." >&2
  exit 2
fi
```

### 5-2. 비동기 테스트 실행 hook
- PostToolUse에서 코드 변경 감지 시 백그라운드로 테스트 실행
- 결과를 다음 프롬프트에 주입

### 5-3. Slack/Discord 알림 hook
- HTTP hook으로 작업 완료/실패 시 팀 채널에 알림
- `"type": "command"` → `curl -X POST webhook_url`

### 5-4. 컴팩션 컨텍스트 주입 hook
- PreCompact 시점에 핵심 컨텍스트를 별도 파일에 백업
- SessionStart에서 복원

- **난이도**: 쉬움~중간
- **참고**: claude-code-hooks-mastery, pixelmojo CI/CD 패턴

---

## Phase 6: 커뮤니티 & 배포

> "더 많은 사람이 쓰고, 더 많은 사람이 기여한다"

현재 상태:
- `CONTRIBUTING.md` 추가
- 기능 추가 시 검증/문서/커밋 규칙을 저장소 내부 기준으로 문서화
- public 전환, 패키지화, 커뮤니티 배포는 아직 미진행

### 6-1. sync-conf.dev 등록
- 커뮤니티 디렉토리에 등록하여 `npx sync-conf install jaewon/ai-setting`으로 설치 가능

### 6-2. npm/brew 패키지화
```bash
# npm
npx ai-setting init /path/to/project

# 또는 brew
brew install ai-setting
ai-setting init /path/to/project
```

### 6-3. public 전환 + 기여 가이드
- 현재 private → public 전환
- CONTRIBUTING.md (에이전트/스킬 추가 방법)
- 프로필/언어별 기여 가이드

---

## 우선순위 요약

| Phase | 핵심 | 난이도 | 효과 |
|-------|------|--------|------|
| **Priority 0** | 프로젝트 로컬 MCP preset | 중간 | 재현성 확보, 온보딩 비용 감소 |
| **Priority 1** | docs-first / hybrid / code-first 분기 | 중간 | 초기/진행 프로젝트 모두 정확도 향상 |
| **Priority 2** | 다언어/프레임워크/비웹 프로젝트 확장 | 중간~높음 | 웹 편향 제거, 적용 범위 확대 |
| **Priority 3** | doctor / safe reapply / diff preview | 중간 | 반복 실행 안전성, 문제 진단성 향상 |
| **Phase 1** | Cursor/Gemini/Copilot 지원 | 쉬움 | 사용자 3배 확대 |
| **Phase 2** | Symlink 동기화 | 쉬움 | 유지보수 비용 제거 |
| **Phase 3** | 프로필 시스템 | 중간 | 포크 방지, 맞춤 적용 |
| **Phase 4** | 플러그인 마켓플레이스 | 중간 | 네이티브 배포, 자동 업데이트 |
| **Phase 5** | 고급 hooks | 쉬움~중간 | 자동화 강화 |
| **Phase 6** | 커뮤니티 & 배포 | 쉬움~중간 | 생태계 참여 |

### 권장 순서
1. **Priority 0 (프로젝트 로컬 MCP)** — 재현 가능한 기본 개발 환경 확보
2. **Priority 1 (문서/구현 분기)** — 프로젝트 성숙도에 맞는 해석 기준 확보
3. **Priority 2 (다언어/비웹 확장)** — 웹 편향 제거, archetype 기반 지원 구조 확보
4. **Priority 3 (doctor / safe reapply)** — 운영 안정성 확보
5. **Phase 1-1 (Cursor)** + **Phase 2-1 (Symlink)** — 가장 빠르게 가장 큰 효과
6. **Phase 3 (프로필)** — 다양한 프로젝트 대응
7. **Phase 5-1 (브랜치 보호)** — 바로 추가 가능한 실용 hook
8. 나머지는 필요에 따라

---

## 참고 자료

- [rulebook-ai](https://github.com/botingw/rulebook-ai) — 멀티 도구 규칙 생성
- [sync-conf.dev](https://sync-conf.dev/) — Git 기반 설정 동기화
- [agentsync](https://github.com/dallay/agentsync) — Rust CLI 심링크 동기화
- [agent-sync](https://github.com/ZacheryGlass/agent-sync) — 통합 동기화 도구
- [Trail of Bits claude-code-config](https://github.com/trailofbits/claude-code-config) — 보안 중심 설정
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 65+ 스킬, 12+ 에이전트
- [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) — 127+ 서브에이전트
- [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) — 549+ 스킬
- [cursorrules.org](https://cursorrules.org/) — Cursor 규칙 생성기
- [Claude Code Plugin Marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
- [Gemini CLI Configuration](https://geminicli.com/docs/reference/configuration/)
- [Codex CLI Config Reference](https://developers.openai.com/codex/config-reference/)
- [AI Dotfiles 패턴](https://dylanbochman.com/blog/2026-01-25-dotfiles-for-ai-assisted-development/)
