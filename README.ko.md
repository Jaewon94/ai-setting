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

# 기존 Claude settings를 유지하면서 ai-setting hook만 병합
./bin/ai-setting --merge /path/to/project

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

## 도구 지원 현황

| 도구 | 지원 수준 | 현재 강점 |
|------|-----------|-----------|
| Claude Code | ★★★★ | 프로필, hooks, agents, skills, archetype 반영 `CLAUDE.md` |
| Codex CLI | ★★★★ | 프로필별 config, notes, MCP preset, `AGENTS.md` 자동 탐색 |
| Cursor | ★★★☆ | 공통 + stack/archetype rule, docs/testing rule, 외부 `@file` 이슈 문서화 |
| Gemini CLI | ★★★☆ | 프로젝트 설정, notes, `GEMINI.md`, `AGENTS.md` context 로딩 |
| GitHub Copilot | ★★★☆ | 저장소 지침 + stack/archetype path-specific instructions |

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
| `git` | `mcp-server-git` |
| `chrome` | `chrome-devtools-mcp` |
| `next` | `next-devtools-mcp` |
| `local` | `filesystem`, `fetch` |

메모:
- `.mcp.json`은 JSON 파싱을 깨지 않도록 주석 없이 유지합니다.
- 대신 `.mcp.notes.md`를 같이 생성해서 API 키, 절대 경로 같은 수동 입력값을 안내합니다.
- `.codex/config.toml`은 TOML이라 필요한 경우 인라인 주석을 함께 넣을 수 있습니다.
- `git`은 opt-in preset이며 기본값으로 프로젝트 루트 저장소 경로를 사용하므로, 민감한 저장소에서는 범위를 먼저 검토해야 합니다.
- `chrome`은 `web`과 별도로 opt-in 브라우저 디버깅 preset이고, `next`는 Next.js 스택 감지 시 `--auto-mcp`에서 자동 추천됩니다.

## 패키지 / 실행 메모

```bash
npx @jaewon94/ai-setting --help
npx @jaewon94/ai-setting /path/to/project
brew install Jaewon94/ai-setting/ai-setting
ai-setting --help
```

- npm 패키지: `@jaewon94/ai-setting`
- Homebrew tap: `Jaewon94/ai-setting`
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
- [docs/plans/execution-plan.ko.md](docs/plans/execution-plan.ko.md): 현재 상위 실행 순서와 문서 우선 정리 계획
- [docs/deployment-checklist.md](docs/deployment-checklist.md): npm/release/Homebrew 검증
- [docs/distribution/README.ko.md](docs/distribution/README.ko.md): npm/Homebrew 배포 운영 문서
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
- 프로젝트에 기존 `.claude/settings.json`이 있다면 덮어쓰기 전에 `--merge`를 우선 검토
- AI 자동 채우기가 건너뛰어졌다면 대괄호 섹션을 수동 보정하거나 나중에 다시 실행

## 검증 루프

개발 중에는 변경 범위에 맞는 빠른 검증만 먼저 돌리고, 마지막에만 전체 스위트를 1회 실행합니다.

```bash
# hooks / 보안 정책 변경
./tests/test_hooks.sh

# profile / 설치 경로 / metadata 변경
./tests/test_profiles.sh

# init / doctor / 템플릿 / locale 변경
./tests/test_basic.sh

# 마지막 게이트에서만
./tests/run_all.sh
```

- Windows + Git Bash에서는 `./tests/run_all.sh`가 빠른 스위트보다 훨씬 오래 걸릴 수 있습니다.
- `ai-setting`을 설치해서 사용하는 downstream 프로젝트에서도 같은 원칙을 권장합니다. 먼저 범위별 빠른 확인을 하고, 마지막에만 전체 검증을 1회 수행합니다.

## 생성되는 자산 요약

- `.claude/` : Claude Code 설정, hooks, agents, skills
- `.codex/config.toml` : Codex CLI 설정 + MCP
- `.cursor/rules/*.mdc` : Cursor rules
- `.gemini/settings.json`, `GEMINI.md` : Gemini CLI
- `.github/copilot-instructions.md`, path-specific instructions : Copilot
- `CLAUDE.md`, `AGENTS.md`, `BEHAVIORAL_CORE.md`
- `docs/decisions.md`, `docs/research-notes.md`
- `.mcp.json`, `.mcp.notes.md`
