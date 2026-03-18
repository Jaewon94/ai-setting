# Contributing

## 목표

이 저장소는 새 프로젝트에 AI 코딩 도구 설정을 일관되게 부트스트랩하는 것을 목표로 합니다.
기여 시에는 "기능 추가"보다 아래 3가지를 우선합니다.

- 재현성: 같은 입력이면 같은 결과가 나와야 함
- 안전성: 반복 실행과 기존 사용자 수정에 최대한 안전해야 함
- 문서 일치: `README.md`, `docs/roadmap.md`, 실제 동작이 어긋나지 않아야 함

## 기본 원칙

- 기능은 작은 단위로 나누어 구현하고 커밋합니다.
- 새 설정 파일을 추가하면 `doctor`, `diff`, `backup-all`, `reapply` 영향도 함께 검토합니다.
- 사용자 프로젝트 안에서 생성되는 파일은 가능한 한 managed path를 명확히 합니다.
- project-specific 문서와 shared template를 구분합니다.
- 기존 동작을 바꾸면 README 예시와 로드맵 현재 상태도 같이 갱신합니다.

## 개발 워크플로

1. 현재 동작과 로드맵 상태를 먼저 확인합니다.
2. 기능 범위를 작게 정하고 관련 파일을 함께 갱신합니다.
3. 임시 디렉토리에서 `init.sh --skip-ai` 기준 스모크 테스트를 합니다.
4. 필요한 경우 `--doctor`, `--diff`, `--reapply`까지 같이 확인합니다.
5. 기능 단위로 커밋합니다.

## 검증 체크리스트

최소 권장 검증:

```bash
bash -n init.sh claude/hooks/*.sh

tmpdir=$(mktemp -d)
./init.sh --skip-ai "$tmpdir"
./init.sh --doctor "$tmpdir"
./init.sh --diff "$(mktemp -d)"
```

프로필/옵션을 건드렸다면 추가로 확인:

```bash
./init.sh --skip-ai --profile minimal "$(mktemp -d)"
./init.sh --skip-ai --profile strict "$(mktemp -d)"
./init.sh --skip-ai --profile team "$(mktemp -d)"
./init.sh --skip-ai --reapply "$(mktemp -d)"
```

동기화/플러그인을 건드렸다면 추가로 확인:

```bash
# link-dir
./init.sh --skip-ai --link-dir "$(mktemp -d)"

# sync manifest with per-project options
tmpdir=$(mktemp -d) && echo "$tmpdir profile=strict" > /tmp/test.manifest
./init.sh sync --skip-ai --dry-run /tmp/test.manifest

# sync conflict detection
./init.sh sync --skip-ai --sync-conflict skip /tmp/test.manifest

# plugin lifecycle
tmpdir=$(mktemp -d) && ./init.sh --skip-ai "$tmpdir"
./init.sh plugin list
./init.sh plugin install ai-setting-strict "$tmpdir"
./init.sh plugin check-update "$tmpdir"
./init.sh plugin uninstall ai-setting-strict "$tmpdir"
```

## 어디를 수정하나

### Claude Code 관련

- `claude/settings*.json`
  - profile별 hook 구성을 정의합니다.
- `claude/hooks/*.sh`
  - 편집/명령 보호 로직입니다.
- `claude/agents/*`
  - 기본 서브에이전트 정의입니다.
- `claude/skills/*`
  - slash command형 재사용 워크플로입니다.

### 멀티 도구 관련

- `cursor/rules/*.mdc`
  - Cursor rule 템플릿입니다.
- `gemini/settings.json`
  - Gemini CLI workspace 설정입니다.
- `templates/GEMINI.md.template`
  - Gemini용 프로젝트 컨텍스트 템플릿입니다.
- `templates/copilot-instructions.md.template`
  - GitHub Copilot 저장소 지침 템플릿입니다.

### 플러그인 관련

- `plugins/ai-setting-core/`
  - Core 플러그인 (hooks, agents, skills, MCP)
- `plugins/ai-setting-strict/`
  - Strict 전용 플러그인 (branch protection hook)
- `plugins/ai-setting-team/`
  - Team 전용 플러그인 (webhook notification hook)
- `.claude-plugin/marketplace.json`
  - 플러그인 카탈로그 (새 플러그인 추가 시 엔트리 추가)

### 공통 템플릿 / 부트스트랩

- `templates/*.template`
  - 프로젝트에 생성되는 문서 템플릿입니다.
- `codex/config.toml`
  - Codex 기본 템플릿입니다.
- `init.sh`
  - 옵션 파싱, 파일 생성, backup/diff/doctor, sync, plugin, AI 자동 채우기 흐름의 중심입니다.

## 새 기능을 추가할 때

### 새 profile 추가

- `claude/settings.<profile>.json`을 추가합니다.
- `init.sh`의 `validate_profile`, `get_profile_settings_template`, doctor/profile summary를 갱신합니다.
- profile-specific 파일이 있으면 생성/백업/재적용 경로를 같이 갱신합니다.
- README와 로드맵의 profile 표를 갱신합니다.

### 새 MCP preset 추가

- `init.sh`의 `add_mcp_preset`, `append_codex_mcp_preset`, `write_claude_mcp_config`를 갱신합니다.
- auto recommendation이 필요하면 `calculate_recommended_mcp_presets`도 수정합니다.
- README와 로드맵에서 기본/선택/제외 여부를 명시합니다.

### 새 도구 지원 추가

- 가능한 한 source-of-truth 문서를 재사용하고 중복 템플릿은 줄입니다.
- 생성 파일 위치를 명확히 하고 managed path 목록에 반영합니다.
- `doctor`, `diff`, `backup-all`, `reapply`를 같이 갱신합니다.

### 새 플러그인 추가

- `plugins/<name>/` 디렉토리를 만듭니다.
- `.claude-plugin/plugin.json`, `hooks/hooks.json`, 필요한 `scripts/`를 추가합니다.
- `.claude-plugin/marketplace.json`에 엔트리를 추가합니다.
- `npm run plugin:validate`로 검증합니다.

### 새 언어 / archetype 지원 추가

- `detect_project_stack`, `detect_project_archetype`, `detect_project_context_mode`를 함께 봅니다.
- 자동 감지 신호와 사용자 힌트가 충돌할 때는 사용자 힌트를 우선합니다.
- README와 로드맵의 지원 범위를 같이 업데이트합니다.

## 커밋 규칙

- Conventional Commits를 사용합니다.
- 권장 예시:
  - `feat: add multi-tool bootstrap support`
  - `feat: expand strict and team profiles`
  - `docs: clarify roadmap completion status`
  - `fix: preserve managed files during reapply`

## 문서 규칙

- README는 "사용하는 사람" 관점으로 씁니다.
- `docs/roadmap.md`는 "왜 / 무엇 / 어디까지 끝났는지"가 보여야 합니다.
- 새 기능을 넣었으면 완료 체크와 현재 상태를 같이 갱신합니다.
