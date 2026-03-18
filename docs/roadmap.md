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

### 현재 상태 (v1.0.0)

```
init.sh 실행 → profile 적용 → 로컬 MCP preset 생성 → 템플릿 복사 → 프로젝트 모드/archetype 감지 → AI가 템플릿 채우기
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
| **배포** | package.json v1.0.0, MIT, CI/CD, release workflow, brew formula |
| **문서** | CLAUDE.md, AGENTS.md, GEMINI.md, copilot-instructions.md, decisions.md 템플릿 |

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
**Phase 6 (배포)**: CI/CD, npm v1.0.0, brew formula, MIT LICENSE, SECURITY.md, issue templates

</details>

---

## 2차 고도화 (예정)

> v1.0.0 → v2.0.0
> 실제 배포 실행, 코드 품질 개선, MCP 확장, 테스트 자동화, 커뮤니티 생태계 구축

### 완료 체크

- [ ] Phase 7: 실제 배포 실행
- [ ] Phase 8: init.sh 모듈 분리
- [ ] Phase 9: 테스트 자동화
- [ ] Phase 10: MCP preset 확장
- [ ] Phase 11: 커뮤니티 플러그인 생태계
- [ ] Phase 12: archetype별 템플릿 특화

---

### Phase 7: 실제 배포 실행

> "준비된 배포 파이프라인을 실제로 가동한다"

1차 고도화에서 배포 *준비*는 완료했지만, 실제 실행은 아직이다.

| 항목 | 현재 상태 | 할 일 |
|------|-----------|-------|
| `git push` | 로컬에 미push 커밋 있음 | origin에 push |
| `npm publish` | package.json 준비 완료, `private` 제거됨 | `npm publish` 실행 |
| GitHub repo | private | public 전환 |
| brew tap | Formula 파일 존재 | 별도 `homebrew-ai-setting` repo 생성 후 formula 등록 |
| sync-conf.dev | 미등록 | 커뮤니티 디렉토리 등록 |
| CI 검증 | workflow 파일 존재 | push 후 GitHub Actions 통과 확인 |

#### 완료 기준

- `npx ai-setting init ./my-project` 로 바로 설치 가능
- `brew install jaewon/tap/ai-setting` 으로 설치 가능
- CI가 push/PR마다 자동 실행
- tag push 시 npm + GitHub Release 자동 생성

---

### Phase 8: init.sh 모듈 분리

> "단일 파일 ~3000행을 유지보수 가능한 구조로 분리한다"

현재 `init.sh`가 모든 기능을 포함하여 약 3000행에 달한다. 기능별로 분리하면 가독성과 유지보수성이 크게 향상된다.

#### 분리 구조

```
ai-setting/
├── init.sh                    # 메인 엔트리 (옵션 파싱 + 실행 흐름)
├── lib/
│   ├── common.sh              # 색상, dry-run, mkdir, copy, symlink 헬퍼
│   ├── detect.sh              # 프로젝트 모드/archetype/스택 감지
│   ├── doctor.sh              # doctor 진단 로직
│   ├── sync.sh                # sync manifest, 충돌 감지, settings.local.json
│   ├── plugin.sh              # plugin list/install/uninstall/check-update/upgrade
│   ├── mcp.sh                 # MCP preset 생성
│   └── ai-fill.sh             # AI 자동 채우기 프롬프트/실행
```

#### 완료 기준

- `init.sh`가 300행 이내로 축소
- `bash -n lib/*.sh` 모두 통과
- 기존 모든 모드/옵션이 동일하게 동작 (회귀 없음)

---

### Phase 9: 테스트 자동화

> "CI에서 스모크 테스트를 넘어 체계적인 회귀 테스트를 실행한다"

현재는 CI에서 기본 스모크 테스트만 돌린다. fixture 기반 시나리오 테스트를 추가한다.

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

### Phase 10: MCP preset 확장

> "1차에서 보류했던 MCP를 조건부로 추가한다"

1차 고도화에서 보류/후보로 남긴 MCP를 조건부 preset으로 추가한다.

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

### Phase 11: 커뮤니티 플러그인 생태계

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

### Phase 12: archetype별 템플릿 특화

> "프로젝트 유형에 따라 더 정확한 기본 설정을 제공한다"

현재 archetype 감지는 AI 프롬프트에 힌트를 주는 수준이다. 2차에서는 archetype별로 다른 템플릿과 기본값을 제공한다.

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

| Phase | 핵심 | 난이도 | 효과 |
|-------|------|--------|------|
| **Phase 7** | 실제 배포 실행 | 쉬움 | npm/brew로 누구나 설치 가능 |
| **Phase 8** | init.sh 모듈 분리 | 중간 | 유지보수성 대폭 향상 |
| **Phase 9** | 테스트 자동화 | 중간 | 회귀 방지, 품질 보증 |
| **Phase 10** | MCP preset 확장 | 중간 | 프로젝트별 최적 도구 제공 |
| **Phase 11** | 커뮤니티 플러그인 | 중간~높음 | 생태계 확장, 외부 기여 |
| **Phase 12** | archetype 템플릿 특화 | 중간 | 프로젝트별 정확도 향상 |

#### 권장 순서

1. **Phase 7 (배포 실행)** — 가장 먼저, 나머지는 배포 후
2. **Phase 8 (모듈 분리)** — 다음 기능 추가 전에 구조 정리
3. **Phase 9 (테스트)** — 모듈 분리와 함께 진행
4. **Phase 10 (MCP 확장)** — 사용자 피드백 반영
5. **Phase 11 (커뮤니티)** — 생태계 성장
6. **Phase 12 (템플릿 특화)** — 장기 고도화

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
