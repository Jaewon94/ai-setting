# Documentation Skill Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude 경로에서 바로 쓸 수 있는 문서화 스킬 팩(`document-feature`, `document-infra`, `document-security`)을 추가한다.

**Architecture:** 스킬은 `.claude/skills/*`와 core plugin mirror에 같은 구조로 넣고, profile 적용 로직과 문서/테스트를 함께 갱신한다. 1차는 Claude용 skill 본문에 집중하고, Codex metadata 연계는 이후 단계로 미룬다.

**Tech Stack:** Markdown skills, Bash profile installer, shell tests

---

### Task 1: Skill 자산 추가

**Files:**
- Create: `claude/skills/document-feature/SKILL.md`
- Create: `claude/skills/document-infra/SKILL.md`
- Create: `claude/skills/document-security/SKILL.md`
- Create: `plugins/ai-setting-core/skills/document-feature/SKILL.md`
- Create: `plugins/ai-setting-core/skills/document-infra/SKILL.md`
- Create: `plugins/ai-setting-core/skills/document-security/SKILL.md`

- [x] **Step 1: frontmatter와 호출 문구 설계**
- [x] **Step 2: 최소 문서 구조와 파일별 질문 정의**
- [x] **Step 3: core plugin mirror 반영**

### Task 2: 생성/동기화 경로 연결

**Files:**
- Modify: `lib/profile.sh`

- [x] **Step 1: managed path 목록에 새 skill 추가**
- [x] **Step 2: copy/link 경로에 새 skill 디렉토리 반영**

### Task 3: 문서와 테스트 반영

**Files:**
- Modify: `docs/reference.ko.md`
- Modify: `docs/reference.md`
- Modify: `tests/test_profiles.sh`

- [x] **Step 1: reference에 새 skill 역할 설명 추가**
- [x] **Step 2: standard profile에서 새 skill 생성 확인 테스트 추가**
- [x] **Step 3: 필요한 경우 minimal profile 미생성 확인 유지**

### Task 4: 회귀 검증

**Files:**
- Test: `tests/test_profiles.sh`
- Test: `./tests/run_all.sh`

- [ ] **Step 1: `bash tests/test_profiles.sh` 실행**
- [ ] **Step 2: `./tests/run_all.sh` 실행**
- [ ] **Step 3: 결과 정리 후 커밋**
