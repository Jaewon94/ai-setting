# 레퍼런스

## 지원 도구

| 도구 | 생성 파일 | 메모 |
|------|-----------|------|
| Claude Code | `.claude/`, `CLAUDE.md` | 기본 통합 대상, profile/도구 역할 분담 가이드 포함 |
| Codex CLI | `.codex/config.toml`, `.codex/config.notes.md`, `AGENTS.md` | AGENTS.md는 디렉토리 계층에서 자동 탐색 |
| Cursor | `.cursor/rules/*.mdc` | 공통 rule + stack/archetype rule 생성, `@file`은 Cursor 제품 측 이슈 영향 |
| Gemini CLI | `.gemini/settings.json`, `.gemini/settings.notes.md`, `GEMINI.md` | 설정 파일 + 수동 조정 notes + 컨텍스트 문서 |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | 저장소 지침 + stack/archetype path-specific instructions |

## 생성 자산 범주

- `.claude/settings.json`
- `.claude/hooks/*`
- `.claude/agents/*`
- `.claude/skills/*`
- `.cursor/rules/*`
- `.gemini/settings.json`
- `.gemini/settings.notes.md`
- `.codex/config.toml`
- `.codex/config.notes.md`
- `.mcp.json`
- `.mcp.notes.md`
- `.ai-setting/protect-files.json`
- `.ai-setting/protect-files.notes.md`
- `CLAUDE.md`
- `AGENTS.md`
- `GEMINI.md`
- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `docs/decisions.md`
- `docs/research-notes.md`

## 프로필

| 프로필 | 동작 |
|--------|------|
| `standard` | 기본 hooks, agents, skills |
| `minimal` | 최소 hooks만 유지, 관리 agents/skills는 복사하지 않음 |
| `strict` | `standard` + main/master 직접 git 작업 보호 |
| `team` | `strict` + PR 템플릿 + 웹훅 메타 설정 |

## 프로젝트 해석 모드

AI 자동 채우기 전에 `init.sh`는 프로젝트를 4가지 모드 중 하나로 분류합니다.

| 모드 | 의미 |
|------|------|
| `blank-start` | 프로젝트 신호가 거의 없음 |
| `docs-first` | 문서 신호가 구현 신호보다 강함 |
| `hybrid` | 문서와 구현 신호를 함께 봐야 함 |
| `code-first` | 구현/테스트 신호가 충분함 |

신호 예시:
- 문서: `README.md`, `docs/`, `spec/`, `prd/`
- 구현: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `src/`, `app/`, `backend/`, `frontend/`
- 테스트/운영: `tests/`, workflow, Docker 관련 파일, `.env.example`

## Archetype / Stack 감지

지원 archetype:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app`

감지 가능한 스택 예시:
- `Next.js`
- `Vite`
- `Node.js / TypeScript`
- `Python`
- `Go`
- `Rust`
- `Java / Kotlin`
- `Ruby`
- `PHP`

archetype 특화 반영:
- `CLAUDE.md`는 archetype partial을 자동 삽입
- `AGENTS.md`도 archetype별 agent rules partial을 자동 삽입

## Link / Copy 동작

`--link`:
- 공유 자산을 파일 단위로 심링크

`--link-dir`:
- hooks, agents, skills를 디렉토리 단위로 심링크

항상 로컬 파일로 유지되는 것:
- `CLAUDE.md`
- `AGENTS.md`
- `GEMINI.md`
- `.github/copilot-instructions.md`
- `.github/pull_request_template.md`
- `.codex/config.toml`
- `.mcp.json`
- `.mcp.notes.md`
- `docs/decisions.md`
- `docs/research-notes.md`

## Hooks

| Hook | 트리거 | 역할 |
|------|--------|------|
| `protect-files.sh` | 편집 전 | 민감 파일 편집 차단 |
| `block-dangerous-commands.sh` | Bash 실행 전 | 위험 명령 차단 |
| `format-on-write.sh` | Edit/Write 후 | 가장 가까운 프로젝트 마커 기준으로 포맷터 실행 |
| `async-test.sh` | Edit/Write 후 | 백그라운드 테스트 실행 |
| `compact-backup.sh` | Stop / compact 시작 | compact 복구용 스냅샷 |
| `session-context.sh` | Stop / compact 시작 | 세션 컨텍스트 보존 |
| `protect-main-branch.sh` | git 민감 흐름 | strict/team 브랜치 보호 |
| `team-webhook-notify.sh` | Stop | 팀 웹훅 알림 |

관련 자동 동작:
- Python 포맷: `ruff`
- TS/JS 포맷: `prettier`
- 알림 hook
- 세션 컨텍스트 / compact 복구 흐름

## Agents

| Agent | 역할 |
|-------|------|
| `security-reviewer` | 보안 리뷰 |
| `architect-reviewer` | 아키텍처 리뷰 |
| `test-writer` | 테스트 생성 |
| `research` | 검색/문서 도구 기반 리서치 |

## Skills

| Skill | 역할 |
|-------|------|
| `deploy` | 배포 체크/배포 흐름 |
| `review` | 리뷰 체크리스트 |
| `fix-issue` | 이슈 해결 워크플로 |
| `gap-check` | 누락 요구사항 탐지 |
| `cross-validate` | AI 결과와 실제 상태 교차 검증 |
| `document-feature` | 기능 단위 문서 구조화 |
| `document-infra` | 인프라 운영 문서 구조화 |
| `document-security` | 보안 구현/운영 문서 구조화 |

운영 메타데이터:
- `.claude/skills/metadata.json`
  - `category`
  - `explicit_only`
  - `profile_scope`
  - `required_tools`
  - `required_mcp`
  - `risk_level`

## Hook 메타데이터

- `.claude/hooks/metadata.json`
  - `event`
  - `matcher`
  - `type`
  - `blocking_or_async`
  - `profile_scope`
  - `risk_level`
  - `requires_network_or_secret`

## MCP 설정

위치:
- `.codex/config.toml`
- `.mcp.json`
- `.mcp.notes.md`
- `.ai-setting/protect-files.json`
- `.ai-setting/protect-files.notes.md`

기본 preset:
- `core`
- 선택 `web`
- 선택 `infra`
- 선택 `local`

수동 입력값 처리:
- `.mcp.json`에는 JSON 주석을 넣지 않음
- 설명은 `.mcp.notes.md`에 둠
- Codex 쪽 주석은 TOML에 기록 가능

## 보호 패턴

`protect-files.sh` 정책:
- 즉시 차단:
  - credential 파일
  - 특정 DB/key 확장자
  - 생성물/build/cache 디렉토리
- 확인 후 허용:
  - `.env*`
  - lock 파일
  - `docker-compose*.yml`
  - `.github/workflows/*`
- 프로젝트 override:
  - `.ai-setting/protect-files.json`으로 `allow` / `confirm` / `block` 조정 가능
  - 단, 기본 hard-block 항목은 override로 해제할 수 없음

`block-dangerous-commands.sh`가 막는 패턴 예시:
- `rm -rf`
- `sudo`
- `git push --force`
- `git reset --hard`
- 파괴적 SQL
- raw device write

## Async Test 동작

우선순위:
- `.ai-setting/test-command`
- `AI_SETTING_ASYNC_TEST_CMD`
- 자동 감지

자동 감지는 monorepo를 고려해 가장 가까운 프로젝트 마커를 탐색합니다.

## 구조

상위 구조:

```text
ai-setting/
├── bin/
├── claude/
├── codex/
├── cursor/
├── gemini/
├── plugins/
├── templates/
├── lib/
├── tests/
└── docs/
```

중요 구현 위치:
- `init.sh`: 얇은 메인 엔트리와 모드 오케스트레이션
- `lib/cli.sh`: CLI 파싱, 서브커맨드 전처리, 모드 검증
- `lib/deps.sh`: jq 의존성 점검
- `lib/init-flow.sh`: Step 1~5 실행, 템플릿 복사, 요약 출력
- `lib/ai-autofill.sh`: AI 자동 채우기와 Claude/Codex fallback
- `lib/profile.sh`: 도구/프로필 자산 적용
- `lib/mcp.sh`: MCP 생성
- `lib/doctor.sh`: 진단과 diff
- `lib/sync.sh`: manifest 기반 sync
