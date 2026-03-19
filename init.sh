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

# 모듈 로드를 위한 SCRIPT_DIR 조기 설정
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 모듈 로드
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/validate.sh"
source "$SCRIPT_DIR/lib/fileops.sh"
source "$SCRIPT_DIR/lib/assets.sh"
source "$SCRIPT_DIR/lib/backup.sh"
source "$SCRIPT_DIR/lib/config-detect.sh"
source "$SCRIPT_DIR/lib/doctor.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/mcp.sh"
source "$SCRIPT_DIR/lib/profile.sh"
source "$SCRIPT_DIR/lib/sync.sh"
source "$SCRIPT_DIR/lib/plugin.sh"

# 서브커맨드 전처리
UPDATE_MODE=false
SYNC_MODE=false
PLUGIN_MODE=false
PLUGIN_SUBCOMMAND=""
PLUGIN_NAME=""
PLUGIN_TARGET=""
if [ "${1:-}" = "update" ]; then
  UPDATE_MODE=true
  shift
elif [ "${1:-}" = "sync" ]; then
  SYNC_MODE=true
  shift
elif [ "${1:-}" = "plugin" ]; then
  PLUGIN_MODE=true
  shift
  PLUGIN_SUBCOMMAND="${1:-}"
  shift
  # plugin 서브커맨드 인자 수집
  case "$PLUGIN_SUBCOMMAND" in
    install|uninstall|upgrade)
      PLUGIN_NAME="${1:-}"
      PLUGIN_TARGET="${2:-.}"
      ;;
    list|check-update)
      PLUGIN_TARGET="${1:-.}"
      ;;
  esac
elif [ "${1:-}" = "add-tool" ]; then
  ADD_TOOL_MODE=true
  shift
  ADD_TOOL_NAME="${1:-}"
  ADD_TOOL_TARGET="${2:-.}"
elif [ "${1:-}" = "init" ]; then
  shift
fi

# add-tool 모드는 옵션 파싱 불필요 — 바로 실행
if [ "${ADD_TOOL_MODE:-false}" = true ]; then
  if [ -z "$ADD_TOOL_NAME" ]; then
    echo -e "${RED}오류: add-tool <tool> [target] 형식으로 사용하세요${NC}" >&2
    echo "지원 도구: codex, cursor, gemini, copilot"
    exit 1
  fi
  cmd_add_tool "$ADD_TOOL_NAME" "$ADD_TOOL_TARGET"
  exit 0
fi

# plugin 모드는 옵션 파싱 불필요 — 바로 실행
if [ "$PLUGIN_MODE" = true ]; then
  case "$PLUGIN_SUBCOMMAND" in
    list)
      cmd_plugin_list "$PLUGIN_TARGET"
      ;;
    install)
      if [ -z "$PLUGIN_NAME" ]; then
        echo -e "${RED}오류: plugin install <name> [target] 형식으로 사용하세요${NC}" >&2
        exit 1
      fi
      cmd_plugin_install "$PLUGIN_NAME" "$PLUGIN_TARGET"
      ;;
    uninstall)
      if [ -z "$PLUGIN_NAME" ]; then
        echo -e "${RED}오류: plugin uninstall <name> [target] 형식으로 사용하세요${NC}" >&2
        exit 1
      fi
      cmd_plugin_uninstall "$PLUGIN_NAME" "$PLUGIN_TARGET"
      ;;
    check-update)
      cmd_plugin_check_update "$PLUGIN_TARGET"
      ;;
    upgrade)
      if [ -z "$PLUGIN_NAME" ]; then
        echo -e "${RED}오류: plugin upgrade <name> [target] 형식으로 사용하세요${NC}" >&2
        exit 1
      fi
      cmd_plugin_upgrade "$PLUGIN_NAME" "$PLUGIN_TARGET"
      ;;
    *)
      echo -e "${RED}오류: 알 수 없는 plugin 서브커맨드: ${PLUGIN_SUBCOMMAND}${NC}" >&2
      echo "사용법: ai-setting plugin {list|install|uninstall|check-update|upgrade} [name] [target]"
      exit 1
      ;;
  esac
  exit 0
fi

# 옵션 파싱
DOCTOR_MODE=false
DRY_RUN=false
DIFF_MODE=false
BACKUP_ALL=false
REAPPLY_MODE=false
AUTO_MCP=false
LINK_MODE=false
LINK_DIR_MODE=false
SKIP_AI=false
MCP_ENABLED=true
MCP_PRESETS=()
TOOLS=(claude)
ALL_TOOLS=false
TARGET=""
CLAUDE_PROFILE="standard"
USER_PROJECT_NAME_HINT=""
USER_ARCHETYPE_HINT=""
USER_STACK_HINT=""
USER_MCP_PRESET_SPECIFIED=false
SYNC_MODE_KIND="update"
SYNC_MANIFEST=""
SYNC_CONFLICT_STRATEGY="backup"

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
    --link-dir)
      LINK_MODE=true
      LINK_DIR_MODE=true
      ;;
    --all)
      ALL_TOOLS=true
      TOOLS=(claude codex cursor gemini copilot)
      ;;
    --tools)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --tools 뒤에 값이 필요합니다 (예: claude,cursor)${NC}" >&2
        exit 1
      fi
      IFS=',' read -r -a TOOLS <<< "$2"
      shift
      ;;
    --update)
      UPDATE_MODE=true
      ;;
    --sync-mode)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --sync-mode 뒤에 값이 필요합니다${NC}" >&2
        usage
        exit 1
      fi
      validate_sync_mode "$2"
      SYNC_MODE_KIND="$2"
      shift
      ;;
    --sync-conflict)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}오류: --sync-conflict 뒤에 값이 필요합니다 (overwrite|skip|backup)${NC}" >&2
        exit 1
      fi
      case "$2" in
        overwrite|skip|backup) SYNC_CONFLICT_STRATEGY="$2" ;;
        *) echo -e "${RED}오류: --sync-conflict 값은 overwrite, skip, backup 중 하나여야 합니다${NC}" >&2; exit 1 ;;
      esac
      shift
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
      if [ "$SYNC_MODE" = true ]; then
        if [ -n "$SYNC_MANIFEST" ]; then
          echo -e "${RED}오류: sync manifest 경로는 하나만 지정할 수 있습니다${NC}" >&2
          usage
          exit 1
        fi
        SYNC_MANIFEST="$1"
      else
        if [ -n "$TARGET" ]; then
          echo -e "${RED}오류: 프로젝트 경로는 하나만 지정할 수 있습니다${NC}" >&2
          usage
          exit 1
        fi
        TARGET="$1"
      fi
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
if [ "$SYNC_MODE" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
  echo -e "${RED}오류: sync 명령은 --doctor 또는 --diff와 함께 사용할 수 없습니다${NC}" >&2
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

if [ "$SYNC_MODE" = true ]; then
  SYNC_MANIFEST="${SYNC_MANIFEST:-$SCRIPT_DIR/projects.manifest}"
  if run_sync_manifest "$SYNC_MANIFEST"; then
    exit 0
  else
    exit 1
  fi
fi

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
  echo -e "  hooks(protect-files, block-dangerous-commands, async-test)가 정상 동작하려면 jq가 필요합니다."
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
      echo "  ✅ strict profile 심링크 적용 예정 (settings 1개, hooks 6개, agents 4개, skills 5개)"
    else
      echo "  ✅ strict profile 적용 예정 (settings 1개, hooks 6개, agents 4개, skills 5개)"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ strict profile 심링크 적용됨 (settings 1개, hooks 6개, agents 4개, skills 5개)"
    else
      echo "  ✅ strict profile 적용됨 (settings 1개, hooks 6개, agents 4개, skills 5개)"
    fi
  fi
elif [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ team profile 심링크 적용 예정 (settings 1개, hooks 7개, agents 4개, skills 5개)"
    else
      echo "  ✅ team profile 적용 예정 (settings 1개, hooks 7개, agents 4개, skills 5개)"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ team profile 심링크 적용됨 (settings 1개, hooks 7개, agents 4개, skills 5개)"
    else
      echo "  ✅ team profile 적용됨 (settings 1개, hooks 7개, agents 4개, skills 5개)"
    fi
  fi
else
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ standard profile 심링크 적용 예정 (settings 1개, hooks 5개, agents 4개, skills 5개)"
    else
      echo "  ✅ standard profile 적용 예정 (settings 1개, hooks 5개, agents 4개, skills 5개)"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "  ✅ standard profile 심링크 적용됨 (settings 1개, hooks 5개, agents 4개, skills 5개)"
    else
      echo "  ✅ standard profile 적용됨 (settings 1개, hooks 5개, agents 4개, skills 5개)"
    fi
  fi
fi

# ============================================================
# 2단계: 추가 AI 도구 설정 복사
# ============================================================
if tool_enabled "cursor" || tool_enabled "gemini" || tool_enabled "copilot"; then
  echo -e "${GREEN}[2/7]${NC} 추가 AI 도구 설정 복사"

  if tool_enabled "cursor"; then
    copy_cursor_assets
    echo "  ✅ Cursor rule 적용됨 (.cursor/rules/)"
  fi

  if tool_enabled "gemini"; then
    copy_gemini_assets
    echo "  ✅ Gemini settings 적용됨 (.gemini/settings.json)"
  fi

  if tool_enabled "copilot"; then
    copy_copilot_assets
    echo "  ✅ Copilot instructions 적용됨 (.github/copilot-instructions.md)"
  fi
else
  echo -e "${GREEN}[2/7]${NC} 추가 AI 도구 — 건너뜀 (--tools 또는 --all로 추가 가능)"
fi

# ============================================================
# 3단계: Codex 설정 복사
# ============================================================
if tool_enabled "codex"; then
  echo -e "${GREEN}[3/7]${NC} Codex CLI 설정 복사 (.codex/)"
  copy_codex_assets
  echo "  ✅ config.toml"
else
  echo -e "${GREEN}[3/7]${NC} Codex CLI — 건너뜀 (add-tool codex 로 추가 가능)"
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

  if tool_enabled "codex"; then
    for preset in "${MCP_PRESETS[@]}"; do
      append_codex_mcp_preset "$preset" "$TARGET/.codex/config.toml"
    done
    echo "  ✅ Codex MCP preset 적용됨 ($MCP_PRESET_LABEL)"
  fi
  write_claude_mcp_config "$TARGET/.mcp.json"
  echo "  ✅ Claude MCP config 생성됨 (.mcp.json)"
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

if tool_enabled "gemini"; then
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/GEMINI.md" ]; then
    backup_existing_path "$TARGET/GEMINI.md" "GEMINI.md"
    run_copy "$SCRIPT_DIR/templates/GEMINI.md.template" "$TARGET/GEMINI.md"
    echo "  ✅ GEMINI.md 재생성됨"
    TEMPLATES_COPIED=true
  elif [ ! -f "$TARGET/GEMINI.md" ]; then
    run_copy "$SCRIPT_DIR/templates/GEMINI.md.template" "$TARGET/GEMINI.md"
    echo "  ✅ GEMINI.md 생성됨"
    TEMPLATES_COPIED=true
  else
    echo -e "  ${YELLOW}⚠ GEMINI.md 이미 존재 — 건너뜀${NC}"
  fi
fi

if tool_enabled "copilot"; then
  run_mkdir_p "$TARGET/.github"
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/.github/copilot-instructions.md" ]; then
    backup_existing_path "$TARGET/.github/copilot-instructions.md" ".github/copilot-instructions.md"
    run_copy "$SCRIPT_DIR/templates/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"
    echo "  ✅ .github/copilot-instructions.md 재생성됨"
    TEMPLATES_COPIED=true
  elif [ ! -f "$TARGET/.github/copilot-instructions.md" ]; then
    run_copy "$SCRIPT_DIR/templates/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"
    echo "  ✅ .github/copilot-instructions.md 생성됨"
    TEMPLATES_COPIED=true
  else
    echo -e "  ${YELLOW}⚠ .github/copilot-instructions.md 이미 존재 — 건너뜀${NC}"
  fi
fi

if tool_enabled "codex"; then
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/CODEX.md" ]; then
    backup_existing_path "$TARGET/CODEX.md" "CODEX.md"
    run_copy "$SCRIPT_DIR/templates/CODEX.md.template" "$TARGET/CODEX.md"
    echo "  ✅ CODEX.md 재생성됨"
    TEMPLATES_COPIED=true
  elif [ ! -f "$TARGET/CODEX.md" ]; then
    run_copy "$SCRIPT_DIR/templates/CODEX.md.template" "$TARGET/CODEX.md"
    echo "  ✅ CODEX.md 생성됨"
    TEMPLATES_COPIED=true
  else
    echo -e "  ${YELLOW}⚠ CODEX.md 이미 존재 — 건너뜀${NC}"
  fi
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

  run_mkdir_p "$TARGET/.ai-setting"
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/.ai-setting/team-webhook.json" ]; then
    backup_existing_path "$TARGET/.ai-setting/team-webhook.json" ".ai-setting/team-webhook.json"
    run_copy "$SCRIPT_DIR/templates/team-webhook.json.template" "$TARGET/.ai-setting/team-webhook.json"
    if [ "$DRY_RUN" = true ]; then
      echo "  ✅ .ai-setting/team-webhook.json 재생성 예정"
    else
      echo "  ✅ .ai-setting/team-webhook.json 재생성됨"
    fi
  elif [ ! -f "$TARGET/.ai-setting/team-webhook.json" ]; then
    run_copy "$SCRIPT_DIR/templates/team-webhook.json.template" "$TARGET/.ai-setting/team-webhook.json"
    if [ "$DRY_RUN" = true ]; then
      echo "  ✅ .ai-setting/team-webhook.json 생성 예정"
    else
      echo "  ✅ .ai-setting/team-webhook.json 생성됨"
    fi
  else
    echo -e "  ${YELLOW}⚠ .ai-setting/team-webhook.json 이미 존재 — 건너뜀${NC}"
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
3. .github/copilot-instructions.md가 있으면 GitHub Copilot이 바로 참고할 수 있도록 프로젝트 요약, build/test/lint 명령, 코드 스타일, 금지 패턴을 간결하게 정리해줘.
4. CODEX.md가 있으면 [대괄호] 부분을 채우고, Codex CLI에서 참고할 핵심 지침이 CLAUDE.md / AGENTS.md와 모순되지 않게 정리해줘.
${AI_SKILL_TASK}
6. .github/pull_request_template.md가 있으면 팀이 바로 쓸 수 있도록 유지하고, placeholder가 있다면 실제 검증/리스크 항목에 맞게 다듬어줘.
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
    echo "    .claude/settings.json     — strict workflow hooks + branch 보호 (심링크)"
  else
    echo "    .claude/settings.json     — strict workflow hooks + branch 보호"
  fi
  echo "    .claude/hooks/            — 파일 보호 + 위험 명령 차단 + async test + session context + compact backup + main/master 보호"
  echo "    .claude/agents/           — 보안 리뷰, 설계 검증, 테스트 작성, 리서치"
  echo "    .claude/skills/           — 배포, 리뷰, 이슈수정, Gap체크, 교차검증"
elif [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "    .claude/settings.json     — team workflow hooks + branch 보호 (심링크)"
  else
    echo "    .claude/settings.json     — team workflow hooks + branch 보호"
  fi
  echo "    .claude/hooks/            — 파일 보호 + 위험 명령 차단 + async test + session context + compact backup + main/master 보호 + team webhook"
  echo "    .claude/agents/           — 보안 리뷰, 설계 검증, 테스트 작성, 리서치"
  echo "    .claude/skills/           — 배포, 리뷰, 이슈수정, Gap체크, 교차검증"
else
  if [ "$LINK_MODE" = true ]; then
    echo "    .claude/settings.json     — standard workflow hooks (심링크)"
  else
    echo "    .claude/settings.json     — standard workflow hooks (포맷터, 파일보호, 명령차단, async test, 알림, 종료검사, session context, compact backup)"
  fi
  echo "    .claude/hooks/            — 파일 보호 + 위험 명령 차단 + async test + session context + compact backup"
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
  echo "    CODEX.md                  — Codex CLI 프로젝트 컨텍스트"
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
