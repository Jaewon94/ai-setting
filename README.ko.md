한국어 | [English](README.md)

# AI Setting

Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot용 프로젝트 설정을 한 번에 부트스트랩하는 도구입니다.

새 프로젝트를 시작하거나 기존 프로젝트의 AI 도구 설정을 다시 맞출 때, `.claude`, `.codex`, `.cursor`, `.gemini`, `.github` 파일을 매번 손으로 조립하지 않도록 만드는 저장소입니다.

기여나 확장 방법은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요.

## 빠른 시작

```bash
# 기본: Claude Code만 적용
./bin/ai-setting /path/to/project

# 여러 도구 같이 적용
./bin/ai-setting --tools claude,cursor,codex /path/to/project

# 지원 도구 전부 적용
./bin/ai-setting --all /path/to/project

# 나중에 도구 추가
./bin/ai-setting add-tool gemini /path/to/project

# 기존 프로젝트의 공유 자산만 업데이트
./bin/ai-setting update /path/to/project

# 여러 프로젝트 동기화
./bin/ai-setting sync ./projects.manifest
```

## 이걸로 얻는 것

- Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot 멀티 도구 부트스트랩
- Claude 프로필: `standard`, `minimal`, `strict`, `team`
- 안전/유지보수 명령: `doctor`, `dry-run`, `diff`, `backup-all`, `reapply`
- 프로젝트 로컬 MCP preset 생성
- Claude 우선, Codex fallback 구조의 AI 자동 채우기
- 여러 프로젝트를 맞추는 sync 흐름
- macOS, Windows, Linux 기준으로 검증한 bash hook 흐름

## 핵심 흐름

```text
init.sh
  -> 공통 설정 복사/심링크
  -> 프로젝트 로컬 MCP 생성
  -> 문서/템플릿 생성
  -> Claude Code로 자동 채우기
  -> 필요 시 Codex로 fallback
```

## 프로필 선택

| 프로필 | 이런 경우에 적합 |
|--------|------------------|
| `standard` | 기본 팀/개인 사용 |
| `minimal` | 최소 훅만 두고 관리 자산을 줄이고 싶을 때 |
| `strict` | main/master 보호 등 강한 안전장치가 필요할 때 |
| `team` | strict + PR 템플릿/웹훅 스캐폴딩이 필요할 때 |

## MCP Preset

기본값은 `core`입니다.

| preset | 포함 서버 |
|--------|-----------|
| `core` | `sequential-thinking`, `serena`, `upstash-context-7-mcp` |
| `web` | `playwright` |
| `infra` | `docker` |
| `local` | `filesystem`, `fetch` |

메모:
- `.mcp.json`은 JSON 파싱을 깨지 않도록 주석 없이 유지합니다.
- 대신 `.mcp.notes.md`를 같이 생성해서 API 키, 절대 경로 같은 수동 입력값을 안내합니다.
- `.codex/config.toml`은 TOML이라 필요한 경우 인라인 주석을 함께 넣을 수 있습니다.

## 패키지 / 실행 메모

```bash
npx @jaewon94/ai-setting --help
npx @jaewon94/ai-setting /path/to/project
```

- npm 패키지: `@jaewon94/ai-setting`
- Windows에서는 생성되는 훅과 래퍼 실행에 `bash`가 필요합니다.
- Windows 권장 환경: Git Bash
- `cmd.exe`나 PowerShell에서 쓰려면:

```bash
npm config set script-shell "C:\Program Files\Git\bin\bash.exe"
```

## 문서 안내

README는 진입 문서만 맡고, 상세 설명은 아래로 분리했습니다.

- [docs/usage.ko.md](docs/usage.ko.md): 명령, 옵션, update/sync 흐름, MCP 사용, plugin 사용
- [docs/reference.ko.md](docs/reference.ko.md): 생성 파일, 프로필, 훅/에이전트/스킬 상세, 감지 로직
- [docs/deployment-checklist.md](docs/deployment-checklist.md): npm/release/Homebrew 검증
- [docs/plugin-guide.md](docs/plugin-guide.md): 플러그인 작성/패키징 가이드
- [docs/roadmap.md](docs/roadmap.md): 로드맵
- [docs/issues.md](docs/issues.md): 이슈 이력과 검증 메모
- 실전 검증 문서:
  - [docs/field-test-kobot.md](docs/field-test-kobot.md)
  - [docs/field-test-research-traceability.md](docs/field-test-research-traceability.md)
  - [docs/field-test-ai-autofill.md](docs/field-test-ai-autofill.md)
  - [docs/field-test-python-backend.md](docs/field-test-python-backend.md)

## 적용 후 기본 확인

- `./bin/ai-setting --doctor /path/to/project` 실행
- 생성된 `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, Copilot instructions 확인
- 감지된 archetype/stack이 프로젝트와 맞는지 확인
- AI 자동 채우기가 건너뛰어졌다면 대괄호 섹션을 수동 보정하거나 나중에 다시 실행

## 생성되는 자산 요약

- `.claude/` : Claude Code 설정, hooks, agents, skills
- `.codex/config.toml` : Codex CLI 설정 + MCP
- `.cursor/rules/*.mdc` : Cursor rules
- `.gemini/settings.json`, `GEMINI.md` : Gemini CLI
- `.github/copilot-instructions.md`, path-specific instructions : Copilot
- `CLAUDE.md`, `AGENTS.md`, `BEHAVIORAL_CORE.md`
- `docs/decisions.md`, `docs/research-notes.md`
- `.mcp.json`, `.mcp.notes.md`
