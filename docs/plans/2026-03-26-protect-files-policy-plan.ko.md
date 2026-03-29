# Protect Files Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `protect-files.sh`를 `block / confirm / allow` 정책으로 정리하고, 프로젝트 override와 문서/테스트를 현재 설계 기준에 맞춘다.

**Architecture:** 기본 hard-block 규칙은 훅 내부에 유지하고, 프로젝트별 override는 `.ai-setting/protect-files.json`으로만 조정한다. 다만 hard-block 항목은 override로 완화하지 못하게 해서 안전 기준을 유지한다.

**Tech Stack:** Bash, jq, markdown docs, shell test suite

---

### Task 1: Hard-Block 우선순위 고정

**Files:**
- Modify: `claude/hooks/protect-files.sh`
- Modify: `plugins/ai-setting-core/scripts/protect-files.sh`
- Test: `tests/test_hooks.sh`

- [x] **Step 1: 현재 override 우선순위와 hard-block 충돌 확인**
- [x] **Step 2: hard-block 디렉토리/파일/확장자 검사를 override보다 먼저 실행**
- [x] **Step 3: hard-block은 override로 해제 불가 메시지 추가**
- [x] **Step 4: 테스트에서 credential 파일의 override allow 실패를 검증**

### Task 2: Override UX 문서화

**Files:**
- Modify: `templates/ko/protect-files.notes.md.template`
- Modify: `templates/en/protect-files.notes.md.template`
- Modify: `docs/usage.ko.md`
- Modify: `docs/usage.md`
- Modify: `docs/reference.ko.md`
- Modify: `docs/reference.md`

- [x] **Step 1: override의 목적과 hard-block 제한을 notes에 명시**
- [x] **Step 2: usage/reference에 project override와 hard-block 제한 반영**

### Task 3: 회귀 검증

**Files:**
- Test: `tests/test_hooks.sh`
- Test: `tests/test_basic.sh`
- Test: `tests/run_all.sh`

- [x] **Step 1: `bash tests/test_hooks.sh` 실행**
- [ ] **Step 2: `bash tests/test_basic.sh` 실행**
- [ ] **Step 3: `./tests/run_all.sh` 실행**
- [ ] **Step 4: 결과 반영 후 커밋**
