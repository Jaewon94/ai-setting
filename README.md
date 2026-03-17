# AI Setting - 새 프로젝트용 AI 도구 공통 설정

> 새 프로젝트에 Claude Code, Codex 등 AI 코딩 도구 설정을 한 번에 적용.
> StoryForge, TaskRelay + 커뮤니티 베스트 프랙티스에서 추출.

기여나 확장 작업은 [CONTRIBUTING.md](/Users/jaewon/my-project/ai-setting/CONTRIBUTING.md)를 기준으로 진행하면 됩니다.

## 빠른 시작

```bash
# 저장소 안에서 바로 ai-setting 커맨드 형태로 실행
cd /path/to/ai-setting
./bin/ai-setting /path/to/my-new-project

# 웹 프로젝트용 MCP까지 같이 넣기
./bin/ai-setting --mcp-preset web /path/to/my-new-project

# Claude minimal profile로 가볍게 시작
./bin/ai-setting --profile minimal /path/to/my-new-project

# strict profile로 보호 장치 강화
./bin/ai-setting --profile strict /path/to/my-new-project

# 공유 자산은 심링크로, 프로젝트 문서는 로컬 파일로 유지
./bin/ai-setting --link /path/to/my-new-project

# 기존 프로젝트의 공유 자산/MCP만 빠르게 업데이트
./bin/ai-setting update /path/to/my-new-project

# 여러 프로젝트를 manifest 기준으로 한 번에 동기화
./bin/ai-setting sync ./projects.manifest

# 기존처럼 init.sh를 직접 실행해도 동일
/path/to/ai-setting/init.sh /path/to/my-new-project

# 또는 현재 디렉토리에 적용
cd my-new-project
../ai-setting/bin/ai-setting .
```

실행하면:
```
[1/7] Claude Code 설정 복사 (.claude/)
  ⚠ .claude/ 이미 존재 — 백업 후 덮어쓰기
  📦 백업: /path/to/project/.claude.backup.20260317120000
  ✅ standard profile 적용됨 (settings 1개, hooks 5개, agents 4개, skills 5개)
[2/7] Cursor / Gemini / Copilot 설정 복사
  ✅ Cursor rule 적용됨 (.cursor/rules/ai-setting.mdc)
  ✅ Gemini settings 적용됨 (.gemini/settings.json)
[3/7] Codex CLI 설정 복사 (.codex/)
  ⚠ .codex/config.toml 이미 존재 — 백업 후 덮어쓰기
  📦 백업: /path/to/project/.codex/config.toml.backup.20260317120000
  ✅ config.toml
[4/7] 프로젝트 로컬 MCP preset 생성
  ⚠ .mcp.json 이미 존재 — 백업 후 덮어쓰기
  📦 백업: /path/to/project/.mcp.json.backup.20260317120000
  ✅ Codex MCP preset 적용됨 (core)
  ✅ Claude MCP config 생성됨 (.mcp.json)
[5/7] 템플릿 복사
  ✅ CLAUDE.md 생성됨
  ✅ AGENTS.md 생성됨
  ✅ GEMINI.md 생성됨
  ✅ .github/copilot-instructions.md 생성됨
[6/7] AI로 프로젝트 문서 자동 생성
  mode: hybrid (문서와 구현 신호가 모두 있어 함께 해석하는 편이 적합함)
  archetype: frontend-web (웹 프론트엔드 구성 신호가 확인됨)
  stack: Next.js (TypeScript/JavaScript) [next.config.ts]
  signals: docs=[README.md,docs] | impl=[package.json,src] | tests=[tests] | ops=[Dockerfile,.env.example]
  🔄 Claude Code로 프로젝트 분석 중...
  ✅ Claude Code가 프로젝트 문서를 자동 생성했습니다
[7/7] 완료!
```

### 동작 방식

```
init.sh 실행
  │
  ├─ 1~5단계: 공통 설정 + 멀티 도구 파일 + 프로젝트 로컬 MCP + 템플릿 복사 (즉시 완료)
  │
  └─ 6단계: AI가 프로젝트를 분석해서 프로젝트 문서 자동 채우기
       │
       ├─ Claude Code 있으면 → Claude Code가 처리
       ├─ 없으면 Codex 있으면 → Codex가 처리
       └─ 둘 다 없으면 → 수동 안내 메시지 출력
```

### 로컬 CLI 래퍼

`bin/ai-setting`은 저장소 루트의 `init.sh`를 감싸는 얇은 래퍼입니다. 덕분에 저장소 안에서는 `./bin/ai-setting ...` 형태로 일관되게 실행할 수 있고, 이후 npm/brew 같은 배포 채널로 확장할 때도 같은 커맨드 이름을 유지할 수 있습니다.

같이 추가된 [package.json](/Users/jaewon/my-project/ai-setting/package.json)은 아직 공개 배포용이 아니라 로컬 스캐폴드입니다.
- 기본값은 `private: true`
- `bin.ai-setting` 엔트리만 정의
- `npm run pack:check`로 패키지 메타데이터를 dry-run 검증 가능

### 옵션

```bash
# 기본: core MCP preset 자동 포함
/path/to/ai-setting/init.sh /path/to/my-new-project

# Claude minimal profile 적용
/path/to/ai-setting/init.sh --profile minimal /path/to/my-new-project

# strict 또는 team profile 적용
/path/to/ai-setting/init.sh --profile strict /path/to/my-new-project
/path/to/ai-setting/init.sh --profile team /path/to/my-new-project

# 공유 가능한 설정 자산을 심링크로 연결
/path/to/ai-setting/init.sh --link /path/to/my-new-project

# AI 자동 채우기 없이 shared assets / MCP만 갱신
/path/to/ai-setting/init.sh update /path/to/my-new-project

# 여러 프로젝트를 manifest 기준으로 update 모드로 동기화
/path/to/ai-setting/init.sh sync ./projects.manifest

# 여러 프로젝트를 init 흐름으로 다시 적용
/path/to/ai-setting/init.sh sync --sync-mode init ./projects.manifest

# 웹 프로젝트: core + web
/path/to/ai-setting/init.sh --mcp-preset web /path/to/my-new-project

# Docker 프로젝트: core + infra
/path/to/ai-setting/init.sh --mcp-preset infra /path/to/my-new-project

# 웹 + Docker 프로젝트: core + web + infra
/path/to/ai-setting/init.sh --mcp-preset web,infra /path/to/my-new-project

# AI 자동 채우기 건너뛰기 (복사만)
/path/to/ai-setting/init.sh --skip-ai /path/to/my-new-project

# 프로젝트 로컬 MCP 생성 건너뛰기
/path/to/ai-setting/init.sh --no-mcp /path/to/my-new-project

# 실제 변경 없이 예정 작업만 확인
/path/to/ai-setting/init.sh --dry-run /path/to/my-new-project

# 실제 변경 없이 관리 대상 diff 확인
/path/to/ai-setting/init.sh --diff /path/to/my-new-project

# 적용 전 관리 대상 전체 스냅샷 백업
/path/to/ai-setting/init.sh --backup-all /path/to/my-new-project

# CLAUDE.md / AGENTS.md를 fresh template로 다시 생성
/path/to/ai-setting/init.sh --reapply /path/to/my-new-project

# 감지된 archetype 기반 추천 MCP preset 자동 적용
/path/to/ai-setting/init.sh --auto-mcp /path/to/my-new-project

# 빈 프로젝트에서 의도 힌트와 함께 시작
/path/to/ai-setting/init.sh --project-name my-api --archetype backend-api --stack Python /path/to/my-new-project

# 현재 프로젝트 상태 진단
/path/to/ai-setting/init.sh --doctor /path/to/my-new-project
```

### Claude 프로필

기본값은 `standard`이며, 현재는 `standard`, `minimal`, `strict`, `team` 네 가지를 지원합니다.

| profile | 포함 내용 |
|---------|-----------|
| `standard` | 파일 보호, 위험 명령 차단, 자동 포맷, 알림, Stop 체크, agents 4개, skills 5개 |
| `minimal` | 파일 보호, 자동 포맷만 활성화. managed agents/skills는 복사하지 않음 |
| `strict` | `standard` + main/master 직접 git 작업 차단 hook |
| `team` | `strict` + `.github/pull_request_template.md`, `.ai-setting/team-webhook.json` 생성 |

프로필 전환 시:
- 기존 `.claude/`는 먼저 백업
- ai-setting이 관리하는 agents/skills/hooks만 정리 후 선택한 profile 기준으로 다시 복사
- 사용자가 따로 만든 다른 `.claude` 파일은 그대로 둠

### Link 모드

`--link`를 주면 공유 가능한 설정 자산은 복사 대신 ai-setting 저장소 원본을 가리키는 심링크로 연결합니다.

심링크 대상:
- `.claude/settings.json`
- `.claude/hooks/*`
- `.claude/agents/*`
- `.claude/skills/*`
- `.cursor/rules/ai-setting.mdc`
- `.gemini/settings.json`

계속 로컬 파일로 유지되는 것:
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
- `.github/copilot-instructions.md`, `.github/pull_request_template.md`
- `.codex/config.toml`
- `.mcp.json`
- `docs/decisions.md`

이렇게 나누는 이유:
- 위 파일들은 프로젝트별로 내용이 달라지거나 init 과정에서 추가 생성/수정이 필요함
- 반대로 hooks, agents, skills, tool settings는 원본과 동기화될수록 이점이 큼

### Update 모드

`init.sh update /path/to/project`는 기존 프로젝트를 안전하게 최신 설정으로 맞추기 위한 명시적 갱신 모드입니다.

동작:
- 공유 자산(`.claude`, `.cursor`, `.gemini`) 최신화
- `.codex/config.toml`, `.mcp.json` 최신화
- 기존 `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, Copilot 문서는 그대로 유지
- AI 자동 채우기는 실행하지 않음

추천 상황:
- ai-setting 저장소를 pull 한 뒤 기존 프로젝트 설정만 다시 맞추고 싶을 때
- 프로젝트별 문서는 건드리지 않고 공통 규칙/훅/에이전트만 갱신하고 싶을 때
- `--link` 모드와 함께 써서 링크 + 로컬 설정 갱신을 같이 맞추고 싶을 때

### Sync 모드

`init.sh sync [옵션] [manifest 경로]`는 여러 프로젝트를 한 번에 맞추기 위한 배치 동기화 모드입니다.

기본 동작:
- `sync`는 manifest에 적힌 각 프로젝트에 순서대로 `update` 또는 `init` 흐름을 적용
- 기본 `sync mode`는 `update`
- `--sync-mode init`을 주면 일반 init 흐름을 각 프로젝트에 순차 적용
- `--link`, `--profile`, `--auto-mcp`, `--mcp-preset`, `--no-mcp`, `--dry-run`, `--backup-all`, `--reapply` 옵션을 함께 전달 가능

manifest 형식:
- 한 줄에 프로젝트 경로 하나씩 작성
- 빈 줄과 `#` 주석은 무시
- 상대 경로는 manifest 파일 위치 기준으로 해석

manifest 예시:

```text
# projects.manifest
../storyforge
../taskrelay
/Users/jaewon/workspace/internal-tool
```

시작 방법:
- `templates/projects.manifest.template`를 복사해 `projects.manifest`를 만든 뒤 경로를 채우면 됨

추천 상황:
- ai-setting 저장소를 업데이트한 뒤 여러 프로젝트에 공통 자산을 한 번에 반영하고 싶을 때
- 팀/개인 프로젝트 셋업을 한 파일로 관리하고 싶을 때
- 먼저 `--dry-run`으로 전체 예정 작업을 확인한 뒤 실제 적용하고 싶을 때

### 멀티 도구 지원

기본 실행만으로 아래 도구용 파일도 함께 생성됩니다.

| 도구 | 생성 파일 | 메모 |
|------|-----------|------|
| Cursor | `.cursor/rules/ai-setting.mdc` | `AGENTS.md`, `CLAUDE.md`를 import하는 always-apply rule |
| Gemini CLI | `.gemini/settings.json`, `GEMINI.md` | `GEMINI.md`가 `CLAUDE.md`, `AGENTS.md`를 import |
| GitHub Copilot | `.github/copilot-instructions.md` | 저장소 공통 build/test/validation 규칙 요약 |

## 적용 후 확인

아래 설명은 기본값인 `standard` profile 기준입니다. `--profile minimal`을 사용했다면 hooks만 남고 managed agents/skills는 복사되지 않습니다.

### 그대로 사용 (수정 불필요)
- `.claude/settings.json` — hooks, 포맷터, 알림 전부 포함
- `.claude/hooks/*` — 보호 파일 차단 + 위험 명령 차단 + async test + session context + compact backup
- `.claude/agents/*` — 보안 리뷰, 설계 검증, 테스트 작성, 리서치
- `.claude/skills/*` — 배포, 코드 리뷰, 이슈 수정, Gap 체크, 교차검증
- `.claude/hooks/protect-main-branch.sh` — strict/team에서 main/master 직접 git 작업 차단
- `.ai-setting/team-webhook.json` — team profile용 웹훅 메타설정 템플릿
- `.cursor/rules/ai-setting.mdc` — Cursor project-wide rule
- `.gemini/settings.json` / `GEMINI.md` — Gemini CLI 컨텍스트
- `.github/copilot-instructions.md` — GitHub Copilot 저장소 지침
- `.codex/config.toml` — Codex CLI 기본 설정 + 프로젝트 로컬 MCP
- `.mcp.json` — Claude Code 프로젝트 로컬 MCP

### 프로젝트 로컬 MCP preset

기본값은 `core`이며, 필요 시 `web`, `infra`를 추가할 수 있습니다.

| preset | 포함 서버 | 용도 |
|--------|-----------|------|
| `core` | `sequential-thinking`, `serena`, `upstash-context-7-mcp` | 대부분 프로젝트의 공통 기본값 |
| `web` | `playwright` | 프론트엔드/브라우저 자동화 |
| `infra` | `docker` | 컨테이너/로컬 인프라 작업 |

기본 포함에서 제외된 것:
- `brave-search` — API 키 필요
- `filesystem` — 경로 스코프 설계 후 별도 검토

자동 추천 기준:
- `frontend-web` → `core + web`
- `infra-iac` → `core + infra`
- `backend-api`, `worker-batch`, `data-automation` + 운영 신호(Docker/compose 등) → `core + infra`

기본값은 여전히 `core`만 적용되고, `--auto-mcp`를 줬을 때만 추천 preset이 자동 반영됩니다.

### AI가 자동 생성한 파일 확인
`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.github/copilot-instructions.md`가 프로젝트에 맞게 채워졌는지 확인.
AI 생성이 실패했거나 `--skip-ai`로 건너뛴 경우 `[대괄호]` 부분을 직접 채우거나:
```
claude "프로젝트 문서의 [대괄호] 부분을 채워줘"
```

### 프로젝트 해석 모드 자동 감지

`init.sh`는 AI 자동 채우기 전에 프로젝트 상태를 아래 4가지 중 하나로 분류합니다.

| 모드 | 기준 | 동작 |
|------|------|------|
| `blank-start` | 문서/구현/테스트 신호가 거의 없음 | 템플릿과 설정만 안전하게 생성하고 AI 자동 채우기는 건너뜀 |
| `docs-first` | 문서 신호가 충분하고 구현 신호가 적음 | 문서를 우선 근거로 사용하고 미구현 내용은 TODO/가정으로 남김 |
| `hybrid` | 문서와 구현 신호가 모두 있음 | 코드/설정을 먼저 보고 문서는 의도 보완용으로 사용 |
| `code-first` | 코드/설정/테스트 신호가 풍부함 | 실제 구현 상태를 우선으로 해석하고 문서와 충돌 시 차이를 드러냄 |

감지 신호 예시:
- 문서: `README.md`, `docs/`, `spec/`, `prd/`, `requirements/`
- 구현: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `src/`, `app/`, `backend/`, `frontend/`
- 테스트/운영: `tests/`, `.github/workflows/`, `Dockerfile`, `compose.yaml`, `.env.example`

빈 폴더에서 먼저 실행하면:
- `blank-start`로 감지
- `.claude`, `.codex`, `.mcp.json`, 템플릿은 생성
- `CLAUDE.md`, `AGENTS.md`는 과추론 없이 그대로 두고 AI 자동 채우기는 건너뜀
- 이후 `README.md`, `package.json`, `pyproject.toml`, `src/` 같은 신호가 생긴 뒤 다시 실행하면 됨

blank-start에서도 의도를 미리 줄 수 있음:
- `--project-name my-api`
- `--archetype backend-api`
- `--stack Python`

이 힌트가 있으면 `guided blank-start`로 보고, 힌트 기반 초안을 만들되 확인할 수 없는 부분은 TODO/가정으로 남깁니다.

### 프로젝트 유형과 스택 자동 감지

`init.sh`는 해석 모드와 별개로 프로젝트 archetype과 주 스택도 함께 감지해서 AI 프롬프트에 전달합니다.

지원 archetype:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app` (애매한 경우의 안전한 fallback)

스택 감지 예시:
- `Next.js (TypeScript/JavaScript)`
- `Vite (TypeScript/JavaScript)`
- `Node.js / TypeScript`
- `Python`, `Go`, `Rust`, `Java / Kotlin`, `Ruby`, `PHP`

사용자 힌트 옵션:
- `--project-name NAME`
- `--archetype TYPE`
- `--stack NAME`

`--archetype` 지원값:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app`

### 프로젝트별 선택 추가

**protect-files.sh에 패턴 추가** (필요 시):
```bash
# DB 마이그레이션 보호
"alembic/versions/"

# Docker/설정 파일 보호
"compose.yaml"
"pyproject.toml"

# 데이터 디렉토리 보호
"data/"
```

**프로젝트 고유 agents/skills 추가** (필요 시):
```
.claude/agents/card-content-generator.md   ← StoryForge 예시
.claude/agents/spec-writer.md              ← TaskRelay 예시
.claude/skills/db-schema/SKILL.md          ← 도메인 스킬
.claude/skills/phase-check.md              ← 워크플로우 스킬
```

반복 실행 시 overwrite 정책:
- `.claude/`가 이미 있으면 디렉토리 전체를 `.claude.backup.TIMESTAMP`로 백업
- `.cursor/rules/ai-setting.mdc`가 이미 있으면 `.backup.TIMESTAMP`로 백업
- `.gemini/settings.json`이 이미 있으면 `.backup.TIMESTAMP`로 백업
- `.codex/config.toml`이 이미 있으면 `.codex/config.toml.backup.TIMESTAMP`로 백업
- `.mcp.json`이 이미 있으면 `.mcp.json.backup.TIMESTAMP`로 백업
- `--profile minimal`로 전환하면 ai-setting이 관리하던 agents/skills는 정리되고 minimal 설정만 남음
- `--profile strict` 또는 `--profile team`이면 branch 보호 hook이 함께 적용됨
- `--link`를 주면 공유 자산은 심링크로 다시 연결됨

### Doctor 모드

`init.sh --doctor /path/to/project`로 현재 상태를 점검할 수 있습니다.

진단 항목:
- 필수 바이너리: `jq`, `npx`, `uvx`, `claude`, `codex`, `gemini`
- 핵심 파일: `.claude/settings.json`, profile별 hooks, `.cursor/rules/ai-setting.mdc`, `.gemini/settings.json`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md`(team), `.codex/config.toml`, `.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `docs/decisions.md`
- team profile에서는 `.ai-setting/team-webhook.json`도 함께 확인
- `.mcp.json` JSON 유효성
- 템플릿/skill placeholder 잔존 여부
- 공유 자산 모드가 `copy`인지 `symlink`인지
- async test 명령이 명시되었는지 또는 자동 감지가 가능한지
- compact backup hook 존재 여부

참고:
- `blank-start` 모드에서는 템플릿/skill placeholder가 남아 있어도 정상으로 취급
- `minimal` profile은 `block-dangerous-commands`, `async-test`와 managed skills 부재를 정상으로 취급
- `minimal` profile은 `session-context`, `compact-backup`도 비활성 상태를 정상으로 취급
- `strict/team` profile은 `protect-main-branch.sh`가 없으면 error
- error가 있으면 종료 코드 `1`, error가 없으면 종료 코드 `0`

### Dry-run 모드

`init.sh --dry-run /path/to/project`로 실제 변경 없이 예정 작업만 볼 수 있습니다.

동작:
- 생성/덮어쓰기/백업 예정 파일과 디렉토리를 출력
- AI 자동 채우기는 실행하지 않음
- 종료 후 실제 파일은 전혀 변경되지 않음

### Diff 모드

`init.sh --diff /path/to/project`로 현재 상태와 init 적용 결과의 차이를 unified diff 형태로 볼 수 있습니다.

동작:
- `.claude`, `.codex/config.toml`, `.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `docs/decisions.md` 기준으로 비교
- `.cursor/rules/ai-setting.mdc`, `.gemini/settings.json`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md`도 포함
- 실제 파일은 변경하지 않음
- AI 자동 채우기 결과는 포함하지 않음

참고:
- `--doctor`, `--dry-run`, `--diff`는 동시에 사용할 수 없음
- `sync` 명령은 `--doctor`, `--diff`와 함께 사용할 수 없음

### Backup-all 모드

`init.sh --backup-all /path/to/project`로 적용 전에 관리 대상 전체를 한 번에 스냅샷 백업할 수 있습니다.

동작:
- `.claude`, `.codex/config.toml`, `.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `docs/decisions.md`를 대상 프로젝트 아래 `.ai-setting.backup.TIMESTAMP/`로 백업
- `.cursor/rules/ai-setting.mdc`, `.gemini/settings.json`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md`도 함께 백업
- 이후 overwrite 단계에서는 개별 `.backup.*`를 중복 생성하지 않고 snapshot 포함 안내만 출력
- `--dry-run`과 함께 쓰면 snapshot 생성 예정만 출력

참고:
- `--backup-all`은 `--doctor`, `--diff`와 함께 사용할 수 없음

### Reapply 모드

`init.sh --reapply /path/to/project`로 프로젝트 문서 템플릿을 fresh template 기준으로 다시 생성하고 AI 자동 채우기를 다시 실행할 수 있습니다.

동작:
- 기존 `CLAUDE.md`, `AGENTS.md`는 backup 후 새 템플릿으로 재생성
- 기존 `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md`(team)도 backup 후 새 템플릿으로 재생성
- 이후 AI 자동 채우기 단계가 다시 실행됨
- `.claude`, `.codex`, `.mcp.json`은 기존처럼 최신 설정으로 다시 적용
- `docs/decisions.md`는 사용자 기록 파일로 보고 유지

추천 조합:
- 안전하게 하려면 `--backup-all --reapply`
- 먼저 확인만 하려면 `--dry-run --reapply`

참고:
- `--reapply`는 `--doctor`, `--diff`와 함께 사용할 수 없음

---

## 구조

```
ai-setting/
├── bin/
│   └── ai-setting                         # 로컬 CLI 래퍼 (`init.sh` 실행)
├── init.sh                               # 🚀 초기화 스크립트
├── package.json                          # 로컬 npm 패키지 scaffold (`private`)
├── claude/
│   ├── settings.json                      # standard profile 템플릿
│   ├── settings.minimal.json              # minimal profile 템플릿
│   ├── settings.strict.json               # strict profile 템플릿
│   ├── settings.team.json                 # team profile 템플릿
│   ├── hooks/
│   │   ├── protect-files.sh               # 민감 파일 편집 차단 (20개 패턴)
│   │   ├── block-dangerous-commands.sh    # 위험 명령어 차단 (14개 패턴)
│   │   ├── async-test.sh                  # 편집 후 백그라운드 테스트
│   │   ├── compact-backup.sh              # compact 복원용 스냅샷 백업
│   │   ├── protect-main-branch.sh         # main/master 직접 git 작업 차단
│   │   ├── session-context.sh             # compact 대비용 컨텍스트 스냅샷
│   │   └── team-webhook-notify.sh         # team profile 웹훅 알림
│   ├── agents/
│   │   ├── security-reviewer.md           # 보안 리뷰 (읽기 전용, opus)
│   │   ├── architect-reviewer.md          # 설계 검증 (읽기 전용, opus)
│   │   ├── test-writer.md                 # 테스트 작성 (sonnet)
│   │   └── research.md                    # 기술 리서치 (검색 도구)
│   └── skills/
│       ├── deploy/SKILL.md                # 배포 체크리스트
│       ├── review/SKILL.md                # 코드 리뷰 체크리스트
│       ├── fix-issue/SKILL.md             # 이슈 수정 워크플로우
│       ├── gap-check/SKILL.md             # 빠진 요구사항 탐지
│       └── cross-validate/SKILL.md        # AI 출력물 교차검증
├── cursor/
│   └── rules/
│       └── ai-setting.mdc                 # Cursor always-apply rule
├── gemini/
│   └── settings.json                      # Gemini CLI workspace settings
├── codex/
│   └── config.toml                        # Codex CLI 기본 설정 (MCP preset은 init 시 추가)
├── templates/
│   ├── CLAUDE.md.template                 # [대괄호]만 채우면 됨
│   ├── AGENTS.md.template                 # [대괄호]만 채우면 됨
│   ├── GEMINI.md.template                 # Gemini CLI 컨텍스트 템플릿
│   ├── copilot-instructions.md.template   # Copilot 저장소 지침 템플릿
│   ├── projects.manifest.template         # 다중 프로젝트 sync manifest 예시
│   ├── pull_request_template.md.template  # team profile용 PR 템플릿
│   ├── team-webhook.json.template         # team profile 웹훅 메타설정 템플릿
│   └── decisions.md.template              # 기술 의사결정 기록
└── README.md
```

---

## 포함된 설정 상세

### Hooks — 자동 실행

| Hook | 시점 | 역할 |
|------|------|------|
| **protect-files.sh** | 파일 편집 전 | .env, lock, .git, 인증키, 빌드산출물 편집 차단 |
| **block-dangerous-commands.sh** | Bash 실행 전 | rm -rf, sudo, force push, DROP TABLE 등 차단 |
| **async-test.sh** | PostToolUse(Edit/Write) | 코드 파일 편집 후 비동기 테스트를 best-effort로 실행 |
| **compact-backup.sh** | Stop / SessionStart(compact) | compact 세션 복원용 최신/히스토리 스냅샷 보관 |
| **session-context.sh** | Stop / SessionStart(compact) | compact 대비용 프로젝트 컨텍스트 스냅샷 갱신 및 복원 |
| **team-webhook-notify.sh** | Stop(team) | 선택적으로 Slack/Discord 웹훅에 완료 알림 전송 |
| **auto-format** | 파일 편집 후 | Python→ruff, TS/JS→prettier 자동 포맷 |
| **test-check** | 작업 완료 시 | 코드 변경 후 테스트 실행 여부 확인 |
| **notification** | 입력 필요 시 | macOS 데스크톱 알림 |
| **session-reminder** | compact 시 | CLAUDE.md/AGENTS.md 읽기 리마인더 |

### Agents — 서브에이전트

| Agent | 모델 | 권한 | 역할 |
|-------|------|------|------|
| **security-reviewer** | opus | 읽기 + Bash | 보안 취약점 (인젝션, 인증, 시크릿, AI API, 파일 업로드) |
| **architect-reviewer** | opus | 읽기 전용 | 설계 품질 (관심사 분리, 의존성, God 클래스, 네이밍) |
| **test-writer** | sonnet | 쓰기 가능 | 테스트 생성 (pytest, Vitest, happy/edge/error path) |
| **research** | — | 검색 도구 | 기술 조사 (공식 문서 → 웹 검색 → GitHub 사용례) |

### Skills — 슬래시 명령어

| Skill | 역할 |
|-------|------|
| **/deploy** | Pre-deploy 체크 → 배포 → Post-deploy 검증 |
| **/review** | Security / Backend / Frontend / General 체크리스트 |
| **/fix-issue** | gh issue → 실패 테스트 → 수정 → 린트 → PR |
| **/gap-check** | 빠진 요구사항 탐지 (Implicit Requirements + What If 분석) |
| **/cross-validate** | AI 생성 문서/코드 vs 실제 상태 대조 검증 |

### 프로젝트 로컬 MCP

| 위치 | 역할 |
|------|------|
| `.codex/config.toml` | Codex CLI의 `mcp_servers.*` 설정 |
| `.mcp.json` | Claude Code project-scoped MCP 설정 |

기본 preset:
- `core` → `sequential-thinking`, `serena`, `upstash-context-7-mcp`
- 선택 `web` → `playwright`
- 선택 `infra` → `docker`

### 보호 패턴 (protect-files.sh)

3종 매칭으로 오탐 방지:

| 매칭 방식 | 패턴 | 설명 |
|-----------|------|------|
| **디렉토리** (경로 포함) | `.git/`, `node_modules/`, `__pycache__/`, `.venv/`, `dist/`, `build/`, `.next/` | 경로에 포함되면 차단 |
| **파일명** (basename 일치) | `.env`, `.env.local`, `.env.production`, `.env.development`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `uv.lock`, `credentials.json` | 정확히 일치하는 파일만 차단 |
| **확장자** (basename 끝) | `*.sqlite`, `*.sqlite3`, `*.pem`, `*.key` | 해당 확장자로 끝나는 파일 차단 |

### 위험 명령 차단 (block-dangerous-commands.sh)

```
rm -rf /    rm -rf ~    rm -rf .    sudo
git push --force/--f    git reset --hard
DROP TABLE    DROP DATABASE    TRUNCATE TABLE
chmod 777    mkfs    > /dev/sda    fork bomb
```

### 비동기 테스트 훅 (async-test.sh)

- `standard`, `strict`, `team` profile에서만 활성화됩니다.
- 우선순위는 `.ai-setting/test-command` → `AI_SETTING_ASYNC_TEST_CMD` → 자동 감지(Python/Go/Rust 1차)입니다.
- 상태 파일은 `.claude/context/async-test-status.md`, 로그는 `.claude/context/async-test.log`에 남습니다.
- 이미 실행 중인 테스트가 있으면 중복 실행하지 않고 기존 job을 유지합니다.
- JavaScript/TypeScript 프로젝트는 테스트 러너 옵션이 제각각이라 1차에서는 `.ai-setting/test-command`를 명시하는 쪽을 권장합니다.

예시:

```bash
mkdir -p .ai-setting
printf '%s\n' 'pnpm test -- --runInBand' > .ai-setting/test-command
```

### 팀 웹훅 알림 (team-webhook-notify.sh)

- `team` profile에서만 활성화되는 선택형 훅입니다.
- 실제 URL은 환경변수로 두고, 프로젝트에는 `.ai-setting/team-webhook.json`의 메타설정만 두는 방식을 권장합니다.
- 기본값은 `enabled: false`라서 생성 직후에는 아무 것도 전송하지 않습니다.
- 상태 파일은 `.claude/context/team-webhook-status.md`에 남습니다.

예시:

```bash
export AI_SETTING_TEAM_WEBHOOK_URL='https://hooks.slack.com/services/...'

cat > .ai-setting/team-webhook.json <<'JSON'
{
  "enabled": true,
  "url_env": "AI_SETTING_TEAM_WEBHOOK_URL",
  "channel": "#ai-alerts",
  "username": "Claude Code",
  "mention": "",
  "events": ["stop"]
}
JSON
```

### Compact Backup (compact-backup.sh)

- `standard`, `strict`, `team` profile에서만 활성화됩니다.
- Stop 시점마다 `.claude/context/compact-latest.md`를 갱신하고, `.claude/context/compact-history/` 아래에 타임스탬프 히스토리를 남깁니다.
- SessionStart에서 compact가 일어나면 `session-context.sh`가 최신 compact backup을 우선 복원합니다.
- snapshot에는 session context, async test 상태, team webhook 상태, git status 요약이 함께 들어갑니다.

---

## CLAUDE.md 템플릿 — 포함된 공통 섹션 (17개)

| 섹션 | 내용 |
|------|------|
| 프로젝트 규칙 | @AGENTS.md 참조 |
| 빌드 & 실행 | [프로젝트별 명령어] |
| 라이브러리 우선 원칙 | 직접 구현 전 라이브러리 확인, 공식 문서 검증 |
| 의존성 관리 | stdlib 우선, 버전 핀, 보안 취약점 확인 |
| Research 원칙 | 새 기술 도입 시 공식 문서 확인 필수 |
| Preflight 원칙 | 분석 → 계획 → 확인 → 실행 |
| 교육용 진행 원칙 | 구조 경계 주석, "왜" 중심, 코드 반복 주석 금지 |
| AI 연동 | 추상 인터페이스 경유 필수 |
| 에러 처리 규칙 | 구체적 예외만 포착, structlog, transient/permanent 구분 |
| 환경변수 규칙 | pydantic-settings, .env만, .env.example 문서화 |
| 안전장치 | 재시도 제한, 비용 가드레일, 롤백 전략 |
| 교차검증 원칙 | AI 출력물 vs 실제 코드/상태 대조 필수 |
| Gap Detection 원칙 | 빠진 요구사항 탐지, What If 분석, 범위 제한 |
| 코드-문서 동기화 | 코드 변경 시 관련 문서 필수 갱신 |
| 용어 혼동 방지 | 동일 용어 다중 맥락 시 구분 명시 |
| 의사결정 기록 | decisions.md에 선택 + 이유 + 대안 기록 |
| 도메인 지식 | [프로젝트별 문서 참조] |

## AGENTS.md 템플릿 — 포함된 공통 규칙

**General Principles** (11개):
TDD, 라이브러리 우선, 관심사 분리, SOLID/DRY/KISS/YAGNI, Fail Fast, 불변성, 보안 기본값, 구조화 로깅, 교육용 주석, 모듈식 설계, Preflight

**Forbidden** (10개):
God 클래스, 비즈니스 로직 위치, 바퀴 재발명, 수동 DDL, 공식 문서 없이 라이브러리, any 타입, except:pass, AI API 직접 호출, 하드코딩 시크릿, 주석 노이즈

---

## 출처 및 검증

- **StoryForge** (.claude/ 설정 원본) + **TaskRelay** (.claude/ 설정 원본)
- **Claude Code 공식 문서** — hooks 규격, permissions 문법, agents/skills 형식
- **Codex CLI 공식 문서** — config.toml 필드 검증
- **커뮤니티** — Trail of Bits 설정, Awesome Claude Code, Claude Code Hooks Mastery
