# ai-setting 고도화 로드맵

---

## 1차 고도화 (✅ 완료)

> v0.1.0 → v1.0.0
> 기본 부트스트랩 도구에서 멀티 도구 · 프로필 · 동기화 · 플러그인 · 배포까지 갖춘 완성된 설정 자동화 도구로 확장

### 완료 체크

- [x] Priority 0: 프로젝트 로컬 MCP preset 도입
- [x] Priority 1: `blank-start / docs-first / hybrid / code-first` 분기 도입
- [x] Priority 2: archetype / stack 자동 감지
- [x] Priority 3: `doctor / dry-run / diff / backup-all / reapply` 도입
- [x] Phase 1: 멀티 도구 지원 (Claude Code, Codex, Cursor, Gemini CLI, Copilot)
- [x] Phase 2: 동기화 시스템 (symlink, update, sync, manifest 옵션, 충돌 감지, settings.local.json)
- [x] Phase 3: 프로필 시스템 (standard, minimal, strict, team)
- [x] Phase 4: 플러그인 마켓플레이스 (core/strict/team 분리, install/uninstall/check-update CLI)
- [x] Phase 5: 고급 hooks (branch 보호, async test, compact backup, session context, team webhook)
- [x] Phase 6: 커뮤니티 & 배포 (CI/CD, npm 준비, brew formula, LICENSE, SECURITY, issue templates)

### 현재 상태 (v1.1.8, 2026-03-24 기준)

```
init.sh 실행 → profile 적용 → 로컬 MCP preset 생성 → 템플릿 복사 → 프로젝트 모드/archetype 감지 → Claude autofill (timeout) → Codex fallback → 수동 안내
```

| 영역 | 구현 내용 |
|------|-----------|
| **Claude Code** | standard/minimal/strict/team 프로필, hooks 7개, agents 4개, skills 5개 |
| **멀티 도구** | Cursor (.cursor/rules), Gemini CLI (.gemini), GitHub Copilot (.github), Codex (.codex) |
| **MCP** | core(기본)/web(선택)/infra(선택) preset, `--auto-mcp` archetype 기반 자동 적용 |
| **감지** | blank-start/docs-first/hybrid/code-first 모드, 8종 archetype, 9종 스택 자동 감지 |
| **안전** | doctor, dry-run, diff, backup-all, reapply |
| **동기화** | `--link`(파일), `--link-dir`(디렉토리), update, sync(manifest), settings.local.json override, `--sync-conflict` |
| **플러그인** | ai-setting-core/strict/team, `plugin list\|install\|uninstall\|check-update\|upgrade` |
| **배포** | package.json v1.1.8, MIT, CI/CD, release workflow (npm auto-publish), brew formula |
| **문서** | BEHAVIORAL_CORE.md, CLAUDE.md, AGENTS.md, GEMINI.md, copilot-instructions.md, research-notes.md, decisions.md 템플릿 |

추가 상태:
- `CLAUDE.md` 공통 템플릿에 도구 역할 분담과 프로필 운영 기준 반영 완료
| **신뢰성** | research-notes / decisions 추적성 구조, doctor 문서 형식 검사, session/backup 반영 |
| **검증** | `./tests/run_all.sh` 기준 회귀 테스트, macOS/BSD sed 비호환 제거, field test 4건 문서화 |

### 1차 고도화 상세 (아카이브)

<details>
<summary>Priority 0: 프로젝트 로컬 MCP 도입</summary>

> "글로벌에만 있던 MCP를 새 프로젝트에서도 바로 쓴다"

- `init.sh`가 프로젝트 로컬 MCP 설정도 함께 생성
- 이 저장소가 소유한 preset 기준으로 생성 (글로벌 복사 아님)
- API 키 없이 바로 사용할 수 있는 MCP만 포함

| preset | 서버 | 기본 포함 |
|--------|------|-----------|
| `core` | sequential-thinking, serena, upstash-context-7-mcp | ✅ |
| `web` | playwright | 선택 |
| `infra` | docker | 선택 |

</details>

<details>
<summary>Priority 1: 문서/구현 기준 분기</summary>

> "문서만 있으면 문서를 따르고, 구현이 있으면 실제 상태를 먼저 보며, 아무 근거가 없으면 과추론하지 않는다"

| 모드 | 우선 기준 | 처리 방식 |
|------|-----------|-----------|
| `blank-start` | 확인 가능한 사실만 | 안전한 초기화, AI 자동 채우기 건너뛰기 |
| `docs-first` | 문서 | 문서 기준 작성, 미구현은 TODO 표시 |
| `hybrid` | 코드 + 문서 | 코드 먼저, 문서는 보완용 |
| `code-first` | 코드 | 코드 우선, 문서와 불일치 시 명시 |

</details>

<details>
<summary>Priority 2: 다언어/프레임워크/비웹 프로젝트 확장</summary>

> archetype 기반 지원 구조

감지 대상: `frontend-web`, `backend-api`, `cli-tool`, `worker-batch`, `data-automation`, `library-sdk`, `infra-iac`, `general-app`
스택 감지: Next.js, Vite, Node, Python, Go, Rust, Java/Kotlin, Ruby, PHP

</details>

<details>
<summary>Priority 3: Doctor / Safe Reapply / Diff Preview</summary>

> "반복 실행해도 안전하고, 무엇이 문제인지 바로 진단할 수 있다"

- `--doctor`: 필수 바이너리, 설정 파일, hook 실행 가능 여부, placeholder 잔존 점검
- `--dry-run`: 실제 변경 없이 예정 작업 출력
- `--diff`: 관리 대상 파일 unified diff
- `--backup-all`: 관리 대상 전체 snapshot
- `--reapply`: 템플릿 재생성 + AI 재실행

</details>

<details>
<summary>Phase 1~6 상세</summary>

**Phase 1 (멀티 도구)**: Cursor .mdc, Gemini settings/GEMINI.md, Copilot instructions
**Phase 2 (동기화)**: --link, --link-dir, update, sync manifest, settings.local.json, --sync-conflict
**Phase 3 (프로필)**: standard/minimal/strict/team, 프로필별 hooks/agents/skills 차등 적용
**Phase 4 (플러그인)**: marketplace.json, core/strict/team 분리, plugin CLI (list/install/uninstall/check-update/upgrade)
**Phase 5 (고급 hooks)**: branch 보호, async test, compact backup, session context, team webhook
**Phase 6 (배포)**: CI/CD, npm v1.0.1, brew formula, MIT LICENSE, SECURITY.md, issue templates

</details>

---

## 2차 고도화 (예정)

> v1.0.0 → v2.0.0
> 코드 구조 개선, 멀티 도구 지원 심화, 테스트 자동화, 배포, 생태계 확장

### 완료 체크

- [x] Phase 7: init.sh 모듈 분리
- [ ] Phase 8: 멀티 도구 지원 심화 (Cursor, Gemini CLI, Copilot, Codex)
- [ ] Phase 9: 테스트 자동화
- [x] Phase 10: 실제 배포 실행 (npm 배포 + Homebrew 설치 검증 완료)
- [ ] Phase 11: MCP preset 확장
- [x] Phase 12: 커뮤니티 플러그인 생태계 (가이드 문서)
- [x] Phase 13: archetype별 템플릿 특화

### 2차 고도화 최신 메모

- Copilot path-specific instructions 생성 완료
- `--merge` 모드로 기존 `.claude/settings.json` 보존 + hook 병합 완료
- monorepo-aware `format-on-write.sh` 적용 완료
- `BEHAVIORAL_CORE.md` 공통 행동 코어 도입 완료
- `docs/research-notes.md` / `docs/decisions.md` 추적성 구조와 doctor 검증 완료
- Claude timeout 후 Codex fallback까지 포함한 AI autofill 안정화 완료
- npm scoped package `@jaewon94/ai-setting@1.0.1` publish 완료 (v1.0.0 bin CRLF 문제 수정)
- tag push 기반 npm auto-publish + GitHub Release 자동화 동작 확인
- Homebrew tap repo 생성, GitHub variable/secret 설정, `brew install` / `brew test` 검증 완료
- ISS-010~025 전수 검증 이슈 16건 일괄 수정 (보안, 크로스플랫폼, monorepo, merge 중복 등)
- `prepare_target_context()` 도입으로 `init` / `add-tool` 경로의 대상 절대경로화 + 컨텍스트 감지 중복 제거
- 실전 검증 문서:
  - `docs/field-test-kobot.md`
  - `docs/field-test-research-traceability.md`
  - `docs/field-test-ai-autofill.md`
  - `docs/field-test-python-backend.md`

---

### Phase 7: init.sh 모듈 분리 ⭐ 최우선

> "단일 파일 ~3000행을 유지보수 가능한 구조로 분리한다"

초기에는 `init.sh`가 모든 기능을 포함하여 약 3000행 규모였고, Phase 8 이후 기능 추가 전에 구조 정리가 필요했다. 현재는 엔트리 기준 약 100행 수준까지 축소했다.

#### 구현 지침

- 분리 전 전체 기능의 스모크 테스트를 통과하는 baseline을 확보한다
- 함수 의존 관계를 먼저 파악하고, 순환 참조 없이 분리한다
- 각 모듈은 독립적으로 `bash -n` 통과해야 한다
- 분리 후 기존 모든 모드/옵션이 동일하게 동작하는지 회귀 검증한다

#### 분리 구조

```
ai-setting/
├── init.sh                    # 메인 엔트리 (옵션 파싱 + 실행 흐름, ~300행)
├── lib/
│   ├── common.sh              # 색상, dry-run, mkdir, copy, symlink 헬퍼
│   ├── ai-autofill.sh         # AI 자동 채우기 프롬프트/실행/fallback
│   ├── cli.sh                 # CLI 파싱, 서브커맨드 전처리, 모드 검증
│   ├── deps.sh                # jq 의존성 점검/설치 제안
│   ├── detect.sh              # 프로젝트 모드/archetype/스택 감지
│   ├── doctor.sh              # doctor 진단 로직
│   ├── init-flow.sh           # Step 1~5 실행과 요약 출력
│   ├── sync.sh                # sync manifest, 충돌 감지, settings.local.json
│   ├── plugin.sh              # plugin list/install/uninstall/check-update/upgrade
│   └── mcp.sh                 # MCP preset 생성
```

#### 완료 기준

- `init.sh`가 300행 이내로 축소
- `bash -n init.sh lib/*.sh` 모두 통과
- 기존 모든 모드/옵션이 동일하게 동작 (회귀 없음)
- `bin/ai-setting` 래퍼가 변경 없이 동작

#### 최신 상태

- `init.sh`: 약 94행
- 분리 완료 모듈: `cli.sh`, `deps.sh`, `init-flow.sh`, `ai-autofill.sh` 포함
- 회귀 검증: `./tests/run_all.sh` 기준 `PASS 120 / FAIL 0`

#### 다음 착수 단위

1. 모듈 경계가 바뀔 때는 `CONTRIBUTING.md`, `docs/reference*`의 책임 표를 같이 갱신
2. 큰 단계 분리 후에는 테스트 시나리오가 새로운 경계를 커버하는지 확인
3. 메인 엔트리는 오케스트레이터 역할만 유지하고 세부 로직은 lib로 계속 이동

---

### Phase 8: 멀티 도구 지원 심화 ⭐ 최우선

> "설정 파일 복사 수준에서 각 도구의 고유 기능을 활용하는 수준으로 끌어올린다"

상위 실행 계획: [`docs/plans/execution-plan.ko.md`](plans/execution-plan.ko.md)

상세 실행 계획: [`docs/plans/tool-specialization-plan.ko.md`](plans/tool-specialization-plan.ko.md)

현재 Cursor/Gemini/Copilot/Codex의 1차 특화는 반영됐지만, 문서화 스킬 팩과 스킬/훅 메타데이터 표준화까지 포함한 Phase 8 전체는 아직 진행 중이다.

#### 구현 지침

- **반드시 각 도구의 공식 문서를 먼저 확인**하고 최신 설정 스키마/기능을 파악한다
- 커뮤니티 베스트 프랙티스 (cursorrules.org, awesome-cursorrules 등)를 참고한다
- 각 도구마다 실제로 해당 도구를 실행해서 설정이 적용되는지 검증한다
- 기존 AGENTS.md/CLAUDE.md의 규칙을 각 도구 형식에 맞게 변환하되, 도구 고유 기능도 활용한다

#### 8-1. Cursor 지원 심화

현재: 공통 rule + stack rule + archetype rule 생성이 가능하지만, 세분화와 검증 범위를 더 넓혀야 함

목표:
- **glob 패턴 기반 파일 타입별 규칙** 추가 (Cursor의 핵심 차별점)
- always/auto/manual/agent-requested 타입 분리 활용
- 프로젝트 archetype별 Cursor rule 변형

참고 자료:
- [Cursor Rules 공식 문서](https://docs.cursor.com/context/rules)
- [cursorrules.org](https://cursorrules.org/) — 커뮤니티 규칙 생성기
- [awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules)

추가 대상 예시:
```
.cursor/rules/
├── ai-setting.mdc            # 기존: 프로젝트 공통 규칙 (always)
├── typescript.mdc            # glob: **/*.ts,**/*.tsx — TS 코딩 규칙
├── python.mdc                # glob: **/*.py — Python 코딩 규칙
├── testing.mdc               # glob: **/*.test.*,**/*.spec.* — 테스트 규칙
└── docs.mdc                  # glob: **/*.md — 문서 작성 규칙
```

#### 8-2. Gemini CLI 지원 심화

현재: `.gemini/settings.json`, `.gemini/settings.notes.md`, `GEMINI.md`까지 생성 가능하지만 Gemini 전용 운영 규칙은 더 다듬을 여지가 있음

목표:
- Gemini CLI의 고유 설정 옵션 활용 (sandbox mode, model 설정 등)
- `GEMINI.md`에 Gemini 특화 지침 추가 (tool use 패턴, 응답 형식 등)
- `.gemini/` 디렉토리의 추가 설정 파일 활용

참고 자료:
- [Gemini CLI Configuration](https://geminicli.com/docs/reference/configuration/)
- [Gemini CLI GitHub](https://github.com/google-gemini/gemini-cli)

#### 8-3. GitHub Copilot 지원 심화

현재: repository-wide instruction + stack/archetype path-specific instructions까지 생성 가능하지만 세부 규칙 축약과 경로 범위는 더 다듬을 여지가 있음

목표:
- Copilot의 파일별 지침 (`*.test.ts` 패턴 등) 활용
- `copilot-instructions.md`에 프로젝트 구조, 네이밍 컨벤션, API 패턴 등 Copilot 특화 지침 추가
- VS Code settings 연동 (`.vscode/settings.json`의 Copilot 관련 설정)

참고 자료:
- [GitHub Copilot Instructions 공식 문서](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)
- [Copilot Best Practices](https://github.blog/developer-skills/github/how-to-use-github-copilot-in-your-ide-tips-tricks-and-best-practices/)

#### 8-4. Codex CLI 지원 심화

현재: `.codex/config.toml`, `.codex/config.notes.md`, `AGENTS.md` 조합으로 운영 가능하며, AGENTS archetype 보강까지 반영됨. 세부 정책 정리는 추가 여지가 있음

목표:
- Codex의 approval_policy 세분화 (suggest/auto-edit/full-auto)
- 프로필별 Codex 설정 차등 적용
- Codex는 AGENTS.md를 자동으로 읽으므로 별도 지침 파일 불필요 (공식 문서 확인 완료)

참고 자료:
- [Codex CLI Config Reference](https://developers.openai.com/codex/config-reference/)
- [Codex CLI GitHub](https://github.com/openai/codex)

#### 8-5. 문서화 스킬 팩 추가

현재: 배포/레퍼런스/로드맵/이슈 문서는 정리돼 있지만, downstream 프로젝트에서 기능/인프라/보안 문서를 구조적으로 남기는 skill은 아직 없음

목표:
- `document-feature`, `document-infra`, `document-security` 성격의 명시적 문서화 skill 제공
- `docs/features/*`, `docs/infrastructure/*`, `docs/security/*` 구조 표준화
- 전역 문서(`docs/decisions.md`, `docs/research-notes.md`)와 주제별 문서의 경계 명확화

구현 방향:
- 자동 생성이 아니라 명시적 호출 skill로 둔다
- 각 skill은 폴더 규칙과 문서별 질문만 강하게 정의하고 boilerplate는 최소화한다
- README에는 요약/링크만 두고 상세는 주제별 문서 폴더로 내린다

#### 8-6. 스킬/훅 메타데이터 표준화

현재: skill frontmatter와 hook 설정은 동작 중심으로만 관리되고 있어, 적용 범위와 운영 맥락을 한눈에 파악하기 어렵다

목표:
- 공식 문서가 지원하는 메타데이터 필드는 적극 활용
- 공식 필드가 없는 운영 정보는 sidecar notes 또는 manifest로 표준화
- 이후 doctor/test에서 metadata 기반 진단이 가능하도록 구조를 고정

구현 방향:
- Codex skill: `name`, `description`, `agents/openai.yaml` 활용 검토
- Claude hook: `type`, `matcher`, `timeout`, `async`, prompt/agent hook 활용 후보 정리
- 내부 운영 필드:
  - `profile_scope`
  - `required_tools`
  - `required_mcp`
  - `risk_level`
  - `blocking_or_async`

#### 8-7. 파일 보호 정책 재설계

현재: `protect-files.sh`는 민감 파일 보호에 유효하지만, 정책이 사실상 일괄 차단 중심이라 실제 프로젝트 작업에서는 불편할 수 있음

목표:
- 파일 보호를 `block / confirm / allow` 3단계로 재설계
- 진짜 고위험 자산은 계속 강하게 보호
- 운영 중 자주 수정하는 파일은 무조건 차단 대신 확인 기반 흐름으로 완화

구현 방향:
- `block`: 키/인증서/credential/DB/생성물
- `confirm`: `.env*`, `docker-compose*.yml`, workflow, deploy script, infra config, lockfile
- `allow`: 일반 코드/문서/테스트
- 프로젝트별 override와 profile 차등 적용 가능성까지 함께 설계

#### 완료 기준

- 각 도구에서 설정이 실제로 적용되고 동작하는지 검증
- 도구별 2개 이상의 특화 규칙/설정 추가
- archetype 감지와 연동하여 도구별 규칙이 프로젝트 유형에 맞게 생성
- README에 도구별 지원 수준 표를 ★ 3개 이상으로 끌어올림

---

### Phase 9: 테스트 자동화

> "CI에서 스모크 테스트를 넘어 체계적인 회귀 테스트를 실행한다"

Phase 7 모듈 분리와 함께 진행하면 분리 과정의 회귀를 방지할 수 있다.

#### 테스트 범위

| 카테고리 | 테스트 항목 |
|----------|-------------|
| **프로필** | 4개 프로필별 파일 생성/미생성 검증 |
| **모드** | blank-start/docs-first/hybrid/code-first 감지 정확도 |
| **archetype** | 8종 archetype 감지 fixture |
| **동기화** | link, link-dir, update, sync manifest (옵션 포함), 충돌 전략 |
| **플러그인** | install → verify → uninstall → verify 라운드트립 |
| **override** | settings.local.json merge 결과 검증 |
| **멱등성** | 같은 명령 2회 실행 시 결과 동일 |
| **에지 케이스** | jq 미설치, 빈 프로젝트, 기존 설정 있는 프로젝트 |

#### 구현 방향

```
tests/
├── fixtures/
│   ├── blank-project/
│   ├── docs-only-project/
│   ├── nextjs-project/
│   ├── python-api-project/
│   └── ...
├── test_profiles.sh
├── test_detect.sh
├── test_sync.sh
├── test_plugin.sh
└── run_all.sh
```

#### 완료 기준

- `./tests/run_all.sh` 한 번에 전체 테스트 실행
- CI에서 fixture 테스트 자동 실행
- 새 기능 추가 시 테스트 없으면 CI 실패하도록 가이드

---

### Phase 10: 실제 배포 실행 (완료)

> "준비된 배포 파이프라인을 실제로 가동한다"

배포 인프라는 실제 운영 상태까지 검증 완료했다.
현재는 `npx @jaewon94/ai-setting`와 `brew install Jaewon94/ai-setting/ai-setting` 경로를 모두 사용할 수 있다.

실행 체크리스트: `docs/deployment-checklist.md`

| 항목 | 준비 상태 | 실행 시 할 일 |
|------|-----------|--------------|
| `git push` | ✅ origin에 push 완료 | — |
| `npm publish` | ✅ 배포 완료 | tag push 시 자동 publish |
| GitHub repo | ✅ public | — |
| brew tap | ✅ tap + formula 검증 완료 | release/tag 갱신 시 formula 반영 유지 |
| CI | ✅ 동작 중 | lint + test 자동 실행 |
| sync-conf.dev | ⏳ | 등록 대기 |

#### 실행 시점 기준

- 다른 사람에게 `npx @jaewon94/ai-setting`으로 공유하고 싶을 때
- 팀 프로젝트에서 `brew install Jaewon94/ai-setting/ai-setting`으로 배포하고 싶을 때
- 커뮤니티 피드백을 받고 싶을 때

---

### Phase 11: MCP preset 확장

> "1차에서 보류했던 MCP를 조건부로 추가한다"

| 분류 | MCP | 조건 | 선행 작업 |
|------|-----|------|-----------|
| `local-tools` | `filesystem` | 허용 루트 정책 설계 완료 후 | 보안 스코프 정의, allowedDirectories 설정 자동화 |
| `local-tools` | `git` | 권한 정책 정의 후 | read-only 기본, write는 opt-in |
| `web-debug` | `Chrome DevTools` | web preset 선택 시 | playwright와 역할 구분 문서화 |
| `frontend-addon` | `Agentation` | React/Next archetype일 때 | React 18+ 감지 로직 |
| `next-addon` | `Next.js DevTools` | Next.js 스택일 때 | next.config 감지와 연동 |
| `api-key` | `brave-search` | API 키 제공 시 | `.env` 기반 키 주입 패턴 설계 |

#### 완료 기준

- preset 추가 시 `--mcp-preset` 옵션으로 선택 가능
- archetype 감지와 연동하여 `--auto-mcp`에서 자동 추천
- 보안 민감 MCP는 opt-in + 문서 경고

---

### Phase 12: 커뮤니티 플러그인 생태계

> "외부 기여자가 자신만의 플러그인을 만들어 공유할 수 있다"

| 항목 | 설명 |
|------|------|
| 플러그인 작성 가이드 | `docs/plugin-guide.md` — hooks.json/plugin.json 작성법, 디렉토리 구조 |
| 템플릿 스캐폴더 | `ai-setting plugin create <name>` — 빈 플러그인 구조 자동 생성 |
| 원격 플러그인 설치 | `ai-setting plugin install <github-url>` — git clone 기반 |
| 플러그인 레지스트리 | `registry.json` 중앙 카탈로그 또는 awesome-ai-setting-plugins 목록 |
| 호환성 검증 | 플러그인 간 hook 충돌 감지, settings merge 안전성 검증 |

#### 완료 기준

- 외부 기여자가 가이드만 보고 플러그인을 만들 수 있다
- GitHub URL로 원격 플러그인 설치 가능
- 플러그인 간 충돌 시 경고 메시지 출력

---

### Phase 13: archetype별 템플릿 특화

> "프로젝트 유형에 따라 더 정확한 기본 설정을 제공한다"

| archetype | 특화 내용 |
|-----------|-----------|
| `frontend-web` | lint/format 명령, 번들 사이즈 체크, 컴포넌트 테스트 기본값 |
| `backend-api` | API 테스트, DB 마이그레이션 체크, health check 관련 기본값 |
| `cli-tool` | CLI 인수 테스트, 맨페이지/help 생성 관련 기본값 |
| `data-automation` | 데이터 검증, 파이프라인 테스트 기본값 |
| `infra-iac` | plan/apply 안전장치, drift 감지 관련 기본값 |

#### 구현 방향

```
templates/
├── CLAUDE.md.template              # 공통
├── archetype/
│   ├── frontend-web.partial.md     # archetype별 추가 섹션
│   ├── backend-api.partial.md
│   ├── cli-tool.partial.md
│   └── ...
```

#### 완료 기준

- archetype별 CLAUDE.md에 유형 특화 섹션이 자동 삽입
- 공통 템플릿과 archetype partial이 깔끔하게 합성
- 새 archetype partial 추가가 쉬운 구조

---

### 2차 고도화 우선순위 요약

| Phase | 핵심 | 난이도 | 효과 | 순서 |
|-------|------|--------|------|------|
| **Phase 7** | init.sh 모듈 분리 | 중간 | 유지보수성 대폭 향상 | ⭐ 1순위 |
| **Phase 8** | 멀티 도구 특화 | 중간 | Cursor/Gemini/Copilot 실질적 가치 | ⭐ 1순위 |
| **Phase 9** | 테스트 자동화 | 중간 | 회귀 방지, 품질 보증 | 2순위 |
| **Phase 10** | 실제 배포 실행 | 쉬움 | npm/brew로 누구나 설치 가능 | 3순위 |
| **Phase 11** | MCP preset 확장 | 중간 | 프로젝트별 최적 도구 제공 | 4순위 |
| **Phase 12** | 커뮤니티 플러그인 | 중간~높음 | 생태계 확장, 외부 기여 | 5순위 |
| **Phase 13** | archetype 템플릿 특화 | 중간 | 프로젝트별 정확도 향상 | 6순위 |

#### 권장 순서

1. **Phase 7 (모듈 분리)** → **Phase 8 (멀티 도구 심화)** — 동시 진행 가능, 최우선
2. **Phase 9 (테스트)** — 모듈 분리 직후 회귀 검증 체계 구축
3. **Phase 10 (배포)** — 안정화 후 실제 배포
4. **Phase 11~13** — 사용자 피드백 반영하며 순차 진행

---

## 3차 고도화 (장기 방향)

> v2.0.0 → v3.0.0
> 로컬 LLM 지원, 설정 참조 검증, 상용/로컬 통합 아키텍처

### 현재 한계

현재 ai-setting은 상용 AI 도구(Claude Code, Codex, Cursor, Gemini CLI, Copilot)만 지원한다. 각 도구마다 별도 설정 파일을 생성하고, `@참조`로 AGENTS.md/CLAUDE.md를 가리키는 구조지만:
- 각 도구가 실제로 `@파일` 참조를 지원하는지 **전수 검증이 되지 않았음**
- 로컬 LLM 도구(Aider, Continue.dev, Tabby 등)는 **전혀 미지원**
- 도구가 늘어날수록 비슷한 내용의 설정 파일이 **중복 증가**

### Phase 14: 로컬 LLM 도구 지원

> "Ollama/LM Studio 기반 로컬 모델로도 같은 규칙을 적용한다"

대상 도구:

| 도구 | 형태 | 설정 파일 | 메모 |
|------|------|-----------|------|
| **Aider** | CLI | `.aider.conf.yml`, `.aiderignore` | Ollama/OpenAI-compatible 지원 |
| **Continue.dev** | VS Code/JetBrains | `.continue/config.json` | 로컬/원격 모델 모두 지원 |
| **Tabby** | Self-hosted 서버 | 서버 설정 + 클라이언트 연동 | 코드 완성 + 채팅 |

구현 방향:
- 각 도구의 공식 문서를 **먼저 확인**하여 설정 스키마와 파일 참조 방식을 파악
- AGENTS.md/CLAUDE.md를 참조할 수 있으면 참조, 못 하면 도구별 규칙 변환 생성
- `--local-llm` 또는 `--tool aider` 같은 옵션으로 선택적 생성

### Phase 15: 설정 참조 방식 전수 검증 (✅ 검증 완료, 2026-03-22)

> "각 도구가 실제로 @파일 참조를 지원하는지 검증하고, 안 되는 건 대안을 찾는다"

검증 결과:

| 도구 | @파일 참조 | 검증 결과 | 대응 |
|------|-----------|-----------|------|
| Claude Code | ✅ 동작 | `@path/to/file` 구문, 최대 5단계 재귀 | 그대로 유지 |
| Gemini CLI | ✅ 동작 | `@./path/to/file.md` 구문 지원 | 그대로 유지 |
| Cursor | ⏳ 미동작 | 공식 문서에 있지만 Cursor 팀 확인 "곧 수정 예정" | @참조 유지 + 주석 표기 (ISS-027) |
| Copilot | ❌ 미지원 | 독립 파일만 가능, `applyTo` 경로별 instructions 동작 | 이미 독립 파일로 구현됨 |
| Codex CLI | — (자동 읽기) | AGENTS.md 디렉토리 계층 자동 발견 | 그대로 유지 |
| Aider | 미확인 | Phase 14에서 검증 예정 | — |
| Continue | 미확인 | Phase 14에서 검증 예정 | — |

출처:
- Cursor: https://forum.cursor.com/t/does-file-syntax-works-in-mdc-rules/135663
- Gemini: https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html
- Copilot: https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot
- Claude Code: https://code.claude.com/docs/en/memory
- Codex: https://developers.openai.com/codex/guides/agents-md

### Phase 16: 통합 설정 아키텍처

> "상용이든 로컬이든, 어떤 AI 도구를 써도 AGENTS.md + CLAUDE.md 하나로 동일한 규칙이 적용된다"

최종 목표 구조:
```
AGENTS.md          ← 단일 소스 오브 트루스 (코딩 규칙, 금지 패턴, 원칙)
CLAUDE.md          ← 단일 소스 오브 트루스 (프로젝트 설정, 빌드, 도메인)
    │
    ├─ 직접 읽기: Claude Code, (검증 후 추가)
    │
    └─ 어댑터 생성: 도구별 최소 설정 파일
         ├─ .cursor/rules/*.mdc
         ├─ .gemini/settings.json
         ├─ .github/copilot-instructions.md
         ├─ .codex/config.toml (AGENTS.md 자동 읽기)
         ├─ .aider.conf.yml
         ├─ .continue/config.json
         └─ (향후 도구)
```

핵심 원칙:
- 규칙/컨벤션은 **AGENTS.md + CLAUDE.md에만** 작성
- 각 도구 설정은 **참조(지원 시)** 또는 **최소 변환(미지원 시)**으로만 생성
- 도구가 아무리 늘어나도 **수정할 곳은 하나** — 중복 제거
- `init.sh`가 도구별 어댑터를 자동 생성하는 역할

### ~~Phase 17: 도구 선택적 설치~~ (✅ 2차로 앞당겨 구현 완료)

2차 고도화 Phase 7/8과 함께 구현됨:
- 기본값: Claude Code만 설치
- `--tools claude,cursor`: 특정 도구 조합
- `--all`: 전체 도구 설치
- `add-tool <tool>`: 기존 프로젝트에 도구 추가

---

### 3차 고도화 우선순위

| Phase | 핵심 | 선행 조건 |
|-------|------|-----------|
| **Phase 14** | 로컬 LLM 도구 지원 | 각 도구 공식 문서 확인 |
| **Phase 15** | 설정 참조 전수 검증 | 실제 도구 설치 + 테스트 |
| **Phase 16** | 통합 설정 아키텍처 | Phase 14, 15 결과 기반 |
| **Phase 17** | 도구 선택적 설치 | 사용자 피드백 |

---

## 참고 자료

- [rulebook-ai](https://github.com/botingw/rulebook-ai) — 멀티 도구 규칙 생성
- [sync-conf.dev](https://sync-conf.dev/) — Git 기반 설정 동기화
- [agentsync](https://github.com/dallay/agentsync) — Rust CLI 심링크 동기화
- [agent-sync](https://github.com/ZacheryGlass/agent-sync) — 통합 동기화 도구
- [Trail of Bits claude-code-config](https://github.com/trailofbits/claude-code-config) — 보안 중심 설정
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 65+ 스킬, 12+ 에이전트
- [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) — 127+ 서브에이전트
- [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) — 549+ 스킬
- [cursorrules.org](https://cursorrules.org/) — Cursor 규칙 생성기
- [Claude Code Plugin Marketplace](https://code.claude.com/docs/en/plugin-marketplaces)
- [Gemini CLI Configuration](https://geminicli.com/docs/reference/configuration/)
- [Codex CLI Config Reference](https://developers.openai.com/codex/config-reference/)
- [AI Dotfiles 패턴](https://dylanbochman.com/blog/2026-01-25-dotfiles-for-ai-assisted-development/)
- [Aider](https://aider.chat/) — AI pair programming CLI (Ollama/OpenAI-compatible)
- [Continue.dev](https://continue.dev/) — VS Code/JetBrains AI 확장 (로컬/원격 모델)
- [Tabby](https://tabby.tabbyml.com/) — Self-hosted AI 코딩 어시스턴트
