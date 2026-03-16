# AI Setting - 새 프로젝트용 AI 도구 공통 설정

> 새 프로젝트에 Claude Code, Codex 등 AI 코딩 도구 설정을 한 번에 적용.
> StoryForge, TaskRelay + 커뮤니티 베스트 프랙티스에서 추출.

## 빠른 시작

```bash
# init 스크립트 한 줄이면 끝
/path/to/ai-setting/init.sh /path/to/my-new-project

# 또는 현재 디렉토리에 적용
cd my-new-project
/path/to/ai-setting/init.sh .
```

실행하면:
```
[1/5] Claude Code 설정 복사 (.claude/)
  ✅ settings.json, hooks 2개, agents 4개, skills 5개
[2/5] Codex CLI 설정 복사 (.codex/)
  ✅ config.toml
[3/5] 템플릿 복사
  ✅ CLAUDE.md 생성됨
  ✅ AGENTS.md 생성됨
[4/5] AI로 CLAUDE.md / AGENTS.md 자동 생성
  🔄 Claude Code로 프로젝트 분석 중...
  ✅ Claude Code가 CLAUDE.md / AGENTS.md를 자동 생성했습니다
[5/5] 완료!
```

### 동작 방식

```
init.sh 실행
  │
  ├─ 1~3단계: 공통 설정 파일 복사 (즉시 완료)
  │
  └─ 4단계: AI가 프로젝트를 분석해서 CLAUDE.md / AGENTS.md 자동 채우기
       │
       ├─ Claude Code 있으면 → Claude Code가 처리
       ├─ 없으면 Codex 있으면 → Codex가 처리
       └─ 둘 다 없으면 → 수동 안내 메시지 출력
```

### 옵션

```bash
# AI 자동 채우기 건너뛰기 (복사만)
/path/to/ai-setting/init.sh --skip-ai /path/to/my-new-project
```

## 적용 후 확인

### 그대로 사용 (수정 불필요)
- `.claude/settings.json` — hooks, 포맷터, 알림 전부 포함
- `.claude/hooks/*` — 보호 파일 차단 + 위험 명령 차단
- `.claude/agents/*` — 보안 리뷰, 설계 검증, 테스트 작성, 리서치
- `.claude/skills/*` — 배포, 코드 리뷰, 이슈 수정, Gap 체크, 교차검증
- `.codex/config.toml` — Codex CLI 기본 설정

### AI가 자동 생성한 파일 확인
`CLAUDE.md`와 `AGENTS.md`가 프로젝트에 맞게 채워졌는지 확인.
AI 생성이 실패했거나 `--skip-ai`로 건너뛴 경우 `[대괄호]` 부분을 직접 채우거나:
```
claude "CLAUDE.md와 AGENTS.md의 [대괄호] 부분을 채워줘"
```

### 프로젝트별 선택 추가

**protect-files.sh에 패턴 추가** (필요 시):
```bash
# DB 마이그레이션 보호
"alembic/versions/"

# Docker/설정 파일 보호
"compose.yaml"
"pyproject.toml"

# 데이터 디렉토리 보호
"data/"
```

**프로젝트 고유 agents/skills 추가** (필요 시):
```
.claude/agents/card-content-generator.md   ← StoryForge 예시
.claude/agents/spec-writer.md              ← TaskRelay 예시
.claude/skills/db-schema/SKILL.md          ← 도메인 스킬
.claude/skills/phase-check.md              ← 워크플로우 스킬
```

---

## 구조

```
ai-setting/
├── init.sh                               # 🚀 초기화 스크립트
├── claude/
│   ├── settings.json                      # hooks 6개 (바로 사용)
│   ├── hooks/
│   │   ├── protect-files.sh               # 민감 파일 편집 차단 (20개 패턴)
│   │   └── block-dangerous-commands.sh    # 위험 명령어 차단 (14개 패턴)
│   ├── agents/
│   │   ├── security-reviewer.md           # 보안 리뷰 (읽기 전용, opus)
│   │   ├── architect-reviewer.md          # 설계 검증 (읽기 전용, opus)
│   │   ├── test-writer.md                 # 테스트 작성 (sonnet)
│   │   └── research.md                    # 기술 리서치 (검색 도구)
│   └── skills/
│       ├── deploy/SKILL.md                # 배포 체크리스트
│       ├── review/SKILL.md                # 코드 리뷰 체크리스트
│       ├── fix-issue/SKILL.md             # 이슈 수정 워크플로우
│       ├── gap-check/SKILL.md             # 빠진 요구사항 탐지
│       └── cross-validate/SKILL.md        # AI 출력물 교차검증
├── codex/
│   └── config.toml                        # Codex CLI 기본 설정
├── templates/
│   ├── CLAUDE.md.template                 # [대괄호]만 채우면 됨
│   ├── AGENTS.md.template                 # [대괄호]만 채우면 됨
│   └── decisions.md.template              # 기술 의사결정 기록
└── README.md
```

---

## 포함된 설정 상세

### Hooks — 자동 실행

| Hook | 시점 | 역할 |
|------|------|------|
| **protect-files.sh** | 파일 편집 전 | .env, lock, .git, 인증키, 빌드산출물 편집 차단 |
| **block-dangerous-commands.sh** | Bash 실행 전 | rm -rf, sudo, force push, DROP TABLE 등 차단 |
| **auto-format** | 파일 편집 후 | Python→ruff, TS/JS→prettier 자동 포맷 |
| **test-check** | 작업 완료 시 | 코드 변경 후 테스트 실행 여부 확인 |
| **notification** | 입력 필요 시 | macOS 데스크톱 알림 |
| **session-reminder** | compact 시 | CLAUDE.md/AGENTS.md 읽기 리마인더 |

### Agents — 서브에이전트

| Agent | 모델 | 권한 | 역할 |
|-------|------|------|------|
| **security-reviewer** | opus | 읽기 + Bash | 보안 취약점 (인젝션, 인증, 시크릿, AI API, 파일 업로드) |
| **architect-reviewer** | opus | 읽기 전용 | 설계 품질 (관심사 분리, 의존성, God 클래스, 네이밍) |
| **test-writer** | sonnet | 쓰기 가능 | 테스트 생성 (pytest, Vitest, happy/edge/error path) |
| **research** | — | 검색 도구 | 기술 조사 (공식 문서 → 웹 검색 → GitHub 사용례) |

### Skills — 슬래시 명령어

| Skill | 역할 |
|-------|------|
| **/deploy** | Pre-deploy 체크 → 배포 → Post-deploy 검증 |
| **/review** | Security / Backend / Frontend / General 체크리스트 |
| **/fix-issue** | gh issue → 실패 테스트 → 수정 → 린트 → PR |
| **/gap-check** | 빠진 요구사항 탐지 (Implicit Requirements + What If 분석) |
| **/cross-validate** | AI 생성 문서/코드 vs 실제 상태 대조 검증 |

### 보호 패턴 (protect-files.sh)

| 분류 | 패턴 |
|------|------|
| 시크릿 | `.env`, `.env.local`, `.env.production`, `.env.development` |
| Git | `.git/` |
| 의존성/빌드 | `node_modules/`, `__pycache__/`, `.venv/`, `dist/`, `build/`, `.next/` |
| Lock 파일 | `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `uv.lock` |
| DB | `*.sqlite`, `*.sqlite3` |
| 인증/키 | `*.pem`, `*.key`, `credentials.json` |

### 위험 명령 차단 (block-dangerous-commands.sh)

```
rm -rf /    rm -rf ~    rm -rf .    sudo
git push --force/--f    git reset --hard
DROP TABLE    DROP DATABASE    TRUNCATE TABLE
chmod 777    mkfs    > /dev/sda    fork bomb
```

---

## CLAUDE.md 템플릿 — 포함된 공통 섹션 (17개)

| 섹션 | 내용 |
|------|------|
| 프로젝트 규칙 | @AGENTS.md 참조 |
| 빌드 & 실행 | [프로젝트별 명령어] |
| 라이브러리 우선 원칙 | 직접 구현 전 라이브러리 확인, 공식 문서 검증 |
| 의존성 관리 | stdlib 우선, 버전 핀, 보안 취약점 확인 |
| Research 원칙 | 새 기술 도입 시 공식 문서 확인 필수 |
| Preflight 원칙 | 분석 → 계획 → 확인 → 실행 |
| 교육용 진행 원칙 | 구조 경계 주석, "왜" 중심, 코드 반복 주석 금지 |
| AI 연동 | 추상 인터페이스 경유 필수 |
| 에러 처리 규칙 | 구체적 예외만 포착, structlog, transient/permanent 구분 |
| 환경변수 규칙 | pydantic-settings, .env만, .env.example 문서화 |
| 안전장치 | 재시도 제한, 비용 가드레일, 롤백 전략 |
| 교차검증 원칙 | AI 출력물 vs 실제 코드/상태 대조 필수 |
| Gap Detection 원칙 | 빠진 요구사항 탐지, What If 분석, 범위 제한 |
| 코드-문서 동기화 | 코드 변경 시 관련 문서 필수 갱신 |
| 용어 혼동 방지 | 동일 용어 다중 맥락 시 구분 명시 |
| 의사결정 기록 | decisions.md에 선택 + 이유 + 대안 기록 |
| 도메인 지식 | [프로젝트별 문서 참조] |

## AGENTS.md 템플릿 — 포함된 공통 규칙

**General Principles** (11개):
TDD, 라이브러리 우선, 관심사 분리, SOLID/DRY/KISS/YAGNI, Fail Fast, 불변성, 보안 기본값, 구조화 로깅, 교육용 주석, 모듈식 설계, Preflight

**Forbidden** (10개):
God 클래스, 비즈니스 로직 위치, 바퀴 재발명, 수동 DDL, 공식 문서 없이 라이브러리, any 타입, except:pass, AI API 직접 호출, 하드코딩 시크릿, 주석 노이즈

---

## 출처 및 검증

- **StoryForge** (.claude/ 설정 원본) + **TaskRelay** (.claude/ 설정 원본)
- **Claude Code 공식 문서** — hooks 규격, permissions 문법, agents/skills 형식
- **Codex CLI 공식 문서** — config.toml 필드 검증
- **커뮤니티** — Trail of Bits 설정, Awesome Claude Code, Claude Code Hooks Mastery
