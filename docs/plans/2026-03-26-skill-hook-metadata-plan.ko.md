# Skill Hook Metadata Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude skills와 hooks에 대한 운영용 metadata manifest를 도입하고, 설치 경로/문서/테스트까지 연결한다.

**Architecture:** 공식 필드는 기존 frontmatter와 hooks.json에 유지하고, 운영용 필드는 중앙 manifest(`.claude/skills/metadata.json`, `.claude/hooks/metadata.json`)로 분리한다. manifest는 repo 자산과 core plugin mirror 모두에 두고, downstream 프로젝트에도 설치되게 한다.

**Tech Stack:** JSON manifests, Bash profile installer, shell tests

---

### Task 1: Metadata Manifest 추가

**Files:**
- Create: `claude/skills/metadata.json`
- Create: `claude/hooks/metadata.json`
- Create: `plugins/ai-setting-core/skills/metadata.json`
- Create: `plugins/ai-setting-core/hooks/metadata.json`

- [ ] **Step 1: skill metadata 필드 정의**
- [ ] **Step 2: hook metadata 필드 정의**
- [ ] **Step 3: core plugin mirror에도 동일 구조 반영**

### Task 2: 설치 경로 반영

**Files:**
- Modify: `lib/profile.sh`

- [ ] **Step 1: managed path 목록에 metadata 파일 추가**
- [ ] **Step 2: file copy와 link-dir 모두에서 metadata가 유지되게 반영**

### Task 3: 문서와 테스트 반영

**Files:**
- Modify: `docs/reference.ko.md`
- Modify: `docs/reference.md`
- Modify: `tests/test_profiles.sh`
- Modify: `tests/test_hooks.sh`

- [ ] **Step 1: reference에 metadata manifest 위치와 의미 추가**
- [ ] **Step 2: profile 테스트에 metadata 파일 생성 확인 추가**
- [ ] **Step 3: hook 테스트에 metadata 핵심 필드 존재 확인 추가**

### Task 4: 회귀 검증

**Files:**
- Test: `bash tests/test_profiles.sh`
- Test: `bash tests/test_hooks.sh`
- Test: `./tests/run_all.sh`

- [ ] **Step 1: 개별 테스트 실행**
- [ ] **Step 2: 전체 회귀 실행**
- [ ] **Step 3: 결과 정리 후 커밋**
