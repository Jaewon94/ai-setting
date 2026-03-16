# ai-setting 고도화 로드맵

> 현재 상태: init.sh로 Claude Code + Codex 설정 복사 + AI 자동 채우기
> 목표: 멀티 AI 도구 지원, 자동 동기화, 프로필 시스템

## 현재 상태 (v0)

```
init.sh 실행 → 파일 복사 → AI가 템플릿 채우기
```

- Claude Code: settings.json, hooks 2개, agents 4개, skills 5개
- Codex: config.toml
- Templates: CLAUDE.md, AGENTS.md, decisions.md
- 한계: 복사 방식이라 원본 업데이트 시 재실행 필요, Claude/Codex만 지원

---

## Phase 1: 멀티 도구 지원

> "AI 도구가 뭐든 같은 규칙이 적용된다"

### 1-1. Cursor 지원 추가
- `.cursor/rules/*.mdc` 파일 생성
- AGENTS.md 템플릿의 Coding Rules를 `.mdc` 형식으로 변환
- init.sh에 `.cursor/rules/` 복사 추가
- **난이도**: 쉬움 (포맷 변환만)
- **참고**: cursorrules.org, awesome-cursorrules

### 1-2. Gemini CLI 지원 추가
- `.gemini/settings.json` 템플릿
- `GEMINI.md` (= CLAUDE.md의 Gemini 버전)
- init.sh에 `.gemini/` 복사 추가
- **난이도**: 쉬움 (JSON 템플릿)
- **참고**: geminicli.com/docs/reference/configuration/

### 1-3. GitHub Copilot 지원 추가
- `.github/copilot-instructions.md` 생성
- AGENTS.md의 규칙을 Copilot 형식으로 변환
- **난이도**: 쉬움

### 결과
```
init.sh 실행 후:
  .claude/      → Claude Code
  .codex/       → Codex CLI
  .cursor/      → Cursor
  .gemini/      → Gemini CLI
  .github/      → GitHub Copilot
```

---

## Phase 2: 동기화 시스템

> "한 곳을 고치면 모든 프로젝트에 반영된다"

### 2-1. Symlink 기반 동기화 (stow 패턴)
현재 방식 (복사):
```
ai-setting/ --cp--> project-a/.claude/
            --cp--> project-b/.claude/
            --cp--> project-c/.claude/
# ai-setting 업데이트해도 프로젝트에는 반영 안 됨
```

개선 방식 (심링크):
```
~/.ai-setting/claude/ <--symlink-- project-a/.claude/
                      <--symlink-- project-b/.claude/
                      <--symlink-- project-c/.claude/
# ai-setting 업데이트하면 모든 프로젝트에 즉시 반영
```

- `init.sh --link` 옵션 추가 (복사 대신 심링크)
- 프로젝트별 오버라이드: `.claude/settings.local.json` 같은 로컬 설정
- **난이도**: 쉬움
- **참고**: GNU Stow, agentsync, AI dotfiles 패턴

### 2-2. 업데이트 명령
```bash
# 원본이 업데이트된 후 프로젝트에 반영
ai-setting update /path/to/project

# 또는 심링크 모드에서는 git pull만 하면 됨
cd ~/.ai-setting && git pull
```

---

## Phase 3: 프로필 시스템

> "프로젝트 성격에 따라 다른 설정을 적용한다"

### 프로필 구조
```
ai-setting/
├── profiles/
│   ├── standard/     # 현재 기본값 (균형잡힌 설정)
│   ├── strict/       # 보안 강화, 모든 체크 활성화
│   ├── minimal/      # 최소 설정 (hooks + 포맷터만)
│   └── team/         # 팀 프로젝트용 (리뷰 강화, PR 규칙)
```

### 프로필별 차이

| 항목 | minimal | standard | strict | team |
|------|---------|----------|--------|------|
| protect-files hook | ✅ | ✅ | ✅ | ✅ |
| block-commands hook | — | ✅ | ✅ | ✅ |
| auto-format hook | ✅ | ✅ | ✅ | ✅ |
| test-check (Stop) | — | ✅ | ✅ | ✅ |
| security-reviewer | — | ✅ | ✅ | ✅ |
| architect-reviewer | — | ✅ | ✅ | ✅ |
| gap-check skill | — | ✅ | ✅ | ✅ |
| cross-validate skill | — | — | ✅ | ✅ |
| branch 보호 hook | — | — | ✅ | ✅ |
| PR 템플릿 | — | — | — | ✅ |

### 사용법
```bash
# 기본 (standard)
init.sh /path/to/project

# 프로필 지정
init.sh --profile strict /path/to/project
init.sh --profile minimal /path/to/project
```

- **난이도**: 중간
- **참고**: rulebook-ai의 packs 시스템, Trail of Bits 보안 프로필

---

## Phase 4: 플러그인 마켓플레이스

> "다른 사람들이 만든 에이전트/스킬을 설치하고, 내 것도 공유한다"

### Claude Code 플러그인 형식
```json
// .claude-plugin/marketplace.json
{
  "name": "ai-setting",
  "version": "1.0.0",
  "description": "AI 코딩 도구 공통 설정",
  "components": {
    "agents": ["security-reviewer", "architect-reviewer", ...],
    "skills": ["deploy", "review", "gap-check", ...],
    "hooks": ["protect-files", "block-dangerous-commands"]
  }
}
```

### 사용법 (마켓플레이스 등록 후)
```
/plugin marketplace add jaewon/ai-setting
/plugin marketplace update
```

- init.sh 없이 Claude Code 안에서 바로 설치
- 업데이트 자동 전파
- **난이도**: 중간
- **참고**: anthropics/claude-plugins-official, SkillsMP

---

## Phase 5: 고급 hooks

> "더 똑똑한 자동화"

### 5-1. 브랜치 보호 hook
```bash
# main/master 브랜치에 직접 커밋 차단
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "Blocked: 직접 커밋 금지. feat/fix 브랜치에서 PR로 머지하세요." >&2
  exit 2
fi
```

### 5-2. 비동기 테스트 실행 hook
- PostToolUse에서 코드 변경 감지 시 백그라운드로 테스트 실행
- 결과를 다음 프롬프트에 주입

### 5-3. Slack/Discord 알림 hook
- HTTP hook으로 작업 완료/실패 시 팀 채널에 알림
- `"type": "command"` → `curl -X POST webhook_url`

### 5-4. 컴팩션 컨텍스트 주입 hook
- PreCompact 시점에 핵심 컨텍스트를 별도 파일에 백업
- SessionStart에서 복원

- **난이도**: 쉬움~중간
- **참고**: claude-code-hooks-mastery, pixelmojo CI/CD 패턴

---

## Phase 6: 커뮤니티 & 배포

> "더 많은 사람이 쓰고, 더 많은 사람이 기여한다"

### 6-1. sync-conf.dev 등록
- 커뮤니티 디렉토리에 등록하여 `npx sync-conf install jaewon/ai-setting`으로 설치 가능

### 6-2. npm/brew 패키지화
```bash
# npm
npx ai-setting init /path/to/project

# 또는 brew
brew install ai-setting
ai-setting init /path/to/project
```

### 6-3. public 전환 + 기여 가이드
- 현재 private → public 전환
- CONTRIBUTING.md (에이전트/스킬 추가 방법)
- 프로필/언어별 기여 가이드

---

## 우선순위 요약

| Phase | 핵심 | 난이도 | 효과 |
|-------|------|--------|------|
| **Phase 1** | Cursor/Gemini/Copilot 지원 | 쉬움 | 사용자 3배 확대 |
| **Phase 2** | Symlink 동기화 | 쉬움 | 유지보수 비용 제거 |
| **Phase 3** | 프로필 시스템 | 중간 | 포크 방지, 맞춤 적용 |
| **Phase 4** | 플러그인 마켓플레이스 | 중간 | 네이티브 배포, 자동 업데이트 |
| **Phase 5** | 고급 hooks | 쉬움~중간 | 자동화 강화 |
| **Phase 6** | 커뮤니티 & 배포 | 쉬움~중간 | 생태계 참여 |

### 권장 순서
1. **Phase 1-1 (Cursor)** + **Phase 2-1 (Symlink)** — 가장 빠르게 가장 큰 효과
2. **Phase 3 (프로필)** — 다양한 프로젝트 대응
3. **Phase 5-1 (브랜치 보호)** — 바로 추가 가능한 실용 hook
4. 나머지는 필요에 따라

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
