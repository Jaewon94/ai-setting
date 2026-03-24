# 이슈 관리

## 점검일: 2026-03-20

전체 프로젝트 점검 결과 발견된 이슈를 기록하고 추적합니다.

---

### ISS-001: CODEX.md가 Codex CLI에서 자동 인식되지 않음 (⚠️ 수정 필요)

**발견일**: 2026-03-19
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-19)

**문제**:
- Codex CLI는 **AGENTS.md만** 자동으로 읽음 ([공식 문서](https://developers.openai.com/codex/guides/agents-md))
- 우리가 생성하는 CODEX.md는 Codex가 인식하지 않아 사실상 사용되지 않는 파일

**수정 내용**:
- CODEX.md.template 삭제
- init.sh Step 5에서 CODEX.md 생성 제거
- AI 프롬프트에서 CODEX.md 지시 제거
- doctor, backup, add-tool, README, roadmap에서 CODEX.md 참조 제거
- 테스트에서 CODEX.md 기대값 제거

---

### ISS-002: archetype partial 삽입 테스트 누락 (⚠️ 수정 필요)

**발견일**: 2026-03-19
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-19)

**문제**:
- 7종 archetype partial이 CLAUDE.md에 올바르게 삽입되는지 자동 테스트가 없음

**수정 내용**:
- test_detect.sh에 frontend-web, backend-api partial 삽입 검증 테스트 추가
- blank-start에서 partial 미삽입 확인 테스트 추가

---

### ISS-003: Copilot 경로별 지침 미활용 (✅ 수정 완료)

**발견일**: 2026-03-19
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-20)

**문제**:
- GitHub Copilot이 `*.instructions.md` 형태의 경로별 지침을 지원 ([공식 문서](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot))
- 현재는 copilot-instructions.md 1개만 생성

**수정 내용**:
- `.github/instructions/*.instructions.md` 템플릿 추가
- TypeScript / Python / Testing 경로별 지침 자동 생성
- profile/doctor/backup/test 흐름에 반영

---

---

### ISS-004: Codex config.toml에 reasoning 옵션 누락 (✅ 수정 완료)

**발견일**: 2026-03-19
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-19)

**문제**: 공식 문서에 `model_reasoning_effort`, `model_reasoning_summary` 옵션이 있으나 미사용
**수정**: 4개 프로필 config.toml 전부에 `model_reasoning_effort = "medium"`, `model_reasoning_summary = "concise"` 추가

---

### ISS-005: Gemini settings.json 공식 문서 대비 미활용 옵션 (✅ 수정 완료)

**발견일**: 2026-03-19
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-19)

**문제**:
- `context.fileName`이 문자열인데 공식 문서에서 배열도 지원 → AGENTS.md 직접 포함 가능
- `includeDirectoryTree` 옵션 미사용

**수정**:
- fileName을 `["GEMINI.md", "AGENTS.md"]` 배열로 변경 (AGENTS.md도 직접 읽힘)
- `includeDirectoryTree: true` 추가

---

---

### ISS-006: settings.json merge 모드 필요 (✅ 수정 완료)

**발견일**: 2026-03-19 (onDeviceAI-KOBOT 실전 테스트)
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-20)

**문제**: 기존 프로젝트에 이미 커스텀 settings.json이 있을 때, ai-setting이 기본 템플릿으로 덮어쓰면 프로젝트 전용 설정(포맷터 경로, 알림 메시지 등)이 사라짐
**수정**:
- `--merge` 옵션 추가
- 기존 `.claude/settings.json`의 커스텀 키/기존 hook 유지
- ai-setting profile hook만 jq 기반으로 병합
- 회귀 테스트 추가

---

### ISS-007: 포맷터 경로가 monorepo에서 안 맞음 (✅ 수정 완료)

**발견일**: 2026-03-19 (onDeviceAI-KOBOT 실전 테스트)
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-20)

**문제**: ai-setting 기본 포맷터가 `cd "$CLAUDE_PROJECT_DIR" && uv run ruff`인데, uv 안 쓰거나 frontend가 하위 디렉토리인 프로젝트에서 안 맞음
**수정**:
- inline 포맷터 명령을 `format-on-write.sh` hook로 분리
- 편집된 파일 기준으로 nearest `package.json`, `pyproject.toml`, `requirements*.txt` 탐색
- `frontend/`, `backend/` 같은 하위 프로젝트에서 해당 디렉토리로 이동 후 실행
- `uv.lock`이 있을 때만 `uv run ruff`, 아니면 `ruff` 직접 실행
- monorepo 회귀 테스트 추가

---

### ISS-008: 조사/결정 문서의 출처 추적 구조 부족 (✅ 수정 완료)

**발견일**: 2026-03-20
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-20)

**문제**:
- "공식 문서를 보고 판단했다"는 원칙은 있었지만, 무엇을 언제 확인했는지 남기는 표준 문서 구조가 약했음
- 사용자가 결정의 근거를 나중에 다시 추적하기 어려웠음

**수정 내용**:
- `docs/research-notes.md` 템플릿 추가
- `docs/decisions.md`에 `관련 조사`, `확인일`, `근거 문서` 필드 추가
- `R-xxx`, `D-xxx`, `문서명 — URL`, `YYYY-MM-DD` 형식 표준화
- `doctor`, `backup`, `diff`, `session-context`, `compact-backup`에 반영
- 실전 검증 문서 `docs/field-test-research-traceability.md` 추가

---

### ISS-009: AI 자동 채우기 fallback이 최신 CLI 동작과 불일치 (✅ 수정 완료)

**발견일**: 2026-03-20
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-20)

**문제**:
- Codex fallback이 구형 CLI 호출(`codex -q`)에 의존하고 있었음
- Claude Code가 응답 없이 오래 대기할 때 자동 fallback으로 넘어가는 timeout이 없었음

**수정 내용**:
- Codex fallback을 `codex exec --skip-git-repo-check`로 변경
- Claude 자동 채우기에 기본 `20s` timeout 추가 후 Codex fallback 연결
- `tests/test_basic.sh`에 Codex fallback/Claude timeout 회귀 테스트 추가
- 실전 검증 문서 `docs/field-test-ai-autofill.md` 추가

---

### ISS-010: npm publish 후 `npx` / `npm exec` 실행 경로 실패 (✅ 수정 완료)

**발견일**: 2026-03-20
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-21)

**원인**: bin/ai-setting 파일이 CRLF line ending → shebang이 `#!/bin/bash\r`로 해석되어 실행 실패
**수정**: bin/ai-setting LF 변환 + `.gitattributes`에 `bin/* text eol=lf`, `*.sh text eol=lf` 추가

**문제**:
- npm 패키지 `@jaewon94/ai-setting@1.0.0` publish 자체는 성공
- 익명 조회 기준 `npm view @jaewon94/ai-setting version --userconfig=/dev/null` 는 `1.0.0` 반환
- 그러나 실제 실행 경로 검증에서 아래 명령들이 모두 실패

```bash
npx @jaewon94/ai-setting --help
npx --yes --package=@jaewon94/ai-setting -- ai-setting --help
npm exec --yes --package=@jaewon94/ai-setting -- ai-setting --help
```

- 공통 에러:

```text
sh: ai-setting: command not found
```

**현재까지 확인된 사실**:
- 로컬 저장소 경로 실행은 정상
- `./bin/ai-setting --skip-ai --all <tmpdir>` 적용 정상
- `./bin/ai-setting --doctor <tmpdir>` 결과 `ERROR: 0`
- `storyforge`, `taskrelay` 대상 `--doctor`, `/tmp` 복제본 `--dry-run`도 의미 있게 동작
- 즉, 문제 범위는 "배포된 npm 패키지의 실행 엔트리" 쪽으로 좁혀짐

**가설**:
- scoped package + `bin` 엔트리 노출 방식 문제
- publish된 패키지 메타데이터와 `npx/npm exec` 해석 차이
- 로컬 npm 환경과 패키지 bin linking 방식 차이

**다음 액션**:
- npm registry에서 publish된 `bin` 메타데이터 확인
- tarball 설치 후 실제 `node_modules/.bin` 생성 여부 확인
- 필요하면 `package.json#bin` 또는 패키지 구조 조정 후 `1.0.1` 재배포

---

## 완료된 이슈

- ISS-001: CODEX.md 제거 ✅
- ISS-002: archetype partial 테스트 추가 ✅
- ISS-003: Copilot 경로별 지침 ✅
- ISS-004: Codex reasoning 옵션 추가 ✅
- ISS-005: Gemini settings.json 개선 ✅
- ISS-006: settings.json merge 모드 ✅
- ISS-007: 포맷터 경로 자동 조정 ✅
- ISS-008: research-notes / decisions 추적성 구조 ✅
- ISS-009: AI 자동 채우기 fallback 안정화 ✅

### ISS-011: jq 부재 시 보안 hook(protect-files, block-dangerous-commands)이 완전 우회됨 (✅ 수정 완료)

**발견일**: 2026-03-21 (StoryForge Windows 환경 실전 적용)
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- `protect-files.sh`와 `block-dangerous-commands.sh`가 jq로 tool_input을 파싱함
- jq가 없으면 `FILE_PATH`/`COMMAND`가 빈 문자열 → 모든 패턴 매칭 통과 → 보안 hook 무력화
- Windows 환경에서 jq가 기본 설치되어 있지 않은 경우가 많음

**수정 제안**:
- hook 진입부에 jq 존재 확인 추가, 없으면 fail-closed(exit 2)로 동작
```bash
if ! command -v jq >/dev/null 2>&1; then
  echo "Blocked: jq not available, cannot parse tool input safely." >&2
  exit 2
fi
```
- `--doctor` 명령에서 jq 설치 여부를 WARNING이 아닌 ERROR로 표시

---

### ISS-012: async-test.sh에서 eval 사용 — 커맨드 인젝션 가능성 (✅ 수정 완료)

**발견일**: 2026-03-21 (StoryForge 보안 리뷰)
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- `async-test.sh` 라인 156에서 `eval "${ASYNC_TEST_COMMAND:-}"` 사용
- `.ai-setting/test-command` 파일 또는 `AI_SETTING_ASYNC_TEST_CMD` 환경변수에서 읽은 값을 eval로 실행
- 파일/환경변수가 조작되면 셸 메타문자(`;`, `&&`, `|`)를 통해 임의 명령 실행 가능

**수정 제안**:
- `eval` 대신 `bash -c "$ASYNC_TEST_COMMAND"` 사용 (최소한 별도 셸에서 실행)
- 또는 허용된 명령 패턴(pytest, vitest, go test 등) 화이트리스트 검증 추가

---

### ISS-013: Notification hook이 macOS 전용 osascript — Windows/Linux 미동작 (✅ 수정 완료)

**발견일**: 2026-03-21 (StoryForge Windows 11 환경)
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- Notification hook이 `osascript -e 'display notification ...'` 사용
- macOS 전용이라 Windows/Linux에서 무조건 실패(exit code != 0)
- Claude Code가 매 알림마다 에러를 겪음

**수정 제안**:
- OS 감지 래퍼 스크립트(`notification.sh`)로 교체
```bash
if command -v osascript >/dev/null 2>&1; then
  osascript -e 'display notification "..." with title "Claude Code"'
elif command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "New-BurntToastNotification -Text 'Claude Code', '...' 2>$null" || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "Claude Code" "..."
fi
```

---

### ISS-014: --merge 적용 시 동일 이벤트에 hook 중복 등록 (✅ 수정 완료)

**발견일**: 2026-03-21 (StoryForge 실전 적용)
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- `--merge` 모드에서 기존 hooks + ai-setting hooks가 모두 보존됨
- 결과적으로 동일 기능이 중복 실행:
  - PostToolUse(Edit|Write): format-on-write.sh + 기존 inline 포맷터 → 포맷팅 2회
  - Notification: osascript 2개 → 알림 2회
  - Stop: 동일 prompt hook 2개 → 검사 2회
- 성능 저하 및 불필요한 지연 발생

**수정 제안**:
- merge 시 동일 command/prompt를 가진 hook은 중복 제거(deduplicate) 로직 추가
- 또는 ai-setting 관리 hook에 `"_managed_by": "ai-setting"` 마커를 넣어 기존 것과 구분

---

### ISS-015: .claude/context/ 디렉토리가 .gitignore 자동 추가 안 됨 (✅ 수정 완료)

**발견일**: 2026-03-21 (StoryForge 적용 후 확인)
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- session-context.sh, compact-backup.sh가 `.claude/context/`에 런타임 데이터 저장
- 프로젝트 경로, 타임스탬프, git 상태 등 개인 환경 정보 포함
- init.sh가 `.gitignore`에 `.claude/context/`와 `.claude.backup.*`를 자동 추가하지 않음
- git에 커밋되면 로컬 환경 정보 노출

**수정 제안**:
- init.sh에서 `.gitignore`에 다음을 자동 추가:
```
.claude/context/
.claude.backup.*
```

---

### ISS-016: deploy, fix-issue skill의 플레이스홀더가 --skip-ai 시 미치환 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- `--skip-ai`로 적용 시 `{{TEST_BACKEND_CMD}}`, `{{DEPLOY_BACKEND_CMD}}` 등이 머스태시 그대로 남음
- 해당 skill 실행 시 문자열 그대로 실행 시도 → 실패

**수정 제안**:
- `--skip-ai` 시에도 archetype/stack 감지 결과를 기반으로 기본 명령을 치환하는 rule-based fallback 추가
- 또는 미치환 플레이스홀더가 있는 skill을 비활성화 표시

---

## 완료된 이슈

- ISS-001: CODEX.md 제거 ✅
- ISS-002: archetype partial 테스트 추가 ✅
- ISS-003: Copilot 경로별 지침 ✅
- ISS-004: Codex reasoning 옵션 추가 ✅
- ISS-005: Gemini settings.json 개선 ✅
- ISS-006: settings.json merge 모드 ✅
- ISS-007: 포맷터 경로 자동 조정 ✅
- ISS-008: research-notes / decisions 추적성 구조 ✅
- ISS-009: AI 자동 채우기 fallback 안정화 ✅
- ISS-010: npm bin CRLF 수정 ✅
- ISS-011: jq fail-closed ✅
- ISS-012: eval 제거 ✅
- ISS-013: Notification 크로스플랫폼 ✅
- ISS-014: merge hook 중복 ✅
- ISS-015: .gitignore 자동 추가 ✅
- ISS-016: skip-ai 플레이스홀더 ✅
- ISS-017: merge PostToolUse 중복 ✅
- ISS-018: format-on-write monorepo 경로 ✅
- ISS-019: async-test monorepo 감지 ✅
- ISS-020: 프로젝트명 미치환 ✅
- ISS-021: skill 플레이스홀더 ✅
- ISS-022: doctor permission 경고 ✅
- ISS-023: research MCP fallback ✅
- ISS-024: serena uvx 경고 ✅
- ISS-025: skip-ai 범용 템플릿 ✅
- ISS-026: npx Windows bash shebang ✅
- ISS-027: Cursor @file 참조 미동작 (Cursor 측 수정 대기)
- ISS-028: git 프로젝트 백업 스킵 ✅
- ISS-029: jq PATH fallback + 자동 설치 제안 ✅
- ISS-030: archetype 규칙 중복 삽입 방지 + 사용자 커스텀 보호 ✅
- ISS-031: Windows Notification timeout 단축 ✅

### ISS-029: 보안 hook의 jq 탐색이 PATH만 확인 — Windows fallback 경로 누락 (✅ 수정 완료)

**발견일**: 2026-03-22 (StoryForge 실전 적용)
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-22)

**문제**:
- `protect-files.sh`, `block-dangerous-commands.sh`가 `command -v jq`만 체크
- Windows에서 jq가 `$HOME/jq.exe`에 수동 다운로드되어 있어도 PATH에 없으면 실패
- 결과: 보안 hook이 모든 작업을 차단 (fail-closed)

**수정**:
- jq 탐색을 다단계 fallback으로 변경: `command -v jq` → `$HOME/jq.exe` → `/usr/local/bin/jq`
- 찾은 경로를 `$JQ_BIN` 변수에 저장하여 이후 호출에서 사용
- claude/hooks/, plugins/ai-setting-core/scripts/ 양쪽 모두 반영
- init.sh에서 jq 없을 때 자동 설치 프롬프트 추가 (macOS: brew, Linux: apt/yum, Windows: curl 다운로드)

---

### ISS-027: Cursor .mdc 파일의 @file 참조가 동작하지 않음 (⏳ 외부 대기)

**발견일**: 2026-03-22 (Phase 15 참조 검증)
**심각도**: 중간
**상태**: ⏳ Cursor 측 수정 대기

**문제**:
- `.cursor/rules/ai-setting.mdc`에서 `@AGENTS.md`, `@CLAUDE.md` 참조를 사용
- Cursor 공식 문서에는 `@file` 구문이 문서화되어 있지만 실제로 동작하지 않음
- Cursor 팀(deanrie)이 포럼에서 "아직 동작하지 않으며 곧 수정 예정"이라고 확인

**대응**:
- `@` 참조는 유지하되, 주석으로 미동작 상태를 명시
- 규칙 본문에 핵심 안내를 인라인으로 포함하여 참조 없이도 동작하도록 보완
- Cursor 측 수정 시 자동으로 동작 시작

**출처**: https://forum.cursor.com/t/does-file-syntax-works-in-mdc-rules/135663

---

### ISS-028: git 프로젝트에서 불필요한 백업 파일 생성 (✅ 수정 완료)

**발견일**: 2026-03-22
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-22)

**문제**:
- init/update 실행 시 `.claude.backup.*`, `.mcp.json.backup.*` 등 백업 파일이 무조건 생성됨
- git으로 관리되는 프로젝트에서는 `git checkout`으로 복구 가능하므로 백업이 불필요
- 반복 실행 시 백업 파일이 누적되어 디스크 낭비

**수정 제안**:
- `.git/` 디렉토리가 있으면 백업을 자동 스킵
- git이 아닌 프로젝트에서는 기존처럼 백업 유지

---

### ISS-026: npx 실행 시 Windows에서 bash shebang 인식 실패 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- `npx @jaewon94/ai-setting --help` 실행 시 Windows cmd.exe에서 "지정된 경로를 찾을 수 없습니다" 에러
- npm의 cmd-shim이 `#!/bin/bash` shebang을 `.cmd` wrapper로 변환하지만, `bash.exe`가 시스템 PATH에 없으면 실패
- v1.0.1에서 CRLF 문제는 수정했지만, Windows cmd.exe 환경에서의 bash 실행 자체가 불가

**수정**:
- `bin/ai-setting.js` Node.js wrapper 추가 — `#!/usr/bin/env node`로 모든 플랫폼 지원
- Windows에서 Git Bash 경로를 자동 탐색하여 bash 실행
- `package.json` bin 엔트리를 `.js`로 변경
- v1.0.2로 재배포

---

## 보류 메모

- Homebrew tap 배포는 자동화 코드까지 준비했지만, 실제 tap repo 생성과 GitHub variable/secret 설정은 추후 반영 예정
- ISS-010: ✅ 완료 (CRLF + Node.js wrapper로 최종 해결)

---

## StoryForge 실전 적용 전수 검증 (2026-03-21)

> StoryForge(FastAPI + Next.js 15 monorepo, Windows 11)에 `ai-setting --tools claude --merge --skip-ai --no-mcp`로 적용 후, 생성된 모든 파일을 하나씩 검증한 결과.

---

### ISS-017: --merge 시 PostToolUse에 포맷터 hook 중복 등록 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 높음 (포맷터 2회 실행 → 성능 저하, 충돌 가능)
**상태**: ✅ 수정 완료 (2026-03-21) — ISS-014와 동일 수정 (`_source` 마커 + strip_managed_hooks)

**문제**:
- merge 결과 `PostToolUse(Edit|Write)`에 두 블록이 공존:
  1. ai-setting의 `format-on-write.sh` + `async-test.sh`
  2. 프로젝트 기존 inline 포맷터 (`cd backend && uv run ruff ...`)
- 파일 저장마다 ruff/prettier가 **2번** 실행됨
- Stop hook의 prompt도 2번, Notification도 2번 (ISS-014와 동일 근본 원인)

**근본 원인**:
- `--merge`가 기존 hooks를 보존한 채 ai-setting hooks를 **추가**만 함
- 동일 기능(포맷팅, 알림, 종료 검사)의 중복 여부를 판단하는 로직이 없음

**수정 제안**:
- merge 시 동일 matcher를 가진 hook 배열 안에서, `command` 문자열에 ai-setting 관리 파일(`format-on-write.sh`, `async-test.sh` 등)이 포함된 기존 항목은 ai-setting 것으로 교체
- 또는 ai-setting hook에 식별 마커(`"_source": "ai-setting"`)를 넣어 기존 것과 구분 후, 기존 중 동일 기능은 제거

---

### ISS-018: format-on-write.sh — monorepo에서 작업 디렉토리 탐색 실패 가능 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- `find_parent_with_markers()`가 편집된 파일의 상위 디렉토리를 올라가며 `pyproject.toml` / `package.json`을 찾음
- StoryForge는 `backend/pyproject.toml`과 `frontend/package.json`이 분리됨
- hook에 전달되는 `file_path`가 **절대 경로**인지 **상대 경로**인지에 따라 `$PROJECT_DIR/$dir/$marker` 조합이 실패할 수 있음
- 특히 Windows에서 `C:\Users\...` 절대 경로가 전달되면 `PROJECT_DIR` 기준 상대 변환이 깨질 수 있음

**수정 제안**:
- hook 진입 시 file_path가 절대 경로면 PROJECT_DIR 기준 상대 경로로 변환하는 전처리 추가
- Windows 경로(`C:\...`)와 Git Bash 경로(`/c/...`) 혼용 대응

---

### ISS-019: async-test.sh — monorepo 루트에서 pytest 자동 감지 시 실행 실패 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- 자동 감지 로직이 프로젝트 루트에서 `uv.lock` + `tests/` 존재를 확인
- StoryForge는 `backend/` 아래에 `tests/`와 `pyproject.toml`이 있고, 루트에는 없음
- 루트에 `uv.lock`이 없으므로 자동 감지 자체가 실패하여 "unconfigured" skip됨
- `.ai-setting/test-command` 파일도 자동 생성되지 않음

**수정 제안**:
- init.sh에서 archetype이 `backend-api`이고 monorepo 구조 감지 시, `.ai-setting/test-command`를 자동 생성:
  ```
  cd backend && uv run pytest -q
  ```
- 또는 자동 감지에 `$PROJECT_DIR/backend/`, `$PROJECT_DIR/server/` 등 하위 탐색 추가

---

### ISS-020: docs/decisions.md, docs/research-notes.md — 프로젝트명 플레이스홀더 미치환 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-21)

**문제**:
- 두 문서 모두 제목이 `# [프로젝트명]`으로 남아 있음
- `--skip-ai`로 적용했으므로 AI 자동 채우기가 건너뛰어짐
- `--project-name` 옵션을 줬어도 이 필드는 치환되지 않는 것으로 보임 (rule-based fallback 없음)

**수정 제안**:
- `--skip-ai`여도 `--project-name`이 주어지면 `[프로젝트명]` → 실제 이름으로 치환하는 rule-based fallback 추가
- init.sh의 `detect_project_name` 결과를 이 필드에도 반영

---

### ISS-021: deploy/SKILL.md, fix-issue/SKILL.md — 플레이스홀더가 실행 가능 명령처럼 보임 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-21) — ISS-016/025과 동일 수정 (fill_rule_based_placeholders)

**문제**:
- `{{TEST_BACKEND_CMD}}`, `{{DEPLOY_BACKEND_CMD}}` 등이 코드 블록 안에 그대로 남아 있음
- Claude가 이 skill을 실행하면 `{{...}}` 문자열을 셸 명령으로 실행 시도 → 즉시 실패
- `disable-model-invocation: true`라 자동 호출은 안 되지만, 사용자가 `/deploy` 실행 시 혼란

**수정 제안**:
- ISS-016과 동일: `--skip-ai` 시에도 archetype/stack 기반 rule-based 치환 적용
- 미치환 플레이스홀더가 있는 skill은 실행 시 "아직 설정되지 않았습니다" 안내 출력

---

### ISS-022: settings.local.json에 세션 중 추가된 임시 permissions가 영구 잔류 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-21) — doctor에 과도한 permission 경고 추가

**문제**:
- Claude Code 세션 중 허용한 명령들이 `settings.local.json`에 자동 누적됨
- 그중 `curl -sL -o "$HOME/jq.exe"`, `ai-setting --tools claude ...` 같은 1회성 명령이 영구 허용 상태로 남음
- 이건 ai-setting의 문제라기보다 Claude Code의 동작이지만, ai-setting이 `--merge` 시 settings.local.json도 건드리므로 관련

**수정 제안**:
- ai-setting `--merge`가 settings.local.json을 건드릴 때, ai-setting 관리 항목만 추가/갱신하고 기존 사용자 허용 목록은 그대로 유지 (현재 동작과 동일하되, 문서화 필요)
- doctor 명령에서 "불필요하게 넓은 permission 감지" 경고 추가

---

### ISS-023: research.md agent가 WebSearch/WebFetch MCP 도구에 의존하나 MCP 미설정 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-21) — MCP 미설정 시 fallback 안내 추가

**문제**:
- `research.md`의 tools에 `WebSearch, WebFetch`가 명시됨
- `--no-mcp`로 적용했으므로 해당 MCP 서버가 설정되지 않음
- WebFetch는 Claude Code 내장 도구이므로 동작하지만, WebSearch는 MCP 없이는 사용 불가

**수정 제안**:
- `--no-mcp` 시 research agent의 tools에서 MCP 의존 도구를 제거하거나, "MCP 미설정 시 제한 동작" 안내 추가
- 또는 init.sh에서 `--no-mcp`와 research agent 조합일 때 경고 출력

---

## 전수 검증 요약

| 파일 | 평가 | 주요 이슈 |
|------|------|-----------|
| settings.json | ⚠️ 중복 hook 정리 필요 | ISS-014, ISS-017 |
| protect-files.sh | ⚠️ jq 부재 시 무력화 | ISS-011 |
| block-dangerous-commands.sh | ⚠️ jq 부재 시 무력화 | ISS-011 |
| format-on-write.sh | ⚠️ monorepo 경로 + jq 의존 | ISS-018 |
| async-test.sh | ⚠️ monorepo 자동감지 실패 + eval | ISS-012, ISS-019 |
| session-context.sh | ✅ 양호 | — |
| compact-backup.sh | ✅ 양호 | — |
| security-reviewer.md | ✅ 양호 | — |
| architect-reviewer.md | ✅ 양호 | — |
| test-writer.md | ✅ 양호 | — |
| research.md | ⚠️ MCP 의존 | ISS-023 |
| deploy/SKILL.md | ⚠️ 플레이스홀더 | ISS-021 |
| fix-issue/SKILL.md | ⚠️ 플레이스홀더 | ISS-021 |
| review/SKILL.md | ✅ 양호 | — |
| gap-check/SKILL.md | ✅ 양호 | — |
| cross-validate/SKILL.md | ✅ 양호 | — |
| BEHAVIORAL_CORE.md | ✅ 양호 | — |
| docs/decisions.md | ⚠️ 프로젝트명 미치환 | ISS-020 |
| docs/research-notes.md | ⚠️ 프로젝트명 미치환 | ISS-020 |
| settings.local.json | ⚠️ 임시 permission 잔류 | ISS-022 |

**적용 평가**: 23개 파일 중 12개 양호, 11개 조치 필요 — **구조는 우수하나 monorepo/Windows/--skip-ai 조합에서 마무리 부족**

---

## MCP preset 적용 검증 (2026-03-21)

> `--mcp-preset core,infra,web`로 `.mcp.json` 생성 후 검증

---

### ISS-024: serena MCP가 uvx에 의존하나 Windows에서 uvx 미설치 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 중간
**상태**: ✅ 수정 완료 (2026-03-21) — MCP preset 적용 시 command 실행 가능 여부 체크 + 경고 출력

**문제**:
- `.mcp.json`의 serena 항목이 `"command": "uvx"` 사용
- `uvx`는 `uv`에 포함된 도구 실행기인데, Windows bash PATH에 uv/uvx가 없음
- Claude Code 재시작 시 serena MCP 연결 실패 예상

**확인**:
```bash
which uvx  # → not found
which uv   # → not found (pip 설치는 했지만 bash PATH에 미포함)
```

**수정 제안**:
- init.sh에서 MCP preset 적용 시 `uvx`/`uv` 존재 여부 확인, 없으면 경고 출력
- 또는 serena를 npx 기반 대안으로 교체할 수 있는지 조사
- `--doctor`에서 MCP 서버별 실행 가능 여부 점검 항목 추가

---

## 생성 콘텐츠 프로젝트 적합성 평가 (2026-03-21)

> ai-setting이 생성한 agents, skills, 템플릿 문서가 StoryForge(FastAPI+Next.js monorepo, 소설 세계관 구축 플랫폼)에 **실제로 유용한 수준**인지 평가

---

### Agents 적합성

| Agent | StoryForge 적합도 | 평가 |
|-------|------------------|------|
| **security-reviewer** | ✅ 높음 | SQLAlchemy 파라미터 바인딩, `Depends(get_current_user)`, AI API 키 노출 점검 등 StoryForge 스택에 정확히 맞음. IDOR 점검도 프로젝트별 소유권 검증 패턴과 일치 |
| **architect-reviewer** | ✅ 높음 | Router/Service/Repository 관심사 분리, 200줄 제한, 네이밍 규칙 등 AGENTS.md의 기존 규칙과 완전 일치. 프로젝트 전용 커스텀 없이도 바로 활용 가능 |
| **test-writer** | ✅ 높음 | pytest+pytest-asyncio(백엔드), Vitest+RTL(프론트엔드) 정확히 매칭. AI 서비스 mock 처리 지침도 적합. 다만 StoryForge 고유의 conftest 패턴(reset_database, auth_headers fixture)은 언급 없음 — 범용이므로 자연스러움 |
| **research** | ⚠️ 중간 | 작업 흐름/출력 형식은 우수하나, tools에 `WebSearch`를 명시하고 있어 MCP 없으면 동작 불완전. 또한 `brave-search`를 예시로 들지만 실제 설치된 MCP에는 없음 |

**종합**: agents 4개 중 3개는 프로젝트에 즉시 활용 가능. research만 MCP 의존 문제.

---

### Skills 적합성

| Skill | StoryForge 적합도 | 평가 |
|-------|------------------|------|
| **deploy** | ❌ 낮음 | 7개 플레이스홀더(`{{TEST_BACKEND_CMD}}` 등) 전부 미치환. 실행하면 문자열 그대로 출력됨. StoryForge의 실제 명령(Docker Compose, Railway, Vercel)과 전혀 연결 안 됨 |
| **fix-issue** | ⚠️ 중간 | `gh issue view` → 코드 탐색 → 테스트 → 수정 → PR 흐름은 우수. 다만 `{{TEST_CMD}}`, `{{LINT_CMD}}` 2개 플레이스홀더 미치환 |
| **review** | ✅ 높음 | Security, Backend, Frontend, General 체크리스트가 StoryForge 스택에 정확히 맞음. "AI calls go through abstract interface" 항목은 ai-architecture.md의 핵심 원칙과 일치. 플레이스홀더 없음 |
| **gap-check** | ✅ 높음 | API/인증/DB/프론트엔드별 체크리스트가 AGENTS.md의 Coding Rules와 일치. "What If" 분석 + 결과 분류(must/should/nice_to_have)는 StoryForge의 Phase 기반 작업에 유용 |
| **cross-validate** | ✅ 높음 | AI 생성 문서를 실제 코드와 대조하는 흐름은 StoryForge의 docs/ 문서 관리에 직접 활용 가능. 불일치 분류(ERROR/WARNING/INFO)도 명확 |

**종합**: 5개 중 3개 즉시 활용 가능, 1개 부분 활용, 1개는 플레이스홀더 미치환으로 사용 불가.

---

### 템플릿 문서 적합성

| 문서 | StoryForge 적합도 | 평가 |
|------|------------------|------|
| **BEHAVIORAL_CORE.md** | ✅ 높음 | 5개 원칙 모두 범용적이면서도 실용적. "Prefer The Simplest Sufficient Change"는 AGENTS.md의 KISS/YAGNI와 상호보완. 프로젝트 커스텀 불필요 |
| **docs/decisions.md** | ⚠️ 중간 | 구조(D-xxx ID, 관련 조사 R-xxx 연결, 근거 문서)는 우수. 그러나 제목이 `[프로젝트명]` 그대로이고, StoryForge의 기존 결정(FastAPI 선택, SQLAlchemy 2.0, Claude API, PyJWT+pwdlib 등)이 하나도 기록되지 않음. 빈 템플릿 상태로 체크인됨 |
| **docs/research-notes.md** | ⚠️ 중간 | decisions.md와 동일 문제. 구조는 좋으나 빈 상태. StoryForge에는 이미 docs/ 아래 많은 문서가 있어 역할 중복 가능성도 있음 (docs/02-implementation/ 등) |

---

### ISS-025: --skip-ai 적용 시 생성 콘텐츠가 "범용 템플릿" 수준에 머무름 (✅ 수정 완료)

**발견일**: 2026-03-21
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-21) — fill_rule_based_placeholders() 함수로 archetype/stack 기반 자동 치환

**문제**:
- `--skip-ai`로 적용하면 AI 자동 채우기가 건너뛰어져 모든 생성 문서가 범용 템플릿 상태
- agents/skills는 범용이라 괜찮지만, docs/decisions.md와 docs/research-notes.md는 프로젝트명조차 미기입
- deploy, fix-issue skill의 플레이스홀더도 미치환
- 즉, `--skip-ai` 모드에서 "프로젝트에 맞게 만들어진" 결과물은 **archetype 규칙 삽입**(CLAUDE.md)과 **MCP preset** 뿐

**근본 원인**:
- `--skip-ai`가 AI 채우기를 완전히 건너뛰므로, 감지된 프로젝트 정보(이름, archetype, stack)를 활용한 rule-based 치환도 함께 건너뛰어짐
- `--project-name`, `--archetype`, `--stack` 힌트가 있어도 활용되지 않음

**수정 제안**:
- `--skip-ai`를 "AI LLM 호출 건너뛰기"로 한정하고, rule-based 치환(프로젝트명, 테스트 명령, 린트 명령 등)은 별도로 항상 실행
- 감지된 archetype + stack 조합에서 `{{TEST_BACKEND_CMD}}` 등을 자동 매핑하는 테이블 추가:
  ```
  backend-api + python-fastapi → TEST_BACKEND_CMD="cd backend && uv run pytest -q"
  frontend-web + nextjs        → TEST_FRONTEND_CMD="cd frontend && pnpm test"
  ```

---

### 최종 적합성 총평

| 카테고리 | 즉시 활용 | 조치 후 활용 | 사용 불가 |
|---------|----------|------------|----------|
| **Agents** (4) | 3 | 1 (research — MCP) | 0 |
| **Skills** (5) | 3 (review, gap-check, cross-validate) | 1 (fix-issue) | 1 (deploy) |
| **Hooks** (6) | 2 (session-context, compact-backup) | 4 (jq/uvx/monorepo 해결 필요) | 0 |
| **문서** (3) | 1 (BEHAVIORAL_CORE) | 2 (decisions, research-notes) | 0 |
| **MCP** (5) | 3 (sequential-thinking, context7, playwright) | 1 (docker — Docker 실행 시) | 1 (serena — uvx 없음) |

**총 23개 중 12개 즉시 활용, 9개 조치 후 활용, 2개 현재 사용 불가**

---

## 재적용 후 검증 (2026-03-22)

> ISS-011~024 수정 반영 후 StoryForge에 재적용(`ai-setting --tools claude --merge --skip-ai --mcp-preset core,infra,web`)한 결과.

---

### ISS-029: jq fail-closed 전환 후 Windows에서 모든 Bash/Edit 차단 (✅ 수정 완료)

**발견일**: 2026-03-22
**심각도**: 치명적 (Critical)
**상태**: ✅ 수정 완료 (2026-03-22) — jq PATH fallback + 자동 설치 프롬프트 (v1.1.2~v1.1.4)

**문제**:
- ISS-011 수정으로 `protect-files.sh`와 `block-dangerous-commands.sh`가 jq 미설치 시 `exit 2` (fail-closed)로 변경됨
- 보안 관점에서는 올바르지만, **jq가 시스템 PATH에 없는 환경에서 Claude Code가 완전히 무력화됨**
- Windows Git Bash에서는 `winget install jqlang.jq` 후에도 새 셸 세션 전까지 PATH 미반영
- `$HOME/jq.exe` 수동 다운로드도 `command -v jq`에 잡히지 않음

**영향**: Bash, Edit, Write 도구 전부 차단 → 코드 작성/실행 불가

**임시 해결** (StoryForge에서 직접 적용):
```bash
# hook 스크립트 상단의 jq 탐색을 확장
JQ_BIN=""
if command -v jq >/dev/null 2>&1; then
  JQ_BIN="jq"
elif [ -f "$HOME/jq.exe" ]; then
  JQ_BIN="$HOME/jq.exe"
elif [ -f "/usr/local/bin/jq" ]; then
  JQ_BIN="/usr/local/bin/jq"
fi
# 이후 jq 대신 $JQ_BIN 사용
```

**근본 수정 제안**:
1. hook 스크립트에 jq 경로 fallback 탐색 내장
2. `--doctor`에 jq PATH 도달 가능 여부 점검 추가
3. init.sh에서 jq 미설치 시 경고 + 설치 안내 출력
4. README에 "jq 필수 의존성" 명시

**근본 원인**: init.sh가 jq 의존성을 사전 점검하지 않고 hook 설치. fail-closed는 보안상 옳지만 의존성 가이드 없이 적용하면 사용 불가.

---

### ISS-030: 재적용 시 CLAUDE.md에 archetype 규칙이 중복 삽입됨 (✅ 수정 완료)

**발견일**: 2026-03-22
**심각도**: 중간
**상태**: ✅ 수정 완료 (v1.1.8)

**수정 이력**:
- v1.1.5: `<!-- ai-setting:archetype-rules -->` 마커 기반 교체 도입 → 재적용 시 중복 방지 ✅
- v1.1.5 잔존: 기존 한국어 "## API 규칙" 유지 + 영문 "## API Rules" 추가 삽입 → 한/영 중복 ✗
- v1.1.6~v1.1.7: 기존 비마커 섹션을 마커 블록으로 교체 → 중복 제거 ✅, 한국어→영문 교체 ✗
- v1.1.8: 마커 블록 교체 시 **기존 언어를 보존** → 한국어 그대로 유지 ✅

**v1.1.8 검증 결과**:
- 한국어 "## API 규칙" + 마커가 있는 상태에서 재적용 → 한국어 유지, 빈 줄 1개만 diff
- ISS-030 완전 해결

---

### ISS-031: Windows Notification powershell Popup이 포커스를 빼앗음 (✅ 수정 완료)

**발견일**: 2026-03-22
**심각도**: 낮음
**상태**: ✅ 수정 완료 (2026-03-22) — Popup timeout 3초 → 1초로 단축

**문제**: ISS-013 수정의 Windows 분기(`Wscript.Shell.Popup`)가 모달 팝업으로 포커스를 가져감 (macOS는 알림센터로 비침해)

**수정**: timeout을 1초로 줄여 자동 닫힘으로 포커스 빼앗김 최소화

---

### ISS-032: macOS/BSD sed 비호환으로 init 멱등성 및 `--skip-ai` 실행 실패 (✅ 수정 완료)

**발견일**: 2026-03-24
**심각도**: 높음
**상태**: ✅ 수정 완료 (2026-03-24)

**문제**:
- `init.sh`가 in-place 편집에 GNU sed 스타일 `sed -i`를 직접 사용
- macOS의 BSD sed에서는 같은 구문이 실패하여 `sed: invalid command code ...` 에러 발생
- 영향 범위:
  - `CLAUDE.md` archetype 마커 재삽입
  - `[프로젝트명]`, `{{TEST_CMD}}` 등 rule-based placeholder 치환
  - `./init.sh --skip-ai <target>` 기본 경로와 2회 실행 멱등성 테스트

**수정 내용**:
- `lib/common.sh`에 플랫폼 공통 텍스트 편집 헬퍼 추가
  - `replace_literal_in_file()`
  - `truncate_file_from_marker()`
- `init.sh`의 `sed -i` 사용 지점을 모두 공통 헬퍼로 교체
- 관련 테스트를 `sed -i` 문자열 검사가 아닌 portable helper 기준으로 갱신

**검증 기준**:
- macOS에서 `tests/test_basic.sh`의 `멱등성 (2회 실행)` 통과
- `./tests/run_all.sh` 전체 회귀 테스트 통과
