# 실전 적용 테스트: onDeviceAI-KOBOT

**적용일**: 2026-03-19
**대상**: 해양 KOBOT 관제 시스템 (FastAPI + React Native + ROS2/MQTT)
**적용 모드**: `--skip-ai --backup-all --no-mcp`

---

## 적용 전 상태

| 항목 | 상태 |
|------|------|
| .claude/settings.json | ✅ 있음 (프로젝트 커스텀: frontend 경로 포맷터, KOBOT 알림) |
| .claude/settings.local.json | ✅ 있음 (permissions 누적) |
| .claude/hooks/ | protect-files.sh 1개만 |
| .claude/agents/ | security-reviewer, test-writer 2개 |
| .claude/skills/ | deploy, dev-principles, fix-issue 3개 |
| .claude/rules/ | core, database, deployment, react-native 4개 (프로젝트 고유) |
| CLAUDE.md | ✅ 프로젝트 전용 (시스템 아키텍처, 문서 참조, 규칙 구조 정리) |
| AGENTS.md | ❌ 없음 |
| .mcp.json | ✅ 커스텀 (filesystem, brave-search + API 키, kobot_usage 메타) |
| .cursor/.gemini/.codex | ❌ 없음 |

## 적용 결과

### 추가된 것 ✅

| 파일 | 내용 |
|------|------|
| .claude/hooks/block-dangerous-commands.sh | 위험 명령 차단 (기존에 없었음) |
| .claude/hooks/async-test.sh | 비동기 테스트 hook |
| .claude/hooks/session-context.sh | compact 대비 컨텍스트 |
| .claude/hooks/compact-backup.sh | compact 복원용 스냅샷 |
| .claude/agents/architect-reviewer.md | 설계 검증 에이전트 |
| .claude/agents/research.md | 기술 리서치 에이전트 |
| .claude/skills/review/ | 코드 리뷰 체크리스트 |
| .claude/skills/gap-check/ | 빠진 요구사항 탐지 |
| .claude/skills/cross-validate/ | AI 출력물 교차검증 |
| AGENTS.md | 코딩 규칙/원칙 (새로 생성) |
| CLAUDE.md + backend-api partial | API 규칙 섹션 자동 삽입 |
| docs/decisions.md | 기술 의사결정 기록 (새로 생성) |

### 보존된 것 ✅

| 항목 | 설명 |
|------|------|
| .mcp.json | `--no-mcp`로 기존 커스텀 MCP 완전 보존 |
| CLAUDE.md | 기존 프로젝트 전용 내용 유지 (backend-api partial만 끝에 추가) |
| .claude/rules/ | core, database, deployment, react-native 4개 모두 보존 |
| .claude/skills/dev-principles | 프로젝트 고유 skill 보존 |
| settings.local.json | permissions 등 프로젝트 설정 보존 + merge 적용 |
| backup | .ai-setting.backup.20260319152735/에 전체 스냅샷 |

### Doctor 결과

- **OK: 19 / WARN: 7 / ERROR: 0**
- WARN은 모두 "선택 도구 미설치" (cursor, gemini, codex, copilot) 또는 "커스텀 프로필" — 정상

---

## 발견된 문제점

### 1. 포맷터 경로 불일치 (⚠️ 중요)

**문제**: ai-setting 기본 포맷터가 프로젝트 구조에 안 맞음
- **기존**: `ruff format "$FILE"` (uv 없이) + `cd frontend && npx prettier`
- **ai-setting 적용 후**: `cd "$CLAUDE_PROJECT_DIR" && uv run ruff format` + `cd "$CLAUDE_PROJECT_DIR" && npx prettier`
- 이 프로젝트는 uv를 안 쓰고, frontend가 하위 디렉토리라 루트에서 prettier가 안 돌 수 있음

**해결**: settings.local.json에 프로젝트 전용 포맷터 hook을 오버라이드로 넣어야 함

**ai-setting 개선 포인트**: 포맷터 hook을 프로젝트 구조에 맞게 커스터마이징하는 가이드 또는 자동 감지 기능 필요

### 2. Notification 메시지 변경 (⚠️ 경미)

**문제**: 기존 "KOBOT GCS" → ai-setting 기본값 "Claude Code"
**해결**: settings.local.json으로 오버라이드

### 3. 주 스택 미감지 (ℹ️ 참고)

**문제**: `주 스택: 미감지`로 나옴. 이 프로젝트는 Python(FastAPI) + TypeScript(React Native)인데, 명확한 감지 신호가 없었음
**원인**: pyproject.toml이 아닌 requirements.txt 기반이거나, 프로젝트 루트에 package.json이 없을 수 있음
**영향**: archetype은 backend-api로 정확히 감지됨. 스택 미감지는 Cursor rule 선택에만 영향

### 4. settings.json 덮어쓰기 방식 (⚠️ 구조적)

**문제**: 기존 프로젝트에 이미 잘 설정된 settings.json이 있는데, ai-setting이 기본 템플릿으로 덮어쓰고 settings.local.json으로 merge하는 방식
**개선 포인트**: 기존 settings.json에 없는 hook만 "추가"하는 merge 모드가 있으면 더 안전

---

## ai-setting 개선 포인트 (향후 고도화)

| 우선순위 | 항목 | 설명 |
|----------|------|------|
| 높음 | **settings.json merge 모드** | 기존 설정을 덮어쓰지 않고 없는 hook만 추가하는 `--merge` 옵션 |
| 높음 | **포맷터 커스터마이징 가이드** | monorepo(backend/frontend 분리) 프로젝트에서 포맷터 경로 설정법 |
| 중간 | **스택 감지 개선** | requirements.txt 기반 Python 감지, 서브디렉토리의 package.json 감지 |
| 낮음 | **Notification 프로젝트명 자동 삽입** | 프로젝트명을 알림 제목에 자동으로 넣기 |

---

## 결론

- ai-setting 적용 자체는 **안전하게 동작**함 (backup + --no-mcp + --skip-ai)
- **기존 프로젝트 고유 파일은 모두 보존**됨 (rules/, dev-principles, .mcp.json, CLAUDE.md)
- **새로 추가된 hooks/agents/skills는 실용적** (특히 block-dangerous-commands, compact-backup)
- **주요 개선점**: 기존 프로젝트에 적용할 때 settings.json을 덮어쓰기보다 merge하는 모드 필요
- **실전 피드백**: 포맷터 경로가 프로젝트별로 다르므로 일률적 적용이 어려움 → settings.local.json 또는 merge 모드로 해결해야 함
