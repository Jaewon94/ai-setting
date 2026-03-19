# 이슈 관리

## 점검일: 2026-03-19

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

### ISS-003: Copilot 경로별 지침 미활용 (ℹ️ 개선 기회)

**발견일**: 2026-03-19
**심각도**: 낮음
**상태**: 📋 보류 (향후 개선)

**문제**:
- GitHub Copilot이 `*.instructions.md` 형태의 경로별 지침을 지원 ([공식 문서](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot))
- 현재는 copilot-instructions.md 1개만 생성

**해결 방향**:
- 3차 고도화 또는 사용자 피드백 시 경로별 지침 생성 검토

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

### ISS-006: settings.json merge 모드 필요 (📋 향후 개선)

**발견일**: 2026-03-19 (onDeviceAI-KOBOT 실전 테스트)
**심각도**: 높음
**상태**: 📋 향후 개선

**문제**: 기존 프로젝트에 이미 커스텀 settings.json이 있을 때, ai-setting이 기본 템플릿으로 덮어쓰면 프로젝트 전용 설정(포맷터 경로, 알림 메시지 등)이 사라짐
**해결 방향**: `--merge` 옵션으로 기존 settings.json에 없는 hook만 추가하는 모드

---

### ISS-007: 포맷터 경로가 monorepo에서 안 맞음 (📋 향후 개선)

**발견일**: 2026-03-19 (onDeviceAI-KOBOT 실전 테스트)
**심각도**: 중간
**상태**: 📋 향후 개선

**문제**: ai-setting 기본 포맷터가 `cd "$CLAUDE_PROJECT_DIR" && uv run ruff`인데, uv 안 쓰거나 frontend가 하위 디렉토리인 프로젝트에서 안 맞음
**해결 방향**: 포맷터 커스터마이징 가이드 또는 프로젝트 구조 기반 자동 조정

---

## 완료된 이슈

- ISS-001: CODEX.md 제거 ✅
- ISS-002: archetype partial 테스트 추가 ✅
- ISS-003: Copilot 경로별 지침 (보류)
- ISS-004: Codex reasoning 옵션 추가 ✅
- ISS-005: Gemini settings.json 개선 ✅
