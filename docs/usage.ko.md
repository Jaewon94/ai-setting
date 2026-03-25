# 사용 가이드

이 문서는 메인 README 이후 실제 사용 방법만 빠르게 찾기 위한 문서입니다.

## 주요 명령

```bash
./bin/ai-setting [options] /path/to/project
./bin/ai-setting update [options] /path/to/project
./bin/ai-setting sync [options] ./projects.manifest
./bin/ai-setting add-tool <tool> /path/to/project
./bin/ai-setting plugin {list|install|uninstall|check-update|upgrade} [name] [target]
```

## 자주 쓰는 예시

```bash
# Claude Code만 적용
./bin/ai-setting /path/to/project

# 특정 도구 조합
./bin/ai-setting --tools claude,cursor /path/to/project

# 지원 도구 전부
./bin/ai-setting --all /path/to/project

# minimal 프로필
./bin/ai-setting --profile minimal /path/to/project

# strict 보호 장치
./bin/ai-setting --profile strict /path/to/project

# AI 자동 채우기 건너뛰기
./bin/ai-setting --skip-ai /path/to/project

# 추천 MCP 자동 적용
./bin/ai-setting --auto-mcp /path/to/project

# 나중에 도구 추가
./bin/ai-setting add-tool codex /path/to/project
```

## 프로필

| 프로필 | 포함 내용 |
|--------|-----------|
| `standard` | 기본 hooks, agents, skills |
| `minimal` | 최소 hooks만 유지, 관리 자산 축소 |
| `strict` | `standard` + main/master 보호 |
| `team` | `strict` + PR 템플릿 + 웹훅 스캐폴딩 |

프로필 전환 시:
- 기존 `.claude/`는 먼저 백업
- ai-setting 관리 자산은 선택한 프로필 기준으로 재정렬
- 사용자 파일은 관리 범위 밖이면 그대로 유지

## MCP 사용

### Preset

| preset | 서버 |
|--------|------|
| `core` | `sequential-thinking`, `serena`, `upstash-context-7-mcp` |
| `web` | `playwright` |
| `infra` | `docker` |
| `local` | `filesystem`, `fetch` |

### 예시

```bash
# 웹 자동화 추가
./bin/ai-setting --mcp-preset web /path/to/project

# 인프라 도구 추가
./bin/ai-setting --mcp-preset infra /path/to/project

# 조합 사용
./bin/ai-setting --mcp-preset web,infra /path/to/project

# archetype 기반 자동 추천
./bin/ai-setting --auto-mcp /path/to/project

# 프로젝트 로컬 MCP 건너뛰기
./bin/ai-setting --no-mcp /path/to/project
```

### 수동 입력값

- `.mcp.json`은 실제 실행되는 JSON 설정
- `.mcp.notes.md`는 API 키, 절대 경로 같은 수동 입력값 안내
- `.codex/config.toml`은 필요한 경우 인라인 주석 포함 가능

## Update 모드

기존 프로젝트의 공유 자산만 최신 상태로 맞추고 싶을 때 사용합니다.

```bash
./bin/ai-setting update /path/to/project
```

동작:
- 공유 설정과 MCP를 최신화
- `CLAUDE.md`, `AGENTS.md` 같은 프로젝트 문서는 유지
- AI 자동 채우기는 실행하지 않음

## Sync 모드

여러 프로젝트를 manifest로 한 번에 맞추는 기능입니다.

```bash
./bin/ai-setting sync ./projects.manifest
./bin/ai-setting sync --sync-mode init ./projects.manifest
./bin/ai-setting sync --sync-conflict skip ./projects.manifest
```

manifest 예시:

```text
# projects.manifest
../storyforge
../taskrelay profile=strict mcp-preset=core,web
../internal-tool profile=minimal archetype=cli-tool
```

프로젝트별 옵션:
- `profile=`
- `mcp-preset=`
- `archetype=`
- `stack=`

충돌 처리:
- `backup` 기본값: 백업 후 덮어쓰기
- `skip`: 해당 프로젝트 건너뜀
- `overwrite`: 바로 덮어쓰기

## Link 모드

```bash
./bin/ai-setting --link /path/to/project
./bin/ai-setting --link-dir /path/to/project
```

- `--link`: 공유 자산을 파일 단위 심링크
- `--link-dir`: `.claude/hooks`, `.claude/agents`, `.claude/skills`를 디렉토리 단위 심링크

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

## 프로젝트 해석 힌트

빈 프로젝트나 애매한 프로젝트는 힌트로 보정할 수 있습니다.

```bash
./bin/ai-setting \
  --project-name my-api \
  --archetype backend-api \
  --stack Python \
  /path/to/project
```

지원 archetype:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app`

## 유지보수 명령

### Doctor

```bash
./bin/ai-setting --doctor /path/to/project
```

확인 항목:
- 필수 바이너리
- hook 준비 상태
- MCP JSON 유효성
- 남은 placeholder
- copy / symlink 모드
- async test 명령 존재 여부

### Dry Run

```bash
./bin/ai-setting --dry-run /path/to/project
```

실제 파일 변경 없이 예정 작업만 보여줍니다.

### Diff

```bash
./bin/ai-setting --diff /path/to/project
```

관리 대상 파일 diff를 미리 보여줍니다.

### Backup All

```bash
./bin/ai-setting --backup-all /path/to/project
```

적용 전 관리 대상 전체 스냅샷 백업을 만듭니다.

### Reapply

```bash
./bin/ai-setting --reapply /path/to/project
```

프로젝트 문서를 새 템플릿 기준으로 다시 만들고 AI 자동 채우기를 다시 실행합니다.

권장 조합:

```bash
./bin/ai-setting --backup-all --reapply /path/to/project
```

## Plugin 명령

포함된 플러그인:
- `ai-setting-core`
- `ai-setting-strict`
- `ai-setting-team`

예시:

```bash
./bin/ai-setting plugin list
./bin/ai-setting plugin install ai-setting-strict /path/to/project
./bin/ai-setting plugin check-update /path/to/project
./bin/ai-setting plugin uninstall ai-setting-strict /path/to/project
./bin/ai-setting plugin upgrade ai-setting-strict /path/to/project
```

플러그인 제작은 [plugin-guide.md](plugin-guide.md)를 참고하세요.

## 플랫폼 메모

- macOS, Windows, Linux 모두 지원 대상입니다.
- 생성되는 hooks는 bash 기반입니다.
- Windows는 Git Bash 권장입니다.
- `cmd.exe`나 PowerShell에서는:

```bash
npm config set script-shell "C:\Program Files\Git\bin\bash.exe"
```

## 관련 문서

- [reference.ko.md](reference.ko.md)
- [deployment-checklist.md](deployment-checklist.md)
- [roadmap.md](roadmap.md)
- [issues.md](issues.md)
