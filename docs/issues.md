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

### ISS-010: npm publish 후 `npx` / `npm exec` 실행 경로 실패 (⚠️ 조사 필요)

**발견일**: 2026-03-20  
**심각도**: 높음  
**상태**: ⏳ 조사 중

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

## 보류 메모

- Homebrew tap 배포는 자동화 코드까지 준비했지만, 실제 tap repo 생성과 GitHub variable/secret 설정은 추후 반영 예정
