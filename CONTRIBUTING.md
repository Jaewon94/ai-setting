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
- 공식 문서나 외부 레퍼런스를 보고 판단한 변경은 `docs/research-notes.md` 또는 `docs/decisions.md`에 출처와 확인일을 남깁니다.

## 개발 워크플로

1. 현재 동작과 로드맵 상태를 먼저 확인합니다.
2. 기능 범위를 작게 정하고 관련 파일을 함께 갱신합니다.
3. 임시 디렉토리에서 `init.sh --skip-ai` 기준 스모크 테스트를 합니다.
4. 필요한 경우 `--doctor`, `--diff`, `--reapply`까지 같이 확인합니다.
5. 기능 단위로 커밋합니다.

## 검증 체크리스트

최소 권장 검증:

```bash
# 구문 검사
bash -n init.sh lib/*.sh claude/hooks/*.sh scripts/*.sh bin/ai-setting

# 자동화 테스트
./tests/run_all.sh

# 스모크 테스트
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
- `codex/config*.toml`
  - 프로필별 Codex 설정 템플릿입니다 (standard, minimal, strict, team).
- `init.sh`
  - 옵션 파싱, 모드 분기, 각 모듈 호출만 담당하는 얇은 오케스트레이터입니다 (~100행).

### 조사/근거 기록

- `docs/research-notes.md`
  - 공식 문서, 레퍼런스, 외부 조사 결과의 요약과 출처를 기록합니다.
- `docs/decisions.md`
  - 최종 기술 결정과 관련 조사 항목을 기록합니다.
- ID 형식은 `R-001`, `D-001`처럼 증가시키고 서로 교차 참조합니다.

### lib/ 모듈 구조

init 흐름은 현재 15개 모듈로 분리되어 있습니다. 수정 시 해당 책임 모듈만 건드리면 됩니다.

| 모듈 | 책임 |
|------|------|
| `common.sh` | 색상, 타임스탬프, trim_whitespace, contains_value, tool_enabled, dry_run_note |
| `ai-autofill.sh` | timeout 실행, rule-based placeholder 치환, Claude/Codex autofill fallback |
| `validate.sh` | usage, validate_profile/sync_mode/archetype_hint, get_profile/codex_settings_template |
| `fileops.sh` | run_mkdir_p, run_copy, run_symlink, run_chmod_file |
| `assets.sh` | install_shared_asset, install_shared_executable_asset, install_shared_directory_link |
| `backup.sh` | build_backup_managed_paths, snapshot, perform_backup_all, backup_existing_path |
| `cli.sh` | 서브커맨드 전처리, 옵션 파싱, 모드 조합 검증 |
| `config-detect.sh` | detect_claude_profile, detect_shared_asset_mode, detect_async_test_strategy |
| `deps.sh` | jq 의존성 점검, 자동 설치 제안 |
| `doctor.sh` | doctor_ok/warn/error, run_doctor, run_diff_preview |
| `detect.sh` | detect_project_stack/archetype/context_mode, apply_user_hints |
| `init-flow.sh` | 시작 개요 출력, Step 1~5 실행, 템플릿/요약 출력 |
| `mcp.sh` | add/normalize/recommend MCP presets, write_claude_mcp_config, check_mcp_commands |
| `profile.sh` | copy_claude/cursor/gemini/codex/copilot_assets, cmd_add_tool, merge_claude_settings_template |
| `sync.sh` | parse_manifest_line, detect_sync_conflicts, run_sync_manifest |
| `plugin.sh` | cmd_plugin_list/install/uninstall/check_update/upgrade |

source 순서(init.sh 상단)가 의존 관계를 반영하므로 순서를 바꾸지 마세요.

## 새 기능을 추가할 때

### 새 profile 추가

- `claude/settings.<profile>.json`을 추가합니다.
- `lib/validate.sh`의 `validate_profile`, `get_profile_settings_template`와 doctor/profile summary를 갱신합니다.
- profile-specific 파일이 있으면 생성/백업/재적용 경로를 같이 갱신합니다.
- README와 로드맵의 profile 표를 갱신합니다.

### 새 MCP preset 추가

- `lib/mcp.sh`의 `add_mcp_preset`, `append_codex_mcp_preset`, `write_claude_mcp_config`를 갱신합니다.
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

## Git 워크플로

ai-setting 저장소 자체는 단독 관리자 프로젝트이므로 **trunk-based development** (main 직접 커밋)을 사용합니다.
이는 strict/team 프로필이 권장하는 feature branch + PR 워크플로와 의도적으로 다릅니다.
strict/team 프로필은 다수 기여자가 있는 협업 프로젝트를 위한 설정입니다.

## 커밋 규칙

- Conventional Commits를 사용합니다.
- 커밋 제목은 기본적으로 한글로 작성합니다.
- 형식은 `분류: 설명`을 권장합니다.
- 바디가 필요하면 중요한 내용만 1~3줄로 짧게 요약합니다.
- 커밋 메시지에 어떤 AI를 사용했는지, AI가 작성했다는 문구는 넣지 않습니다.
- 이 규칙은 `ai-setting` 저장소 자체에 우선 적용합니다. 생성 대상 프로젝트에는 기본값으로 강제하지 않습니다.
- 권장 예시:
  - `기능: 멀티 도구 부트스트랩 지원 추가`
  - `기능: strict 및 team 프로필 확장`
  - `문서: 로드맵 완료 상태 정리`
  - `수정: reapply 시 관리 파일 보존`

## 문서 규칙

- README는 "사용하는 사람" 관점으로 씁니다.
- `docs/roadmap.md`는 "왜 / 무엇 / 어디까지 끝났는지"가 보여야 합니다.
- 새 기능을 넣었으면 완료 체크와 현재 상태를 같이 갱신합니다.
