# 실전 적용 테스트: Python backend

**적용일**: 2026-03-20
**대상**: 샘플 FastAPI 프로젝트 (`pyproject.toml`, `app/`, `tests/`, `README.md`)
**적용 모드**: `--skip-ai --all`

---

## 적용 목적

이번 테스트의 목적은 다음 4가지를 확인하는 것입니다.

1. Python 프로젝트에서 `backend-api` archetype과 `Python` 스택이 올바르게 감지되는지
2. `CLAUDE.md`와 `AGENTS.md`에 backend-api 관련 규칙이 실제로 반영되는지
3. `doctor`가 Python 프로젝트 기준으로 async test 자동 감지와 autofill readiness를 올바르게 보여주는지
4. 배포 전 대표 스택이 Node.js 외에도 최소 한 번 더 검증됐는지

---

## 샘플 프로젝트 구성

| 파일 | 역할 |
|------|------|
| `pyproject.toml` | Python 프로젝트 메타데이터 + pytest 설정 |
| `app/main.py` | FastAPI health endpoint |
| `tests/test_health.py` | 최소 pytest 시나리오 |
| `README.md` | 문서 신호 제공 |

---

## init 결과

샘플 프로젝트에 `./init.sh --skip-ai --all /tmp/ai-setting-fieldtest-python` 적용 결과:

- 해석 모드: `hybrid`
- 프로젝트 유형: `backend-api`
- 주 스택: `Python`
- MCP preset: `core`

생성된 주요 파일:

- `.claude/settings.json`
- `.cursor/rules/ai-setting.mdc`
- `.gemini/settings.json`
- `.codex/config.toml`
- `.mcp.json`
- `BEHAVIORAL_CORE.md`
- `CLAUDE.md`
- `AGENTS.md`
- `GEMINI.md`
- `.github/copilot-instructions.md`
- `docs/research-notes.md`
- `docs/decisions.md`

특이점:

- `CLAUDE.md`에 `backend-api` partial이 실제로 삽입됨
- `--skip-ai` 기준이므로 템플릿 placeholder는 남아 있음

---

## 문서 결과

### CLAUDE.md

- 공통 규칙(`BEHAVIORAL_CORE.md`, `AGENTS.md`) import 유지
- `## API 규칙` 섹션이 자동 삽입됨
- health check, 입력 검증, 마이그레이션 도구, 인증/인가 분리 같은 backend-api 기본 규칙이 포함됨

### AGENTS.md

- backend-api archetype agent rules가 반영됨
- Python style 규칙이 기본 제공됨
- `ruff`, type hints, async 우선, Pydantic v2, SQLAlchemy 2.0 async style 지침이 포함됨
- `--skip-ai`라서 프로젝트 고유 설명/명령/구조 placeholder는 남아 있음

### Copilot instructions

- 저장소 공통 규칙은 생성됨
- 프로젝트별 build/test/lint placeholder는 AI 자동 채우기 또는 수동 작성이 필요함

---

## Doctor 결과

샘플 프로젝트에 `./init.sh --doctor /tmp/ai-setting-fieldtest-python` 실행 결과:

- `claude CLI 실행 가능`
- `codex exec 실행 가능`
- `AI 자동 채우기 준비됨 — Claude 우선, 실패/timeout 시 Codex fallback`
- `async test 자동 감지 가능 (pytest -q)`
- `docs/decisions.md 관련 조사 형식 확인`
- `docs/research-notes.md 출처 링크 형식 확인`

요약:

- **OK: 36 / WARN: 4 / ERROR: 0**
- WARN은 모두 `--skip-ai`로 인해 placeholder가 남아 있는 항목이라 정상 범주

---

## 해석

### 좋아진 점

- Node.js 샘플 외에 Python backend에서도 감지와 doctor 흐름이 안정적으로 동작함
- `backend-api` partial 삽입이 실제로 확인됨
- async test가 `pytest -q`로 자동 감지되어 Python 프로젝트 기본 경험이 자연스러움
- 배포 전 대표 스택 커버리지가 한 단계 더 올라감

### 남는 한계

- `--skip-ai` 기준이라 프로젝트별 build/test/lint 명령과 설명 placeholder는 그대로 남음
- 실제 AI 자동 채우기 성공 품질은 Python 프로젝트에서도 별도 검증이 더 필요함
- FastAPI 예시는 최소 구성이라 DB, migration, env, Docker 같은 운영 신호까지는 아직 검증하지 않음

---

## 결론

- ai-setting은 `Python backend` 최소 프로젝트에서도 감지, archetype 규칙 삽입, doctor readiness, async-test 자동 감지까지 안정적으로 동작함
- 배포 전 field test 포트폴리오는 이제 다음 4축을 갖춤
  - 기존 실프로젝트 적용 (`field-test-kobot`)
  - 출처 추적 구조 (`field-test-research-traceability`)
  - autofill fallback 안정화 (`field-test-ai-autofill`)
  - Python backend 대표 스택 검증 (`field-test-python-backend`)

다음 단계는 이 상태를 바탕으로 `docs/deployment-checklist.md` 순서대로 실제 배포를 실행하는 것임
