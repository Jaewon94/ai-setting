#!/bin/bash
# init.sh — 새 프로젝트에 AI 도구 설정을 자동 적용
# 사용법: /path/to/ai-setting/init.sh [프로젝트 경로]
#
# 1단계: 공통 설정 파일 복사 (hooks, agents, skills, codex)
# 2단계: 프로젝트 로컬 MCP preset 생성
# 3단계: CLAUDE.md / AGENTS.md 템플릿 복사
# 4단계: AI로 템플릿의 [대괄호] 부분 자동 채우기
#         Claude Code → Codex → 수동 안내 (fallback 체인)

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
RUN_TIMESTAMP="$(date +%Y%m%d%H%M%S)"
USAGE_NAME="${AI_SETTING_USAGE_NAME:-init.sh}"

usage() {
  cat <<EOF
사용법:
  $USAGE_NAME [옵션] [프로젝트 경로]
  $USAGE_NAME update [옵션] [프로젝트 경로]

옵션:
  --profile PROFILE        Claude Code 프로필 지정 (standard|minimal|strict|team)
  --link                   공유 가능한 설정 자산을 복사 대신 심링크로 연결
  --update                 AI 자동 채우기 없이 공유 자산/MCP를 최신 상태로 갱신
  --doctor                 현재 프로젝트 설정 상태 진단
  --dry-run                실제 변경 없이 예정 작업만 출력
  --diff                   실제 변경 없이 관리 대상 파일 diff 출력
  --backup-all             적용 전 관리 대상 전체 스냅샷 백업
  --reapply                CLAUDE.md/AGENTS.md를 다시 생성하고 AI 채우기 재실행
  --auto-mcp               감지된 archetype 기반 추천 MCP preset 자동 적용
  --project-name NAME      프로젝트 이름 힌트 제공
  --archetype TYPE         프로젝트 archetype 힌트 제공
  --stack NAME             주 스택 힌트 제공
  --skip-ai                AI 자동 채우기 건너뛰기
  --mcp-preset PRESETS     프로젝트 로컬 MCP preset 지정 (예: core,web)
  --no-mcp                 프로젝트 로컬 MCP 생성 건너뛰기
  -h, --help               도움말 출력

MCP preset:
  core   sequential-thinking, serena, upstash-context-7-mcp
  web    playwright (core와 함께 사용 권장)
  infra  docker (core와 함께 사용 권장)

Archetype:
  frontend-web | backend-api | cli-tool | worker-batch
  data-automation | library-sdk | infra-iac | general-app
EOF
}

validate_profile() {
  local profile="$1"

  case "$profile" in
    standard|minimal|strict|team)
      ;;
    *)
      echo -e "${RED}오류: 알 수 없는 profile '$profile'${NC}" >&2
      usage
      exit 1
      ;;
  esac
}

get_profile_settings_template() {
  local profile="$1"

  case "$profile" in
    standard)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.json"
      ;;
    minimal)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.minimal.json"
      ;;
    strict)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.strict.json"
      ;;
    team)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.team.json"
      ;;
  esac
}

detect_claude_profile() {
  local target="$1"
  local settings_path="$target/.claude/settings.json"
  local standard_template
  local minimal_template
  local strict_template
  local team_template

  standard_template="$SCRIPT_DIR/claude/settings.json"
  minimal_template="$SCRIPT_DIR/claude/settings.minimal.json"
  strict_template="$SCRIPT_DIR/claude/settings.strict.json"
  team_template="$SCRIPT_DIR/claude/settings.team.json"

  if [ ! -f "$settings_path" ]; then
    DETECTED_CLAUDE_PROFILE="unknown"
    return
  fi

  if cmp -s "$settings_path" "$minimal_template"; then
    DETECTED_CLAUDE_PROFILE="minimal"
  elif cmp -s "$settings_path" "$standard_template"; then
    DETECTED_CLAUDE_PROFILE="standard"
  elif cmp -s "$settings_path" "$strict_template"; then
    DETECTED_CLAUDE_PROFILE="strict"
  elif cmp -s "$settings_path" "$team_template"; then
    DETECTED_CLAUDE_PROFILE="team"
  else
    DETECTED_CLAUDE_PROFILE="custom"
  fi
}

detect_shared_asset_mode() {
  local target="$1"
  local symlink_count=0
  local regular_count=0
  local path
  local paths=(
    "$target/.claude/settings.json"
    "$target/.cursor/rules/ai-setting.mdc"
    "$target/.gemini/settings.json"
  )

  for path in "${paths[@]}"; do
    if [ -L "$path" ]; then
      symlink_count=$((symlink_count + 1))
    elif [ -e "$path" ]; then
      regular_count=$((regular_count + 1))
    fi
  done

  if [ "$symlink_count" -gt 0 ] && [ "$regular_count" -gt 0 ]; then
    DETECTED_SHARED_ASSET_MODE="mixed"
  elif [ "$symlink_count" -gt 0 ]; then
    DETECTED_SHARED_ASSET_MODE="symlink"
  else
    DETECTED_SHARED_ASSET_MODE="copy"
  fi
}

doctor_ok() {
  DOCTOR_OK_COUNT=$((DOCTOR_OK_COUNT + 1))
  echo -e "${GREEN}[OK]${NC} $1"
}

doctor_warn() {
  DOCTOR_WARN_COUNT=$((DOCTOR_WARN_COUNT + 1))
  echo -e "${YELLOW}[WARN]${NC} $1"
}

doctor_error() {
  DOCTOR_ERROR_COUNT=$((DOCTOR_ERROR_COUNT + 1))
  echo -e "${RED}[ERROR]${NC} $1"
}

run_doctor() {
  local target="$1"
  local placeholder_count
  local skill_placeholder_count

  DOCTOR_OK_COUNT=0
  DOCTOR_WARN_COUNT=0
  DOCTOR_ERROR_COUNT=0
  detect_claude_profile "$target"
  detect_shared_asset_mode "$target"

  echo -e "${CYAN}━━━ AI Setting Doctor ━━━${NC}"
  echo -e "대상: ${target}"
  echo -e "Claude 프로필: ${DETECTED_CLAUDE_PROFILE}"
  echo -e "공유 자산 모드: ${DETECTED_SHARED_ASSET_MODE}"
  echo -e "해석 모드: ${PROJECT_CONTEXT_MODE}"
  echo -e "프로젝트 유형: ${PROJECT_ARCHETYPE}"
  echo -e "주 스택: ${PROJECT_STACK}"
  echo ""

  if command -v jq &> /dev/null; then
    doctor_ok "jq 설치됨"
  else
    doctor_warn "jq 미설치 — hooks JSON 파싱 및 .mcp.json 검증이 제한됨"
  fi

  if command -v npx &> /dev/null; then
    doctor_ok "npx 설치됨"
  else
    doctor_warn "npx 미설치 — sequential-thinking/context7/playwright/docker MCP 실행 불가"
  fi

  if command -v uvx &> /dev/null; then
    doctor_ok "uvx 설치됨"
  else
    doctor_warn "uvx 미설치 — serena MCP 실행 불가"
  fi

  if command -v claude &> /dev/null; then
    doctor_ok "claude 설치됨"
  else
    doctor_warn "claude 미설치 — Claude Code 자동 채우기 사용 불가"
  fi

  if command -v codex &> /dev/null; then
    doctor_ok "codex 설치됨"
  else
    doctor_warn "codex 미설치 — Codex fallback 자동 채우기 사용 불가"
  fi

  if command -v gemini &> /dev/null; then
    doctor_ok "gemini 설치됨"
  else
    doctor_warn "gemini 미설치 — Gemini CLI는 설정 파일만 생성되고 CLI 실행은 불가할 수 있음"
  fi

  if [ -f "$target/.claude/settings.json" ]; then
    doctor_ok ".claude/settings.json 존재"
    if [ "$DETECTED_CLAUDE_PROFILE" = "custom" ]; then
      doctor_warn ".claude/settings.json이 bundled profile 템플릿과 다름"
    else
      doctor_ok "Claude 프로필 감지: ${DETECTED_CLAUDE_PROFILE}"
    fi
  else
    doctor_error ".claude/settings.json 없음"
  fi

  if [ -f "$target/.cursor/rules/ai-setting.mdc" ]; then
    doctor_ok ".cursor/rules/ai-setting.mdc 존재"
  else
    doctor_warn ".cursor/rules/ai-setting.mdc 없음 — Cursor 지원 파일이 아직 생성되지 않았을 수 있음"
  fi

  if [ -f "$target/.gemini/settings.json" ]; then
    doctor_ok ".gemini/settings.json 존재"
  else
    doctor_warn ".gemini/settings.json 없음 — Gemini CLI 지원 파일이 아직 생성되지 않았을 수 있음"
  fi

  if [ -f "$target/GEMINI.md" ]; then
    doctor_ok "GEMINI.md 존재"
  else
    doctor_warn "GEMINI.md 없음 — Gemini CLI 프로젝트 컨텍스트가 아직 생성되지 않았을 수 있음"
  fi

  if [ -f "$target/.github/copilot-instructions.md" ]; then
    doctor_ok ".github/copilot-instructions.md 존재"
  else
    doctor_warn ".github/copilot-instructions.md 없음 — GitHub Copilot 지원 파일이 아직 생성되지 않았을 수 있음"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "team" ]; then
    if [ -f "$target/.github/pull_request_template.md" ]; then
      doctor_ok ".github/pull_request_template.md 존재"
    else
      doctor_error ".github/pull_request_template.md 없음"
    fi
  fi

  if [ -x "$target/.claude/hooks/protect-files.sh" ]; then
    doctor_ok ".claude/hooks/protect-files.sh 실행 가능"
  else
    doctor_error ".claude/hooks/protect-files.sh 없음 또는 실행 권한 없음"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "minimal 프로필 — block-dangerous-commands hook 비활성"
  elif [ -x "$target/.claude/hooks/block-dangerous-commands.sh" ]; then
    doctor_ok ".claude/hooks/block-dangerous-commands.sh 실행 가능"
  else
    doctor_error ".claude/hooks/block-dangerous-commands.sh 없음 또는 실행 권한 없음"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "strict" ] || [ "$DETECTED_CLAUDE_PROFILE" = "team" ]; then
    if [ -x "$target/.claude/hooks/protect-main-branch.sh" ]; then
      doctor_ok ".claude/hooks/protect-main-branch.sh 실행 가능"
    else
      doctor_error ".claude/hooks/protect-main-branch.sh 없음 또는 실행 권한 없음"
    fi
  fi

  if [ -f "$target/.codex/config.toml" ]; then
    doctor_ok ".codex/config.toml 존재"
  else
    doctor_error ".codex/config.toml 없음"
  fi

  if [ -f "$target/.mcp.json" ]; then
    if command -v jq &> /dev/null && jq empty "$target/.mcp.json" >/dev/null 2>&1; then
      doctor_ok ".mcp.json 유효한 JSON"
    elif command -v jq &> /dev/null; then
      doctor_error ".mcp.json JSON 형식이 올바르지 않음"
    else
      doctor_warn ".mcp.json 존재하지만 jq가 없어 형식 검증은 건너뜀"
    fi
  else
    doctor_warn ".mcp.json 없음 — --no-mcp로 초기화했거나 설정이 누락되었을 수 있음"
  fi

  if [ -f "$target/CLAUDE.md" ]; then
    doctor_ok "CLAUDE.md 존재"
  else
    doctor_error "CLAUDE.md 없음"
  fi

  if [ -f "$target/AGENTS.md" ]; then
    doctor_ok "AGENTS.md 존재"
  else
    doctor_error "AGENTS.md 없음"
  fi

  if [ -f "$target/docs/decisions.md" ]; then
    doctor_ok "docs/decisions.md 존재"
  else
    doctor_warn "docs/decisions.md 없음"
  fi

  if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ]; then
    doctor_ok "blank-start 모드 — 템플릿/skill 플레이스홀더 잔존은 현재 정상"
  else
    placeholder_count=0
    if [ -f "$target/CLAUDE.md" ]; then
      placeholder_count=$((placeholder_count + $(rg -o '\[(프로젝트명|프로젝트에 맞게 수정|프로젝트별 문서 참조 추가: @docs/architecture.md 등)\]' "$target/CLAUDE.md" 2>/dev/null | wc -l | tr -d ' ')))
    fi
    if [ -f "$target/AGENTS.md" ]; then
      placeholder_count=$((placeholder_count + $(rg -o '\[(프로젝트명|프로젝트 한 줄 설명|아키텍처 다이어그램|백엔드 스택|프론트엔드 스택|프로젝트별 테스트 명령어|프로젝트 디렉토리 구조|프로젝트별 도메인 개념)\]' "$target/AGENTS.md" 2>/dev/null | wc -l | tr -d ' ')))
    fi
    if [ -f "$target/GEMINI.md" ]; then
      placeholder_count=$((placeholder_count + $(rg -o '\[(프로젝트명|Gemini CLI에서 특히 강조할 프로젝트 규칙)\]' "$target/GEMINI.md" 2>/dev/null | wc -l | tr -d ' ')))
    fi
    if [ -f "$target/.github/copilot-instructions.md" ]; then
      placeholder_count=$((placeholder_count + $(rg -o '\[(프로젝트 한 줄 설명|프로젝트별 build 또는 run 명령|프로젝트별 테스트 명령어|프로젝트별 린트 또는 포맷 명령|프로젝트별 추가 검증 또는 협업 규칙)\]' "$target/.github/copilot-instructions.md" 2>/dev/null | wc -l | tr -d ' ')))
    fi
    if [ "$placeholder_count" -eq 0 ]; then
      doctor_ok "문서 템플릿 플레이스홀더 없음"
    else
      doctor_warn "CLAUDE.md / AGENTS.md / GEMINI.md / copilot instructions에 템플릿 플레이스홀더가 남아 있음"
    fi

    if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
      doctor_ok "minimal 프로필 — managed skills 미사용"
    else
      skill_placeholder_count=$(rg -o '\{\{[A-Z0-9_]+\}\}' "$target/.claude/skills" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$skill_placeholder_count" -eq 0 ]; then
        doctor_ok ".claude/skills 플레이스홀더 없음"
      else
        doctor_warn ".claude/skills에 치환되지 않은 {{PLACEHOLDER}}가 남아 있음"
      fi
    fi
  fi

  echo ""
  echo -e "${CYAN}━━━ Doctor Summary ━━━${NC}"
  echo "  OK: ${DOCTOR_OK_COUNT}"
  echo "  WARN: ${DOCTOR_WARN_COUNT}"
  echo "  ERROR: ${DOCTOR_ERROR_COUNT}"

  if [ "$DOCTOR_ERROR_COUNT" -gt 0 ]; then
    return 1
  fi

  return 0
}

run_diff_preview() {
  local target="$1"
  local staging_dir
  local diff_found=false
  local managed_path
  local left_path
  local right_path
  local diff_output
  local status
  local internal_log
  local -a managed_paths
  local -a internal_args

  managed_paths=(".claude" ".codex/config.toml" "CLAUDE.md" "AGENTS.md" "docs/decisions.md")
  managed_paths+=(".cursor/rules/ai-setting.mdc" ".gemini/settings.json" "GEMINI.md" ".github/copilot-instructions.md" ".github/pull_request_template.md")
  if [ "$MCP_ENABLED" = true ]; then
    managed_paths+=(".mcp.json")
  fi

  staging_dir="$(mktemp -d)"
  internal_log="$(mktemp)"

  cp -R "$target/." "$staging_dir/" 2>/dev/null || true

  internal_args=("--skip-ai")
  internal_args+=("--profile" "$CLAUDE_PROFILE")
  if [ "$LINK_MODE" = true ]; then
    internal_args+=("--link")
  fi
  if [ "$MCP_ENABLED" = false ]; then
    internal_args+=("--no-mcp")
  else
    internal_args+=("--mcp-preset" "$MCP_PRESET_LABEL")
  fi

  if [ -n "$USER_PROJECT_NAME_HINT" ]; then
    internal_args+=("--project-name" "$USER_PROJECT_NAME_HINT")
  fi
  if [ -n "$USER_ARCHETYPE_HINT" ]; then
    internal_args+=("--archetype" "$USER_ARCHETYPE_HINT")
  fi
  if [ -n "$USER_STACK_HINT" ]; then
    internal_args+=("--stack" "$USER_STACK_HINT")
  fi
  internal_args+=("$staging_dir")

  if ! "$SCRIPT_DIR/init.sh" "${internal_args[@]}" >"$internal_log" 2>&1; then
    echo -e "${RED}diff preview 생성 실패${NC}" >&2
    cat "$internal_log" >&2
    rm -rf "$staging_dir"
    rm -f "$internal_log"
    return 1
  fi

  echo -e "${CYAN}━━━ AI Setting Diff ━━━${NC}"
  echo -e "대상: ${target}"
  echo -e "해석 모드: ${PROJECT_CONTEXT_MODE}"
  echo -e "프로젝트 유형: ${PROJECT_ARCHETYPE}"
  echo -e "주 스택: ${PROJECT_STACK}"
  echo ""

  for managed_path in "${managed_paths[@]}"; do
    left_path="$target/$managed_path"
    right_path="$staging_dir/$managed_path"

    if [ ! -e "$left_path" ] && [ ! -e "$right_path" ]; then
      continue
    fi

    set +e
    diff_output="$(diff -ruN "$left_path" "$right_path" 2>&1)"
    status=$?
    set -e

    if [ "$status" -eq 0 ]; then
      continue
    fi

    if [ "$status" -ne 1 ]; then
      echo -e "${RED}diff 출력 실패: ${managed_path}${NC}" >&2
      echo "$diff_output" >&2
      rm -rf "$staging_dir"
      rm -f "$internal_log"
      return 1
    fi

    diff_found=true
    echo ""
    echo "### ${managed_path}"
    echo "$diff_output" | sed "s|$target/|current/|g; s|$target$|current|g; s|$staging_dir/|preview/|g; s|$staging_dir$|preview|g"
  done

  if [ "$diff_found" = false ]; then
    echo "변경될 관리 대상 파일이 없습니다."
  fi

  echo ""
  echo "참고: diff preview는 AI 자동 채우기 결과를 포함하지 않습니다."

  rm -rf "$staging_dir"
  rm -f "$internal_log"
  return 0
}

build_backup_managed_paths() {
  BACKUP_MANAGED_PATHS=(
    ".claude"
    ".cursor/rules/ai-setting.mdc"
    ".gemini/settings.json"
    ".codex/config.toml"
    ".mcp.json"
    "CLAUDE.md"
    "AGENTS.md"
    "GEMINI.md"
    ".github/copilot-instructions.md"
    ".github/pull_request_template.md"
    "docs/decisions.md"
  )
}

snapshot_managed_path() {
  local rel_path="$1"
  local source_path="$TARGET/$rel_path"
  local backup_path="$BACKUP_SNAPSHOT_DIR/$rel_path"

  if [ ! -e "$source_path" ]; then
    return
  fi

  BACKUP_ALL_CREATED=true

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "backup-all 스냅샷: ${source_path} -> ${backup_path}"
    return
  fi

  mkdir -p "$(dirname "$backup_path")"
  if [ -d "$source_path" ]; then
    cp -R "$source_path" "$backup_path"
  else
    cp "$source_path" "$backup_path"
  fi
}

perform_backup_all() {
  local rel_path

  build_backup_managed_paths
  BACKUP_ALL_CREATED=false
  BACKUP_SNAPSHOT_DIR="$TARGET/.ai-setting.backup.$RUN_TIMESTAMP"

  echo -e "${CYAN}backup-all:${NC} 관리 대상 전체 스냅샷 생성"
  echo "  📦 경로: ${BACKUP_SNAPSHOT_DIR}"

  for rel_path in "${BACKUP_MANAGED_PATHS[@]}"; do
    snapshot_managed_path "$rel_path"
  done

  if [ "$BACKUP_ALL_CREATED" = true ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  ✅ backup-all 스냅샷 생성 예정"
    else
      echo "  ✅ backup-all 스냅샷 생성됨"
    fi
  else
    echo -e "  ${YELLOW}관리 대상 기존 파일이 없어 백업할 내용이 없습니다${NC}"
  fi

  echo ""
}

dry_run_note() {
  echo -e "  ${CYAN}[dry-run]${NC} $1"
}

resolve_copy_destination() {
  local src="$1"
  local dst="$2"

  if [ -d "$dst" ] || [[ "$dst" == */ ]]; then
    printf '%s%s\n' "$dst" "$(basename "$src")"
  else
    printf '%s\n' "$dst"
  fi
}

run_mkdir_p() {
  local path="$1"

  if [ "$DRY_RUN" = true ]; then
    if [ -d "$path" ]; then
      dry_run_note "디렉토리 유지: ${path}"
    else
      dry_run_note "디렉토리 생성: ${path}"
    fi
  else
    mkdir -p "$path"
  fi
}

run_remove_path() {
  local path="$1"

  if [ ! -e "$path" ]; then
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "관리 경로 정리: ${path}"
  else
    rm -rf "$path"
  fi
}

run_copy() {
  local src="$1"
  local dst="$2"
  local final_path

  final_path="$(resolve_copy_destination "$src" "$dst")"

  if [ "$DRY_RUN" = true ]; then
    if [ -e "$final_path" ]; then
      dry_run_note "파일 덮어쓰기: ${final_path}"
    else
      dry_run_note "파일 생성: ${final_path}"
    fi
  else
    cp "$src" "$dst"
  fi
}

run_symlink() {
  local src="$1"
  local dst="$2"
  local final_path

  final_path="$(resolve_copy_destination "$src" "$dst")"

  if [ "$DRY_RUN" = true ]; then
    if [ -L "$final_path" ]; then
      dry_run_note "심링크 갱신: ${final_path} -> ${src}"
    else
      dry_run_note "심링크 생성: ${final_path} -> ${src}"
    fi
    return
  fi

  mkdir -p "$(dirname "$final_path")"
  ln -sfn "$src" "$final_path"
}

install_shared_asset() {
  local src="$1"
  local dst="$2"

  if [ "$LINK_MODE" = true ]; then
    run_symlink "$src" "$dst"
  else
    run_copy "$src" "$dst"
  fi
}

install_shared_executable_asset() {
  local src="$1"
  local dst="$2"

  if [ "$LINK_MODE" = true ]; then
    run_symlink "$src" "$dst"
  else
    run_copy "$src" "$dst"
    run_chmod_file "$(resolve_copy_destination "$src" "$dst")"
  fi
}

run_chmod_file() {
  local path="$1"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "권한 변경: chmod +x ${path}"
  else
    chmod +x "$path"
  fi
}

contains_value() {
  local needle="$1"
  shift
  local value
  for value in "$@"; do
    if [ "$value" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

add_mcp_preset() {
  local preset="$1"
  case "$preset" in
    core|web|infra)
      ;;
    *)
      echo -e "${RED}오류: 알 수 없는 MCP preset '$preset'${NC}" >&2
      usage
      exit 1
      ;;
  esac

  if ! contains_value "$preset" "${MCP_PRESETS[@]}"; then
    MCP_PRESETS+=("$preset")
  fi
}

normalize_mcp_presets() {
  if [ "$MCP_ENABLED" = false ]; then
    MCP_PRESETS=()
    return
  fi

  if [ "${#MCP_PRESETS[@]}" -eq 0 ]; then
    MCP_PRESETS=("core")
    return
  fi

  if ! contains_value "core" "${MCP_PRESETS[@]}"; then
    MCP_PRESETS=("core" "${MCP_PRESETS[@]}")
  fi
}

add_recommended_mcp_preset() {
  local preset="$1"

  if ! contains_value "$preset" "${RECOMMENDED_MCP_PRESETS[@]}"; then
    RECOMMENDED_MCP_PRESETS+=("$preset")
  fi
}

calculate_recommended_mcp_presets() {
  RECOMMENDED_MCP_PRESETS=("core")

  case "$PROJECT_ARCHETYPE" in
    frontend-web)
      add_recommended_mcp_preset "web"
      ;;
    infra-iac)
      add_recommended_mcp_preset "infra"
      ;;
    backend-api|worker-batch|data-automation)
      if [ "$OPS_SIGNAL_COUNT" -ge 1 ]; then
        add_recommended_mcp_preset "infra"
      fi
      ;;
  esac

  RECOMMENDED_MCP_PRESET_LABEL="$(IFS=,; echo "${RECOMMENDED_MCP_PRESETS[*]}")"
}

apply_auto_mcp_presets() {
  local preset

  if [ "$AUTO_MCP" = true ] && [ "$MCP_ENABLED" = true ] && [ "$USER_MCP_PRESET_SPECIFIED" = false ]; then
    for preset in "${RECOMMENDED_MCP_PRESETS[@]}"; do
      add_mcp_preset "$preset"
    done
    AUTO_MCP_APPLIED=true
  else
    AUTO_MCP_APPLIED=false
  fi

  normalize_mcp_presets
}

cleanup_empty_parent_dir() {
  local path="$1"

  if [ "$DRY_RUN" = true ]; then
    return
  fi

  if [ -d "$path" ]; then
    rmdir "$path" 2>/dev/null || true
  fi
}

cleanup_managed_claude_assets() {
  local managed_file
  local managed_dir
  local managed_files=(
    "$TARGET/.claude/settings.json"
    "$TARGET/.claude/hooks/protect-files.sh"
    "$TARGET/.claude/hooks/block-dangerous-commands.sh"
    "$TARGET/.claude/hooks/protect-main-branch.sh"
    "$TARGET/.claude/agents/security-reviewer.md"
    "$TARGET/.claude/agents/architect-reviewer.md"
    "$TARGET/.claude/agents/test-writer.md"
    "$TARGET/.claude/agents/research.md"
    "$TARGET/.claude/skills/deploy/SKILL.md"
    "$TARGET/.claude/skills/review/SKILL.md"
    "$TARGET/.claude/skills/fix-issue/SKILL.md"
    "$TARGET/.claude/skills/gap-check/SKILL.md"
    "$TARGET/.claude/skills/cross-validate/SKILL.md"
  )
  local managed_dirs=(
    "$TARGET/.claude/agents"
    "$TARGET/.claude/skills/deploy"
    "$TARGET/.claude/skills/review"
    "$TARGET/.claude/skills/fix-issue"
    "$TARGET/.claude/skills/gap-check"
    "$TARGET/.claude/skills/cross-validate"
    "$TARGET/.claude/skills"
    "$TARGET/.claude/hooks"
  )

  for managed_file in "${managed_files[@]}"; do
    run_remove_path "$managed_file"
  done

  for managed_dir in "${managed_dirs[@]}"; do
    cleanup_empty_parent_dir "$managed_dir"
  done
}

copy_claude_profile_assets() {
  local settings_template

  settings_template="$(get_profile_settings_template "$CLAUDE_PROFILE")"

  run_mkdir_p "$TARGET/.claude/hooks"
  install_shared_asset "$settings_template" "$TARGET/.claude/settings.json"
  install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/protect-files.sh" "$TARGET/.claude/hooks/protect-files.sh"

  if [ "$CLAUDE_PROFILE" != "minimal" ]; then
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/block-dangerous-commands.sh" "$TARGET/.claude/hooks/block-dangerous-commands.sh"
  fi

  if [ "$CLAUDE_PROFILE" = "strict" ] || [ "$CLAUDE_PROFILE" = "team" ]; then
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/protect-main-branch.sh" "$TARGET/.claude/hooks/protect-main-branch.sh"
  fi

  if [ "$CLAUDE_PROFILE" != "minimal" ]; then
    run_mkdir_p "$TARGET/.claude/agents"
    install_shared_asset "$SCRIPT_DIR/claude/agents/security-reviewer.md" "$TARGET/.claude/agents/"
    install_shared_asset "$SCRIPT_DIR/claude/agents/architect-reviewer.md" "$TARGET/.claude/agents/"
    install_shared_asset "$SCRIPT_DIR/claude/agents/test-writer.md" "$TARGET/.claude/agents/"
    install_shared_asset "$SCRIPT_DIR/claude/agents/research.md" "$TARGET/.claude/agents/"

    run_mkdir_p "$TARGET/.claude/skills/deploy"
    run_mkdir_p "$TARGET/.claude/skills/review"
    run_mkdir_p "$TARGET/.claude/skills/fix-issue"
    run_mkdir_p "$TARGET/.claude/skills/gap-check"
    run_mkdir_p "$TARGET/.claude/skills/cross-validate"
    install_shared_asset "$SCRIPT_DIR/claude/skills/deploy/SKILL.md" "$TARGET/.claude/skills/deploy/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/review/SKILL.md" "$TARGET/.claude/skills/review/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/fix-issue/SKILL.md" "$TARGET/.claude/skills/fix-issue/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/gap-check/SKILL.md" "$TARGET/.claude/skills/gap-check/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/cross-validate/SKILL.md" "$TARGET/.claude/skills/cross-validate/"
  fi
}

copy_cursor_assets() {
  run_mkdir_p "$TARGET/.cursor/rules"
  if [ -f "$TARGET/.cursor/rules/ai-setting.mdc" ]; then
    backup_existing_path "$TARGET/.cursor/rules/ai-setting.mdc" ".cursor/rules/ai-setting.mdc"
  fi
  install_shared_asset "$SCRIPT_DIR/cursor/rules/ai-setting.mdc" "$TARGET/.cursor/rules/ai-setting.mdc"
}

copy_gemini_assets() {
  run_mkdir_p "$TARGET/.gemini"
  if [ -f "$TARGET/.gemini/settings.json" ]; then
    backup_existing_path "$TARGET/.gemini/settings.json" ".gemini/settings.json"
  fi
  install_shared_asset "$SCRIPT_DIR/gemini/settings.json" "$TARGET/.gemini/settings.json"
}

backup_existing_path() {
  local path="$1"
  local label="$2"
  local backup_path

  if [ ! -e "$path" ]; then
    return
  fi

  if [ "$BACKUP_ALL" = true ] && [ "$BACKUP_ALL_CREATED" = true ]; then
    echo -e "${YELLOW}  ⚠ ${label} 이미 존재 — backup-all snapshot에 포함됨${NC}"
    echo -e "  📦 snapshot: ${BACKUP_SNAPSHOT_DIR}"
    return
  fi

  backup_path="${path}.backup.${RUN_TIMESTAMP}"
  echo -e "${YELLOW}  ⚠ ${label} 이미 존재 — 백업 후 덮어쓰기${NC}"
  echo -e "  📦 백업: ${backup_path}"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "백업 생성: ${backup_path}"
  elif [ -d "$path" ]; then
    cp -r "$path" "$backup_path"
  else
    cp "$path" "$backup_path"
  fi
}

count_existing_paths() {
  local base="$1"
  shift
  local count=0
  local rel_path

  for rel_path in "$@"; do
    if [ -e "$base/$rel_path" ]; then
      count=$((count + 1))
    fi
  done

  echo "$count"
}

join_existing_paths() {
  local base="$1"
  shift
  local rel_path
  local matches=()
  local old_ifs="$IFS"

  for rel_path in "$@"; do
    if [ -e "$base/$rel_path" ]; then
      matches+=("$rel_path")
    fi
  done

  if [ "${#matches[@]}" -eq 0 ]; then
    echo "없음"
    return
  fi

  IFS=', '
  echo "${matches[*]}"
  IFS="$old_ifs"
}

set_project_mode_guidance() {
  case "$PROJECT_CONTEXT_MODE" in
    blank-start)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
blank-start 모드 지침:
- 프로젝트 근거가 거의 없으므로 확인 가능한 사실만 남겨.
- 스택, 실행 명령, 도메인 규칙은 추정해서 채우지 마.
- 자동 채우기보다 안전한 초기화가 우선이며, 실제 문서나 코드가 생긴 뒤 재실행을 전제로 안내해.
EOF
)
      ;;
    docs-first)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
docs-first 모드 지침:
- README, docs, spec, prd, requirements를 1차 근거로 사용해.
- 아직 구현되지 않은 내용은 TODO, 예정, 가정으로 명확히 표시해.
- 검증 가능한 코드/설정이 없는 내용은 단정하지 마.
EOF
)
      ;;
    hybrid)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
hybrid 모드 지침:
- 실제 코드, 설정, 테스트를 먼저 확인하고 문서는 설계 의도와 누락 보완용으로 사용해.
- 문서와 구현이 다르면 구현을 우선하되, 중요한 차이는 짧게 기록해.
- 문서와 구현을 섞어 쓰더라도 확인하지 못한 내용은 추정으로 표시해.
EOF
)
      ;;
    code-first)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
code-first 모드 지침:
- 실제 디렉토리 구조, 실행 명령, 테스트, 설정 파일을 1차 근거로 사용해.
- 문서가 코드와 다르면 코드를 우선하고, 충돌 내용은 짧게 드러내.
- 오래된 문서 표현을 그대로 옮기지 말고 현재 구현 상태에 맞게 다시 써.
EOF
)
      ;;
  esac
}

detect_project_stack() {
  local base="$1"
  local next_markers=("next.config.js" "next.config.mjs" "next.config.ts")
  local vite_markers=("vite.config.js" "vite.config.mjs" "vite.config.ts")

  if [ "$(count_existing_paths "$base" "${next_markers[@]}")" -ge 1 ]; then
    PROJECT_STACK="Next.js (TypeScript/JavaScript)"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "${next_markers[@]}")"
  elif [ "$(count_existing_paths "$base" "${vite_markers[@]}")" -ge 1 ]; then
    PROJECT_STACK="Vite (TypeScript/JavaScript)"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "${vite_markers[@]}")"
  elif [ -e "$base/package.json" ]; then
    if [ -e "$base/tsconfig.json" ]; then
      PROJECT_STACK="Node.js / TypeScript"
      PROJECT_STACK_SIGNALS="package.json, tsconfig.json"
    else
      PROJECT_STACK="Node.js / JavaScript"
      PROJECT_STACK_SIGNALS="package.json"
    fi
  elif [ -e "$base/pyproject.toml" ] || [ -e "$base/requirements.txt" ]; then
    PROJECT_STACK="Python"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "pyproject.toml" "requirements.txt")"
  elif [ -e "$base/go.mod" ]; then
    PROJECT_STACK="Go"
    PROJECT_STACK_SIGNALS="go.mod"
  elif [ -e "$base/Cargo.toml" ]; then
    PROJECT_STACK="Rust"
    PROJECT_STACK_SIGNALS="Cargo.toml"
  elif [ -e "$base/pom.xml" ] || [ -e "$base/build.gradle" ] || [ -e "$base/build.gradle.kts" ]; then
    PROJECT_STACK="Java / Kotlin"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "pom.xml" "build.gradle" "build.gradle.kts")"
  elif [ -e "$base/Gemfile" ]; then
    PROJECT_STACK="Ruby"
    PROJECT_STACK_SIGNALS="Gemfile"
  elif [ -e "$base/composer.json" ]; then
    PROJECT_STACK="PHP"
    PROJECT_STACK_SIGNALS="composer.json"
  else
    PROJECT_STACK="미감지"
    PROJECT_STACK_SIGNALS="없음"
  fi
}

set_project_archetype_guidance() {
  case "$PROJECT_ARCHETYPE" in
    frontend-web)
      PROJECT_ARCHETYPE_GUIDANCE="프론트엔드 중심 프로젝트로 보고 브라우저 실행, 프론트 테스트, 번들링/개발 서버 명령을 우선 채워."
      ;;
    backend-api)
      PROJECT_ARCHETYPE_GUIDANCE="백엔드/API 중심 프로젝트로 보고 서버 실행, API 테스트, 마이그레이션/런타임 설정을 우선 채워."
      ;;
    cli-tool)
      PROJECT_ARCHETYPE_GUIDANCE="CLI 도구로 보고 설치/실행 예시, 엔트리포인트, 인자 처리와 관련된 명령/설명을 우선 채워."
      ;;
    worker-batch)
      PROJECT_ARCHETYPE_GUIDANCE="워커/배치 프로젝트로 보고 큐 소비, 스케줄러, 잡 실행 및 재시도 전략 관련 내용을 우선 반영해."
      ;;
    data-automation)
      PROJECT_ARCHETYPE_GUIDANCE="데이터/자동화 프로젝트로 보고 파이프라인 실행, 스크립트 진입점, 데이터 의존성과 재현성 관련 내용을 우선 반영해."
      ;;
    library-sdk)
      PROJECT_ARCHETYPE_GUIDANCE="라이브러리/SDK로 보고 공개 API, 사용 예시, 배포/버전 관리, 호환성 검증에 초점을 맞춰."
      ;;
    infra-iac)
      PROJECT_ARCHETYPE_GUIDANCE="인프라/IaC 프로젝트로 보고 plan/apply, 검증, 환경 분리, 배포 안전장치 관련 내용을 우선 반영해."
      ;;
    *)
      PROJECT_ARCHETYPE_GUIDANCE="일반 애플리케이션으로 보고 실제 코드 구조와 실행 명령을 우선 정리해."
      ;;
  esac
}

validate_archetype_hint() {
  local archetype="$1"

  case "$archetype" in
    frontend-web|backend-api|cli-tool|worker-batch|data-automation|library-sdk|infra-iac|general-app)
      ;;
    *)
      echo -e "${RED}오류: 알 수 없는 archetype '$archetype'${NC}" >&2
      usage
      exit 1
      ;;
  esac
}

apply_user_hints() {
  HAS_USER_GUIDANCE=false

  PROJECT_NAME="${TARGET_BASENAME}"
  PROJECT_NAME_SOURCE="target directory"

  if [ -n "$USER_PROJECT_NAME_HINT" ]; then
    PROJECT_NAME="$USER_PROJECT_NAME_HINT"
    PROJECT_NAME_SOURCE="user hint"
    HAS_USER_GUIDANCE=true
  fi

  if [ -n "$USER_STACK_HINT" ]; then
    PROJECT_STACK="$USER_STACK_HINT"
    PROJECT_STACK_SIGNALS="user hint"
    HAS_USER_GUIDANCE=true
  fi

  if [ -n "$USER_ARCHETYPE_HINT" ]; then
    validate_archetype_hint "$USER_ARCHETYPE_HINT"
    PROJECT_ARCHETYPE="$USER_ARCHETYPE_HINT"
    PROJECT_ARCHETYPE_SIGNALS="user hint"
    PROJECT_ARCHETYPE_REASON="사용자 힌트로 지정됨"
    set_project_archetype_guidance
    HAS_USER_GUIDANCE=true
  fi
}

detect_project_archetype() {
  local base="$1"
  local frontend_markers=(
    "next.config.js"
    "next.config.mjs"
    "next.config.ts"
    "vite.config.js"
    "vite.config.mjs"
    "vite.config.ts"
    "src/app"
    "src/pages"
    "frontend/src"
  )
  local backend_markers=(
    "app/main.py"
    "manage.py"
    "main.go"
    "backend"
    "backend/app"
    "backend/src"
    "src/api"
    "app/api"
  )
  local cli_markers=("cmd" "bin" "cli" "cli.py" "cli.ts")
  local worker_markers=("worker" "workers" "jobs" "queue" "scheduler" "celery.py")
  local data_markers=("notebooks" "pipelines" "airflow" "dbt_project.yml" "scripts")
  local infra_markers=(
    "terraform"
    "ansible"
    "helm"
    "infra"
    "k8s"
    "docker-compose.yml"
    "docker-compose.yaml"
    "compose.yaml"
    "compose.yml"
    ".github/workflows"
  )
  local frontend_count
  local backend_count
  local cli_count
  local worker_count
  local data_count
  local infra_count

  frontend_count="$(count_existing_paths "$base" "${frontend_markers[@]}")"
  backend_count="$(count_existing_paths "$base" "${backend_markers[@]}")"
  cli_count="$(count_existing_paths "$base" "${cli_markers[@]}")"
  worker_count="$(count_existing_paths "$base" "${worker_markers[@]}")"
  data_count="$(count_existing_paths "$base" "${data_markers[@]}")"
  infra_count="$(count_existing_paths "$base" "${infra_markers[@]}")"

  if [ "$infra_count" -ge 2 ] && \
     [ "$frontend_count" -eq 0 ] && \
     [ "$backend_count" -eq 0 ] && \
     [ "$cli_count" -eq 0 ] && \
     [ "$worker_count" -eq 0 ] && \
     [ "$data_count" -eq 0 ]; then
    PROJECT_ARCHETYPE="infra-iac"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${infra_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="인프라/IaC 신호가 다수이고 앱 코드 신호가 거의 없음"
  elif [ "$frontend_count" -ge 2 ] || { [ "$frontend_count" -ge 1 ] && [ -e "$base/package.json" ]; }; then
    PROJECT_ARCHETYPE="frontend-web"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${frontend_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="웹 프론트엔드 구성 신호가 확인됨"
  elif [ "$worker_count" -ge 2 ] || { [ "$worker_count" -ge 1 ] && [ "$backend_count" -ge 1 ]; }; then
    PROJECT_ARCHETYPE="worker-batch"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${worker_markers[@]}" "${backend_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="워커/큐/잡 관련 신호가 백엔드 구조와 함께 확인됨"
  elif [ "$cli_count" -ge 1 ] && [ "$frontend_count" -eq 0 ]; then
    PROJECT_ARCHETYPE="cli-tool"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${cli_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="CLI 엔트리포인트 또는 실행용 디렉토리 신호가 확인됨"
  elif [ "$data_count" -ge 2 ] || { [ "$data_count" -ge 1 ] && [ "$PROJECT_STACK" = "Python" ]; }; then
    PROJECT_ARCHETYPE="data-automation"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${data_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="데이터 파이프라인/자동화 스크립트 관련 신호가 확인됨"
  elif [ -e "$base/examples" ] && [ -e "$base/src" ] && [ "$frontend_count" -eq 0 ] && [ "$backend_count" -eq 0 ] && [ "$cli_count" -eq 0 ] && [ "$worker_count" -eq 0 ] && [ "$data_count" -eq 0 ]; then
    PROJECT_ARCHETYPE="library-sdk"
    PROJECT_ARCHETYPE_SIGNALS="src, examples"
    PROJECT_ARCHETYPE_REASON="실행 앱보다 공개 API/예제 중심 구조로 보임"
  elif [ "$backend_count" -ge 1 ] || { [ "$PROJECT_CONTEXT_MODE" = "code-first" ] && [ "$PROJECT_STACK" != "미감지" ] && [ "$frontend_count" -eq 0 ]; }; then
    PROJECT_ARCHETYPE="backend-api"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${backend_markers[@]}")"
    if [ "$PROJECT_ARCHETYPE_SIGNALS" = "없음" ]; then
      PROJECT_ARCHETYPE_SIGNALS="$PROJECT_STACK_SIGNALS"
    fi
    PROJECT_ARCHETYPE_REASON="서버/API 실행 구조 또는 백엔드 중심 스택 신호가 확인됨"
  elif [ "$infra_count" -ge 1 ] && [ "$IMPLEMENTATION_SIGNAL_COUNT" -le 2 ]; then
    PROJECT_ARCHETYPE="infra-iac"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${infra_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="인프라 관련 구성은 있으나 애플리케이션 신호는 제한적임"
  else
    PROJECT_ARCHETYPE="general-app"
    PROJECT_ARCHETYPE_SIGNALS="없음"
    PROJECT_ARCHETYPE_REASON="지배적인 프로젝트 유형 신호가 부족해 일반 애플리케이션으로 처리"
  fi

  set_project_archetype_guidance
}

detect_project_context_mode() {
  local base="$1"
  local blank_start_markers=(
    "README.md"
    "spec"
    "specs"
    "prd"
    "requirements"
    "docs/architecture.md"
    "docs/requirements.md"
    "docs/product.md"
    "docs/specs"
    "docs/prd.md"
    "package.json"
    "pyproject.toml"
    "go.mod"
    "Cargo.toml"
    "pom.xml"
    "build.gradle"
    "build.gradle.kts"
    "requirements.txt"
    "Gemfile"
    "composer.json"
    "src"
    "app"
    "backend"
    "frontend"
    "server"
    "client"
    "cmd"
    "bin"
    "lib"
    "internal"
    "tests"
    "test"
    "__tests__"
    ".github/workflows"
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.yaml"
    "compose.yaml"
    "compose.yml"
    ".env.example"
    "deploy"
    "infra"
    "terraform"
    "ansible"
    "helm"
  )
  local doc_markers=(
    "README.md"
    "docs"
    "spec"
    "specs"
    "prd"
    "requirements"
    "docs/architecture.md"
    "docs/requirements.md"
    "docs/product.md"
  )
  local manifest_markers=(
    "package.json"
    "pyproject.toml"
    "go.mod"
    "Cargo.toml"
    "pom.xml"
    "build.gradle"
    "build.gradle.kts"
    "requirements.txt"
    "Gemfile"
    "composer.json"
  )
  local code_dir_markers=(
    "src"
    "app"
    "backend"
    "frontend"
    "server"
    "client"
    "cmd"
    "bin"
    "lib"
    "internal"
  )
  local test_markers=(
    "tests"
    "test"
    "__tests__"
    ".github/workflows"
  )
  local ops_markers=(
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.yaml"
    "compose.yaml"
    "compose.yml"
    ".env.example"
    ".github/workflows"
    "deploy"
    "infra"
    "terraform"
    "ansible"
    "helm"
  )
  local manifest_count
  local code_dir_count
  local blank_start_signal_count

  blank_start_signal_count="$(count_existing_paths "$base" "${blank_start_markers[@]}")"

  DOC_SIGNAL_COUNT="$(count_existing_paths "$base" "${doc_markers[@]}")"
  PROJECT_DOC_SIGNALS="$(join_existing_paths "$base" "${doc_markers[@]}")"

  manifest_count="$(count_existing_paths "$base" "${manifest_markers[@]}")"
  code_dir_count="$(count_existing_paths "$base" "${code_dir_markers[@]}")"
  IMPLEMENTATION_SIGNAL_COUNT=$((manifest_count + code_dir_count))
  PROJECT_IMPLEMENTATION_SIGNALS="$(join_existing_paths "$base" "${manifest_markers[@]}" "${code_dir_markers[@]}")"

  TEST_SIGNAL_COUNT="$(count_existing_paths "$base" "${test_markers[@]}")"
  PROJECT_TEST_SIGNALS="$(join_existing_paths "$base" "${test_markers[@]}")"

  OPS_SIGNAL_COUNT="$(count_existing_paths "$base" "${ops_markers[@]}")"
  PROJECT_OPS_SIGNALS="$(join_existing_paths "$base" "${ops_markers[@]}")"

  if [ "$blank_start_signal_count" -eq 0 ]; then
    PROJECT_CONTEXT_MODE="blank-start"
    PROJECT_CONTEXT_REASON="프로젝트 폴더에 의미 있는 문서/구현 신호가 거의 없음"
  elif [ "$IMPLEMENTATION_SIGNAL_COUNT" -le 1 ] && [ "$DOC_SIGNAL_COUNT" -ge 2 ]; then
    PROJECT_CONTEXT_MODE="docs-first"
    PROJECT_CONTEXT_REASON="문서 신호가 충분하고 실행 가능한 구현 신호가 적음"
  elif [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 4 ] || \
       { [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 3 ] && { [ "$TEST_SIGNAL_COUNT" -ge 1 ] || [ "$OPS_SIGNAL_COUNT" -ge 1 ]; }; } || \
       { [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 2 ] && [ "$DOC_SIGNAL_COUNT" -eq 0 ]; }; then
    PROJECT_CONTEXT_MODE="code-first"
    PROJECT_CONTEXT_REASON="코드/설정/테스트 신호가 풍부해 실제 구현을 우선 해석하는 편이 안전함"
  elif [ "$DOC_SIGNAL_COUNT" -ge 1 ] && [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 1 ]; then
    PROJECT_CONTEXT_MODE="hybrid"
    PROJECT_CONTEXT_REASON="문서와 구현 신호가 모두 있어 함께 해석하는 편이 적합함"
  elif [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 1 ]; then
    PROJECT_CONTEXT_MODE="code-first"
    PROJECT_CONTEXT_REASON="문서보다 구현 신호가 상대적으로 많음"
  else
    PROJECT_CONTEXT_MODE="docs-first"
    PROJECT_CONTEXT_REASON="확실한 구현 신호가 부족하므로 확인 가능한 사실만 채우는 편이 안전함"
  fi

  set_project_mode_guidance
}

append_codex_mcp_preset() {
  local preset="$1"
  local file="$2"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "Codex MCP preset 추가: ${preset} -> ${file}"
    return
  fi

  case "$preset" in
    core)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: core
[mcp_servers.sequential-thinking]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-sequential-thinking"]

[mcp_servers.serena]
command = "uvx"
args = ["--from", "git+https://github.com/oraios/serena", "serena-mcp-server", "--enable-web-dashboard", "false", "start-mcp-server"]

[mcp_servers.upstash-context-7-mcp]
command = "npx"
args = ["-y", "@upstash/context7-mcp@latest"]
EOF
      ;;
    web)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: web
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]
EOF
      ;;
    infra)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: infra
[mcp_servers.docker]
command = "npx"
args = ["-y", "@hypnosis/docker-mcp-server"]
EOF
      ;;
  esac
}

CLAUDE_MCP_FIRST=true

append_claude_mcp_server() {
  local file="$1"
  local server_name="$2"
  local command_name="$3"
  local args_json="$4"

  if [ "$CLAUDE_MCP_FIRST" = true ]; then
    CLAUDE_MCP_FIRST=false
  else
    printf ',\n' >> "$file"
  fi

  printf '    "%s": {\n      "command": "%s",\n      "args": %s\n    }' \
    "$server_name" \
    "$command_name" \
    "$args_json" >> "$file"
}

write_claude_mcp_config() {
  local file="$1"
  local preset

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "Claude MCP config 생성: ${file}"
    return
  fi

  cat <<'EOF' > "$file"
{
  "mcpServers": {
EOF

  CLAUDE_MCP_FIRST=true

  for preset in "${MCP_PRESETS[@]}"; do
    case "$preset" in
      core)
        append_claude_mcp_server "$file" "sequential-thinking" "npx" '["-y", "@modelcontextprotocol/server-sequential-thinking"]'
        append_claude_mcp_server "$file" "serena" "uvx" '["--from", "git+https://github.com/oraios/serena", "serena-mcp-server", "--enable-web-dashboard", "false", "start-mcp-server"]'
        append_claude_mcp_server "$file" "upstash-context-7-mcp" "npx" '["-y", "@upstash/context7-mcp@latest"]'
        ;;
      web)
        append_claude_mcp_server "$file" "playwright" "npx" '["-y", "@playwright/mcp@latest"]'
        ;;
      infra)
        append_claude_mcp_server "$file" "docker" "npx" '["-y", "@hypnosis/docker-mcp-server"]'
        ;;
    esac
  done

  printf '\n' >> "$file"

  cat <<'EOF' >> "$file"

  }
}
EOF
}

# 서브커맨드 전처리
UPDATE_MODE=false
if [ "${1:-}" = "update" ]; then
  UPDATE_MODE=true
  shift
elif [ "${1:-}" = "init" ]; then
  shift
fi

# 옵션 파싱
DOCTOR_MODE=false
DRY_RUN=false
DIFF_MODE=false
BACKUP_ALL=false
REAPPLY_MODE=false
AUTO_MCP=false
LINK_MODE=false
SKIP_AI=false
MCP_ENABLED=true
MCP_PRESETS=()
TARGET=""
CLAUDE_PROFILE="standard"
USER_PROJECT_NAME_HINT=""
USER_ARCHETYPE_HINT=""
USER_STACK_HINT=""
USER_MCP_PRESET_SPECIFIED=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --profile 뒤에 값이 필요합니다${NC}" >&2
        usage
        exit 1
      fi
      validate_profile "$2"
      CLAUDE_PROFILE="$2"
      shift
      ;;
    --doctor)
      DOCTOR_MODE=true
      ;;
    --link)
      LINK_MODE=true
      ;;
    --update)
      UPDATE_MODE=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --diff)
      DIFF_MODE=true
      ;;
    --backup-all)
      BACKUP_ALL=true
      ;;
    --reapply)
      REAPPLY_MODE=true
      ;;
    --auto-mcp)
      AUTO_MCP=true
      ;;
    --project-name)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --project-name 뒤에 값이 필요합니다${NC}" >&2
        usage
        exit 1
      fi
      USER_PROJECT_NAME_HINT="$2"
      shift
      ;;
    --archetype)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --archetype 뒤에 값이 필요합니다${NC}" >&2
        usage
        exit 1
      fi
      USER_ARCHETYPE_HINT="$2"
      shift
      ;;
    --stack)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --stack 뒤에 값이 필요합니다${NC}" >&2
        usage
        exit 1
      fi
      USER_STACK_HINT="$2"
      shift
      ;;
    --skip-ai)
      SKIP_AI=true
      ;;
    --no-mcp)
      MCP_ENABLED=false
      USER_MCP_PRESET_SPECIFIED=true
      ;;
    --mcp-preset)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --mcp-preset 뒤에 값이 필요합니다${NC}" >&2
        usage
        exit 1
      fi
      MCP_ENABLED=true
      USER_MCP_PRESET_SPECIFIED=true
      IFS=',' read -r -a REQUESTED_PRESETS <<< "$2"
      for preset in "${REQUESTED_PRESETS[@]}"; do
        preset="${preset// /}"
        if [ -n "$preset" ]; then
          add_mcp_preset "$preset"
        fi
      done
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo -e "${RED}오류: 알 수 없는 옵션 '$1'${NC}" >&2
      usage
      exit 1
      ;;
    *)
      if [ -n "$TARGET" ]; then
        echo -e "${RED}오류: 프로젝트 경로는 하나만 지정할 수 있습니다${NC}" >&2
        usage
        exit 1
      fi
      TARGET="$1"
      ;;
  esac
  shift
done

MODE_COUNT=0
if [ "$DOCTOR_MODE" = true ]; then
  MODE_COUNT=$((MODE_COUNT + 1))
fi
if [ "$DRY_RUN" = true ]; then
  MODE_COUNT=$((MODE_COUNT + 1))
fi
if [ "$DIFF_MODE" = true ]; then
  MODE_COUNT=$((MODE_COUNT + 1))
fi
if [ "$MODE_COUNT" -gt 1 ]; then
  echo -e "${RED}오류: --doctor, --dry-run, --diff 중 하나만 사용할 수 있습니다${NC}" >&2
  usage
  exit 1
fi
if [ "$UPDATE_MODE" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
  echo -e "${RED}오류: update 모드는 --doctor 또는 --diff와 함께 사용할 수 없습니다${NC}" >&2
  usage
  exit 1
fi
if [ "$BACKUP_ALL" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
  echo -e "${RED}오류: --backup-all은 --doctor 또는 --diff와 함께 사용할 수 없습니다${NC}" >&2
  usage
  exit 1
fi
if [ "$REAPPLY_MODE" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
  echo -e "${RED}오류: --reapply는 --doctor 또는 --diff와 함께 사용할 수 없습니다${NC}" >&2
  usage
  exit 1
fi

# ai-setting 디렉토리 (이 스크립트가 있는 곳)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TARGET="${TARGET:-.}"
TARGET="$(cd "$TARGET" && pwd)"
TARGET_BASENAME="$(basename "$TARGET")"

if [ "$UPDATE_MODE" = true ]; then
  SKIP_AI=true
fi

detect_project_context_mode "$TARGET"
detect_project_stack "$TARGET"
detect_project_archetype "$TARGET"
apply_user_hints
calculate_recommended_mcp_presets
apply_auto_mcp_presets

MCP_PRESET_LABEL="none"
if [ "${#MCP_PRESETS[@]}" -gt 0 ]; then
  MCP_PRESET_LABEL="$(IFS=,; echo "${MCP_PRESETS[*]}")"
fi

if [ "$DOCTOR_MODE" = true ]; then
  if run_doctor "$TARGET"; then
    exit 0
  else
    exit 1
  fi
fi

if [ "$DIFF_MODE" = true ]; then
  if run_diff_preview "$TARGET"; then
    exit 0
  else
    exit 1
  fi
fi

echo -e "${CYAN}━━━ AI Setting Init ━━━${NC}"
echo -e "소스: ${SCRIPT_DIR}"
echo -e "대상: ${TARGET}"
echo -e "Claude 프로필: ${CLAUDE_PROFILE}"
if [ "$LINK_MODE" = true ]; then
  echo -e "공유 자산 모드: symlink"
else
  echo -e "공유 자산 모드: copy"
fi
echo -e "MCP preset: ${MCP_PRESET_LABEL}"
echo -e "MCP 추천: ${RECOMMENDED_MCP_PRESET_LABEL}"
echo -e "프로젝트명: ${PROJECT_NAME}"
echo -e "해석 모드: ${PROJECT_CONTEXT_MODE}"
echo -e "프로젝트 유형: ${PROJECT_ARCHETYPE}"
echo -e "주 스택: ${PROJECT_STACK}"
if [ "$HAS_USER_GUIDANCE" = true ]; then
  echo -e "사용자 힌트: project-name=${USER_PROJECT_NAME_HINT:-없음}, archetype=${USER_ARCHETYPE_HINT:-없음}, stack=${USER_STACK_HINT:-없음}"
fi
if [ "$AUTO_MCP" = true ]; then
  if [ "$AUTO_MCP_APPLIED" = true ]; then
    echo -e "MCP 자동 추천 적용: on"
  else
    echo -e "MCP 자동 추천 적용: 요청됨 (명시 preset 또는 --no-mcp 우선)"
  fi
fi
if [ "$UPDATE_MODE" = true ]; then
  echo -e "명령 모드: update"
fi
if [ "$DRY_RUN" = true ]; then
  echo -e "실행 모드: dry-run"
fi
if [ "$BACKUP_ALL" = true ]; then
  echo -e "백업 모드: backup-all"
fi
if [ "$REAPPLY_MODE" = true ]; then
  echo -e "재적용 모드: reapply"
fi
echo ""

# jq 의존성 체크 (hooks가 jq로 JSON 파싱)
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}⚠ jq가 설치되어 있지 않습니다.${NC}"
  echo -e "  hooks(protect-files, block-dangerous-commands)가 정상 동작하려면 jq가 필요합니다."
  echo -e "  설치: brew install jq (macOS) / sudo apt install jq (Linux)"
  echo ""
fi

if [ "$BACKUP_ALL" = true ]; then
  perform_backup_all
fi

# ============================================================
# 1단계: Claude Code 설정 복사
# ============================================================
echo -e "${GREEN}[1/7]${NC} Claude Code 설정 복사 (.claude/)"

if [ -d "$TARGET/.claude" ]; then
  backup_existing_path "$TARGET/.claude" ".claude/"
fi

cleanup_managed_claude_assets
copy_claude_profile_assets

if [ "$CLAUDE_PROFILE" = "minimal" ]; then
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ minimal profile 심링크 적용 예정 (settings 1개, hooks 1개)"
    else
      echo "  ✅ minimal profile 적용 예정 (settings 1개, hooks 1개)"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ minimal profile 심링크 적용됨 (settings 1개, hooks 1개)"
    else
      echo "  ✅ minimal profile 적용됨 (settings 1개, hooks 1개)"
    fi
  fi
elif [ "$CLAUDE_PROFILE" = "strict" ]; then
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ strict profile 심링크 적용 예정 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    else
      echo "  ✅ strict profile 적용 예정 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ strict profile 심링크 적용됨 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    else
      echo "  ✅ strict profile 적용됨 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    fi
  fi
elif [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ team profile 심링크 적용 예정 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    else
      echo "  ✅ team profile 적용 예정 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ team profile 심링크 적용됨 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    else
      echo "  ✅ team profile 적용됨 (settings 1개, hooks 3개, agents 4개, skills 5개)"
    fi
  fi
else
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ standard profile 심링크 적용 예정 (settings 1개, hooks 2개, agents 4개, skills 5개)"
    else
      echo "  ✅ standard profile 적용 예정 (settings 1개, hooks 2개, agents 4개, skills 5개)"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ standard profile 심링크 적용됨 (settings 1개, hooks 2개, agents 4개, skills 5개)"
    else
      echo "  ✅ standard profile 적용됨 (settings 1개, hooks 2개, agents 4개, skills 5개)"
    fi
  fi
fi

# ============================================================
# 2단계: 추가 AI 도구 설정 복사
# ============================================================
echo -e "${GREEN}[2/7]${NC} Cursor / Gemini / Copilot 설정 복사"

copy_cursor_assets
copy_gemini_assets

if [ "$DRY_RUN" = true ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "  ✅ Cursor rule 심링크 예정 (.cursor/rules/ai-setting.mdc)"
    echo "  ✅ Gemini settings 심링크 예정 (.gemini/settings.json)"
  else
    echo "  ✅ Cursor rule 복사 예정 (.cursor/rules/ai-setting.mdc)"
    echo "  ✅ Gemini settings 복사 예정 (.gemini/settings.json)"
  fi
else
  if [ "$LINK_MODE" = true ]; then
    echo "  ✅ Cursor rule 심링크 적용됨 (.cursor/rules/ai-setting.mdc)"
    echo "  ✅ Gemini settings 심링크 적용됨 (.gemini/settings.json)"
  else
    echo "  ✅ Cursor rule 적용됨 (.cursor/rules/ai-setting.mdc)"
    echo "  ✅ Gemini settings 적용됨 (.gemini/settings.json)"
  fi
fi

# ============================================================
# 3단계: Codex 설정 복사
# ============================================================
echo -e "${GREEN}[3/7]${NC} Codex CLI 설정 복사 (.codex/)"

run_mkdir_p "$TARGET/.codex"
if [ -f "$TARGET/.codex/config.toml" ]; then
  backup_existing_path "$TARGET/.codex/config.toml" ".codex/config.toml"
fi
run_copy "$SCRIPT_DIR/codex/config.toml" "$TARGET/.codex/config.toml"

if [ "$DRY_RUN" = true ]; then
  echo "  ✅ config.toml 복사 예정"
else
  echo "  ✅ config.toml"
fi

# ============================================================
# 4단계: 프로젝트 로컬 MCP preset 생성
# ============================================================
echo -e "${GREEN}[4/7]${NC} 프로젝트 로컬 MCP preset 생성"

if [ "$MCP_ENABLED" = false ]; then
  echo -e "  ${YELLOW}--no-mcp 옵션으로 건너뜀${NC}"
else
  if [ -f "$TARGET/.mcp.json" ]; then
    backup_existing_path "$TARGET/.mcp.json" ".mcp.json"
  fi

  for preset in "${MCP_PRESETS[@]}"; do
    append_codex_mcp_preset "$preset" "$TARGET/.codex/config.toml"
  done
  write_claude_mcp_config "$TARGET/.mcp.json"

  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ Codex MCP preset 적용 예정 ($MCP_PRESET_LABEL)"
    echo "  ✅ Claude MCP config 생성 예정 (.mcp.json)"
  else
    echo "  ✅ Codex MCP preset 적용됨 ($MCP_PRESET_LABEL)"
    echo "  ✅ Claude MCP config 생성됨 (.mcp.json)"
  fi
fi

# ============================================================
# 5단계: 프로젝트 문서 템플릿 복사
# ============================================================
echo -e "${GREEN}[5/7]${NC} 템플릿 복사"

TEMPLATES_COPIED=false

if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/CLAUDE.md" ]; then
  backup_existing_path "$TARGET/CLAUDE.md" "CLAUDE.md"
  run_copy "$SCRIPT_DIR/templates/CLAUDE.md.template" "$TARGET/CLAUDE.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ CLAUDE.md 재생성 예정"
  else
    echo "  ✅ CLAUDE.md 재생성됨"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/CLAUDE.md" ]; then
  run_copy "$SCRIPT_DIR/templates/CLAUDE.md.template" "$TARGET/CLAUDE.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ CLAUDE.md 생성 예정"
  else
    echo "  ✅ CLAUDE.md 생성됨"
  fi
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}⚠ CLAUDE.md 이미 존재 — 건너뜀${NC}"
fi

if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/AGENTS.md" ]; then
  backup_existing_path "$TARGET/AGENTS.md" "AGENTS.md"
  run_copy "$SCRIPT_DIR/templates/AGENTS.md.template" "$TARGET/AGENTS.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ AGENTS.md 재생성 예정"
  else
    echo "  ✅ AGENTS.md 재생성됨"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/AGENTS.md" ]; then
  run_copy "$SCRIPT_DIR/templates/AGENTS.md.template" "$TARGET/AGENTS.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ AGENTS.md 생성 예정"
  else
    echo "  ✅ AGENTS.md 생성됨"
  fi
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}⚠ AGENTS.md 이미 존재 — 건너뜀${NC}"
fi

if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/GEMINI.md" ]; then
  backup_existing_path "$TARGET/GEMINI.md" "GEMINI.md"
  run_copy "$SCRIPT_DIR/templates/GEMINI.md.template" "$TARGET/GEMINI.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ GEMINI.md 재생성 예정"
  else
    echo "  ✅ GEMINI.md 재생성됨"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/GEMINI.md" ]; then
  run_copy "$SCRIPT_DIR/templates/GEMINI.md.template" "$TARGET/GEMINI.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ GEMINI.md 생성 예정"
  else
    echo "  ✅ GEMINI.md 생성됨"
  fi
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}⚠ GEMINI.md 이미 존재 — 건너뜀${NC}"
fi

run_mkdir_p "$TARGET/.github"
if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/.github/copilot-instructions.md" ]; then
  backup_existing_path "$TARGET/.github/copilot-instructions.md" ".github/copilot-instructions.md"
  run_copy "$SCRIPT_DIR/templates/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ .github/copilot-instructions.md 재생성 예정"
  else
    echo "  ✅ .github/copilot-instructions.md 재생성됨"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/.github/copilot-instructions.md" ]; then
  run_copy "$SCRIPT_DIR/templates/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ .github/copilot-instructions.md 생성 예정"
  else
    echo "  ✅ .github/copilot-instructions.md 생성됨"
  fi
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}⚠ .github/copilot-instructions.md 이미 존재 — 건너뜀${NC}"
fi

if [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/.github/pull_request_template.md" ]; then
    backup_existing_path "$TARGET/.github/pull_request_template.md" ".github/pull_request_template.md"
    run_copy "$SCRIPT_DIR/templates/pull_request_template.md.template" "$TARGET/.github/pull_request_template.md"
    if [ "$DRY_RUN" = true ]; then
      echo "  ✅ .github/pull_request_template.md 재생성 예정"
    else
      echo "  ✅ .github/pull_request_template.md 재생성됨"
    fi
  elif [ ! -f "$TARGET/.github/pull_request_template.md" ]; then
    run_copy "$SCRIPT_DIR/templates/pull_request_template.md.template" "$TARGET/.github/pull_request_template.md"
    if [ "$DRY_RUN" = true ]; then
      echo "  ✅ .github/pull_request_template.md 생성 예정"
    else
      echo "  ✅ .github/pull_request_template.md 생성됨"
    fi
  else
    echo -e "  ${YELLOW}⚠ .github/pull_request_template.md 이미 존재 — 건너뜀${NC}"
  fi
fi

run_mkdir_p "$TARGET/docs"
if [ ! -f "$TARGET/docs/decisions.md" ]; then
  run_copy "$SCRIPT_DIR/templates/decisions.md.template" "$TARGET/docs/decisions.md"
  if [ "$DRY_RUN" = true ]; then
    echo "  ✅ docs/decisions.md 생성 예정"
  else
    echo "  ✅ docs/decisions.md 생성됨"
  fi
else
  if [ "$REAPPLY_MODE" = true ]; then
    echo -e "  ${YELLOW}⚠ docs/decisions.md는 사용자 기록 파일로 간주되어 유지합니다${NC}"
  else
    echo -e "  ${YELLOW}⚠ docs/decisions.md 이미 존재 — 건너뜀${NC}"
  fi
fi

# ============================================================
# 6단계: AI로 템플릿 자동 채우기 (Claude Code → Codex → 수동)
# ============================================================
echo -e "${GREEN}[6/7]${NC} AI로 프로젝트 문서 자동 생성"

if [ "$CLAUDE_PROFILE" = "minimal" ]; then
  AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 minimal profile을 사용하므로 managed agents/skills를 새로 만들거나 복원하지 마.
- `.claude/skills`가 없으면 생성하지 말고, skills 전용 placeholder도 건드릴 수 없으면 그대로 둬.
EOF
)
  AI_SKILL_TASK="4. minimal profile이므로 .claude/skills/ 관련 파일이 이미 없으면 새로 만들지 마. 존재하는 경우에만 {{중괄호}} 플레이스홀더를 프로젝트에 맞게 교체해."
elif [ "$CLAUDE_PROFILE" = "strict" ]; then
  AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 strict profile을 사용하므로 검증, 문서 동기화, feature branch 사용 원칙을 더 엄격하게 반영해.
- main/master 직접 작업 대신 feature branch + PR 흐름을 자연스럽게 유도해.
EOF
)
  AI_SKILL_TASK="4. .claude/skills/ 안의 SKILL.md 파일들에서 {{중괄호}} 플레이스홀더({{TEST_CMD}}, {{LINT_CMD}}, {{DEPLOY_BACKEND_CMD}} 등)를 프로젝트에 맞는 실제 명령어로 교체해줘."
elif [ "$CLAUDE_PROFILE" = "team" ]; then
  AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 team profile을 사용하므로 협업, PR 설명, 검증 기록이 드러나도록 문서를 정리해.
- main/master 직접 작업 대신 feature branch + PR 흐름을 자연스럽게 유도해.
EOF
)
  AI_SKILL_TASK="4. .claude/skills/ 안의 SKILL.md 파일들에서 {{중괄호}} 플레이스홀더({{TEST_CMD}}, {{LINT_CMD}}, {{DEPLOY_BACKEND_CMD}} 등)를 프로젝트에 맞는 실제 명령어로 교체해줘."
else
  AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 standard profile을 사용하므로 managed skills placeholder도 함께 실제 명령어로 치환해.
EOF
)
  AI_SKILL_TASK="4. .claude/skills/ 안의 SKILL.md 파일들에서 {{중괄호}} 플레이스홀더({{TEST_CMD}}, {{LINT_CMD}}, {{DEPLOY_BACKEND_CMD}} 등)를 프로젝트에 맞는 실제 명령어로 교체해줘."
fi

AI_PROMPT=$(cat <<EOF
이 프로젝트를 아래 규칙으로 분석해.

프로젝트 이름: ${PROJECT_NAME}
프로젝트 이름 출처: ${PROJECT_NAME_SOURCE}
Claude 프로필: ${CLAUDE_PROFILE}

프로젝트 해석 모드: ${PROJECT_CONTEXT_MODE}
선정 이유: ${PROJECT_CONTEXT_REASON}

프로젝트 유형(archetype): ${PROJECT_ARCHETYPE}
선정 이유: ${PROJECT_ARCHETYPE_REASON}
주 스택: ${PROJECT_STACK}
스택 신호: ${PROJECT_STACK_SIGNALS}

사용자 제공 힌트:
- project-name: ${USER_PROJECT_NAME_HINT:-없음}
- archetype: ${USER_ARCHETYPE_HINT:-없음}
- stack: ${USER_STACK_HINT:-없음}

감지 신호:
- 문서: ${PROJECT_DOC_SIGNALS}
- 구현: ${PROJECT_IMPLEMENTATION_SIGNALS}
- 테스트: ${PROJECT_TEST_SIGNALS}
- 운영: ${PROJECT_OPS_SIGNALS}
- archetype: ${PROJECT_ARCHETYPE_SIGNALS}

${PROJECT_MODE_GUIDANCE}
${PROJECT_ARCHETYPE_GUIDANCE}
${AI_PROFILE_GUIDANCE}

추가 지침:
- 사용자 힌트가 있으면 자동 감지보다 우선하는 의도로 간주해.
- blank-start + 사용자 힌트 조합이면 guided blank-start로 보고, 힌트 기반 초안을 만들되 확인할 수 없는 명령어/구조는 TODO나 가정으로 표시해.

작업:
1. CLAUDE.md와 AGENTS.md의 [대괄호] 부분을 이 프로젝트에 맞게 전부 채워줘. 대괄호를 실제 내용으로 교체하고, 프로젝트에 해당하지 않는 섹션은 제거해. 기존 템플릿의 공통 규칙(Coding Rules, Forbidden 등)은 유지하되 프로젝트 스택에 맞게 보강해.
2. GEMINI.md가 있으면 [대괄호] 부분을 채우고, Gemini CLI에서 참고할 핵심 지침이 CLAUDE.md / AGENTS.md와 모순되지 않게 정리해줘.
3. .github/copilot-instructions.md가 있으면 GitHub Copilot이 바로 참고할 수 있도록 프로젝트 요약, build/test/lint 명령, 핵심 협업 규칙을 간결하게 정리해줘.
${AI_SKILL_TASK}
5. .github/pull_request_template.md가 있으면 팀이 바로 쓸 수 있도록 유지하고, placeholder가 있다면 실제 검증/리스크 항목에 맞게 다듬어줘.
6. 문서와 구현이 충돌하면 CLAUDE.md 끝에 '## Detected Mismatches' 섹션을 추가하고, 확인한 불일치를 짧게 정리해. 충돌이 없으면 이 섹션은 만들지 마.
7. 확실하지 않은 내용은 사실처럼 단정하지 말고 TODO, 가정, 예정으로 표시해.
EOF
)

if [ "$UPDATE_MODE" = true ]; then
  echo -e "  ${YELLOW}update 모드에서는 AI 자동 채우기를 건너뜁니다${NC}"
elif [ "$SKIP_AI" = true ]; then
  echo -e "  ${YELLOW}--skip-ai 옵션으로 건너뜀${NC}"
elif [ "$DRY_RUN" = true ]; then
  echo -e "  ${YELLOW}--dry-run 모드에서는 AI 자동 채우기를 실행하지 않습니다${NC}"
elif [ "$PROJECT_CONTEXT_MODE" = "blank-start" ] && [ "$HAS_USER_GUIDANCE" = false ]; then
  echo "  mode: ${PROJECT_CONTEXT_MODE} (${PROJECT_CONTEXT_REASON})"
  echo -e "  ${YELLOW}프로젝트 근거가 거의 없어 AI 자동 채우기를 건너뜁니다${NC}"
  echo "  README, package.json, pyproject.toml, src/ 같은 신호가 생긴 뒤 다시 실행하세요"
elif [ "$TEMPLATES_COPIED" = false ]; then
  echo -e "  ${YELLOW}새 템플릿이 없음 (이미 존재) — 건너뜀${NC}"
else
  AI_SUCCESS=false
  echo "  mode: ${PROJECT_CONTEXT_MODE} (${PROJECT_CONTEXT_REASON})"
  if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ] && [ "$HAS_USER_GUIDANCE" = true ]; then
    echo "  blank-start with guidance: 사용자 힌트를 바탕으로 초안을 시도합니다"
  fi
  echo "  archetype: ${PROJECT_ARCHETYPE} (${PROJECT_ARCHETYPE_REASON})"
  echo "  stack: ${PROJECT_STACK} [${PROJECT_STACK_SIGNALS}]"
  if [ "$HAS_USER_GUIDANCE" = true ]; then
    echo "  user hints: project-name=${USER_PROJECT_NAME_HINT:-없음}, archetype=${USER_ARCHETYPE_HINT:-없음}, stack=${USER_STACK_HINT:-없음}"
  fi
  echo "  signals: docs=[${PROJECT_DOC_SIGNALS}] | impl=[${PROJECT_IMPLEMENTATION_SIGNALS}] | tests=[${PROJECT_TEST_SIGNALS}] | ops=[${PROJECT_OPS_SIGNALS}]"

  # 시도 1: Claude Code
  if command -v claude &> /dev/null; then
    echo "  🔄 Claude Code로 프로젝트 분석 중..."
    if cd "$TARGET" && claude -p "$AI_PROMPT" --allowedTools Write,Edit,Read,Glob,Grep 2>/dev/null; then
      AI_SUCCESS=true
      echo "  ✅ Claude Code가 프로젝트 문서를 자동 생성했습니다"
    else
      echo -e "  ${YELLOW}  Claude Code 실행 실패 — Codex로 시도합니다${NC}"
    fi
  else
    echo -e "  ${YELLOW}  Claude Code 미설치 — Codex로 시도합니다${NC}"
  fi

  # 시도 2: Codex (fallback)
  if [ "$AI_SUCCESS" = false ]; then
    if command -v codex &> /dev/null; then
      echo "  🔄 Codex로 프로젝트 분석 중..."
      if (cd "$TARGET" && codex -q "$AI_PROMPT") 2>/dev/null; then
        AI_SUCCESS=true
        echo "  ✅ Codex가 프로젝트 문서를 자동 생성했습니다"
      else
        echo -e "  ${YELLOW}  Codex 실행 실패${NC}"
      fi
    else
      echo -e "  ${YELLOW}  Codex 미설치${NC}"
    fi
  fi

  # 시도 3: 수동 안내 (최종 fallback)
  if [ "$AI_SUCCESS" = false ]; then
    echo ""
    echo -e "  ${RED}⚠ AI 자동 생성 실패${NC}"
    echo -e "  Claude Code와 Codex를 모두 사용할 수 없습니다."
    echo ""
    echo -e "  ${CYAN}수동으로 채우는 방법:${NC}"
    echo "    1. CLAUDE.md, AGENTS.md, GEMINI.md, .github/copilot-instructions.md의 [대괄호] 부분을 직접 채우세요"
    echo "    2. 또는 Claude Code / Codex 설치 후 프로젝트 디렉토리에서:"
    echo "       claude \"프로젝트 문서의 [대괄호] 부분을 채워줘\""
    echo ""
  fi
fi

# ============================================================
# 7단계: 완료 요약
# ============================================================
echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${GREEN}[7/7]${NC} dry-run 완료!"
else
  echo -e "${GREEN}[7/7]${NC} 완료!"
fi
echo ""
echo -e "${CYAN}━━━ 적용된 설정 ━━━${NC}"
echo ""
echo "  바로 사용 가능:"
if [ "$CLAUDE_PROFILE" = "minimal" ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "    .claude/settings.json     — minimal hooks 2개 (심링크)"
  else
    echo "    .claude/settings.json     — minimal hooks 2개 (파일보호, 포맷터)"
  fi
  echo "    .claude/hooks/            — 파일 보호"
elif [ "$CLAUDE_PROFILE" = "strict" ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "    .claude/settings.json     — strict hooks + branch 보호 (심링크)"
  else
    echo "    .claude/settings.json     — strict hooks 6개 + branch 보호"
  fi
  echo "    .claude/hooks/            — 파일 보호 + 위험 명령 차단 + main/master 보호"
  echo "    .claude/agents/           — 보안 리뷰, 설계 검증, 테스트 작성, 리서치"
  echo "    .claude/skills/           — 배포, 리뷰, 이슈수정, Gap체크, 교차검증"
elif [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "    .claude/settings.json     — team hooks + branch 보호 (심링크)"
  else
    echo "    .claude/settings.json     — team hooks 6개 + branch 보호"
  fi
  echo "    .claude/hooks/            — 파일 보호 + 위험 명령 차단 + main/master 보호"
  echo "    .claude/agents/           — 보안 리뷰, 설계 검증, 테스트 작성, 리서치"
  echo "    .claude/skills/           — 배포, 리뷰, 이슈수정, Gap체크, 교차검증"
else
  if [ "$LINK_MODE" = true ]; then
    echo "    .claude/settings.json     — hooks 6개 (심링크)"
  else
    echo "    .claude/settings.json     — hooks 6개 (포맷터, 파일보호, 명령차단, 알림, 테스트체크, 리마인더)"
  fi
  echo "    .claude/hooks/            — 파일 보호 + 위험 명령 차단"
  echo "    .claude/agents/           — 보안 리뷰, 설계 검증, 테스트 작성, 리서치"
  echo "    .claude/skills/           — 배포, 리뷰, 이슈수정, Gap체크, 교차검증"
fi
if [ "$LINK_MODE" = true ]; then
  echo "    .cursor/rules/ai-setting.mdc — Cursor project rules (심링크)"
  echo "    .gemini/settings.json     — Gemini CLI workspace settings (심링크)"
else
  echo "    .cursor/rules/ai-setting.mdc — Cursor project rules"
  echo "    .gemini/settings.json     — Gemini CLI workspace settings"
fi
echo "    .codex/config.toml        — Codex CLI 설정 + 프로젝트 로컬 MCP"
if [ "$MCP_ENABLED" = true ]; then
  echo "    .mcp.json                 — Claude Code 프로젝트 로컬 MCP"
fi
echo ""

if [ "$TEMPLATES_COPIED" = true ]; then
  echo "  프로젝트 맞춤 설정:"
  echo "    CLAUDE.md                 — 프로젝트 빌드/실행/도메인 설정"
  echo "    AGENTS.md                 — 아키텍처/스택/코딩 규칙"
  echo "    GEMINI.md                 — Gemini CLI 프로젝트 컨텍스트"
  echo "    .github/copilot-instructions.md — GitHub Copilot 저장소 지침"
  if [ "$CLAUDE_PROFILE" = "team" ]; then
    echo "    .github/pull_request_template.md — 팀용 PR 템플릿"
  fi
  echo "    docs/decisions.md         — 기술 의사결정 기록"
fi
if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ]; then
  echo ""
  echo "  다음 단계 추천:"
  echo "    README.md 또는 프로젝트 manifest/package 파일을 추가한 뒤 init.sh를 다시 실행"
fi
if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "  dry-run: 실제 파일 변경은 적용되지 않았습니다"
fi
if [ "$UPDATE_MODE" = true ]; then
  echo ""
  echo "  update: 공유 자산, Codex 설정, 로컬 MCP만 최신 상태로 갱신했습니다"
fi
echo ""
