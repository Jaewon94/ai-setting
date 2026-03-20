# 실전 적용 테스트: AI 자동 채우기

**적용일**: 2026-03-20
**대상**: 샘플 React + TypeScript 프로젝트 (`package.json`, `src/`, `README.md`)
**적용 모드**: `--all`

---

## 적용 목적

이번 테스트의 목적은 다음 3가지를 확인하는 것입니다.

1. `init.sh`의 AI 자동 채우기 단계가 실제 CLI 문법과 맞는지
2. 자동 채우기 실패 시 fallback 메시지가 충분히 안내되는지
3. `docs/research-notes.md`와 `docs/decisions.md`가 실패 시에도 안전하게 남는지

---

## 테스트 결과

### 1. Claude Code 경로

- 로컬에 `claude` 명령은 존재했음
- 하지만 샘플 프로젝트에서 자동 채우기 호출이 응답 없이 대기 상태로 남았음
- 따라서 이번 테스트에서는 성공/실패를 최종 판정하지 못했고, 운영 관점에서는 timeout 또는 더 빠른 fallback 조건이 있으면 좋다는 점이 확인됨

### 2. Codex fallback 경로

- 기존 구현은 `codex -q "$AI_PROMPT"`를 사용하고 있었음
- 현재 설치된 Codex CLI(`codex --help`, `codex exec --help` 확인)에서는 비대화 실행이 `codex exec [PROMPT]` 형태임
- 따라서 기존 fallback은 현재 CLI 기준으로 실패할 수 있음
- 이번 수정으로 `codex exec --skip-git-repo-check "$AI_PROMPT"`로 변경함

### 3. 실패 시 결과물

- AI 자동 채우기가 실패해도 아래 문서는 기본 템플릿으로 남음
  - `CLAUDE.md`
  - `AGENTS.md`
  - `GEMINI.md`
  - `.github/copilot-instructions.md`
  - `docs/research-notes.md`
  - `docs/decisions.md`
- 즉, 자동 채우기 실패가 프로젝트 초기화를 깨뜨리지는 않음
- 사용자는 fallback 안내에 따라 수동 보정 또는 재실행을 선택할 수 있음

---

## 확인 근거

- 로컬 CLI 도움말:
  - `codex --help`
  - `codex exec --help`
- 샘플 프로젝트 실행:
  - `./init.sh --all /tmp/ai-setting-fieldtest-ai`
  - `PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" ./init.sh --all /tmp/ai-setting-fieldtest-codex-fresh`

---

## 해석

### 좋아진 점

- Codex fallback이 현재 CLI 구조에 맞게 정리됨
- git 저장소가 아닌 새 프로젝트에서도 `--skip-git-repo-check`로 비대화 실행이 가능해짐
- AI 자동 채우기 실패 시에도 문서 뼈대와 추적성 구조는 안전하게 보존됨
- Claude Code가 응답 없이 오래 대기하면 기본 `20s` 후 Codex fallback으로 넘어가도록 보강함

### 남는 과제

- 자동 채우기 성공 시 실제 placeholder가 얼마나 잘 채워지는지는 추가 field test가 필요함
- Codex 경로는 CLI 문법은 맞췄지만, 로그인 상태나 네트워크 제약에 따라 실패할 수 있음

---

## 결론

- 이번 검증으로 **Codex fallback 호출 방식에 실제 호환성 문제가 있었다는 점**을 확인했고, 현재 CLI 기준으로 수정함
- 또한 **AI 자동 채우기 실패가 초기화 전체 실패로 이어지지 않도록 설계되어 있음**을 다시 확인함
- 이어서 **Claude Code hang 시 timeout 후 Codex fallback** 운영 안전장치도 추가함
