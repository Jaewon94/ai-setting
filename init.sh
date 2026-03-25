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
source "$SCRIPT_DIR/lib/cli.sh"
source "$SCRIPT_DIR/lib/deps.sh"
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

# i18n: locale 로드 (--lang 플래그보다 먼저 기본값 로드, 이후 재로드 가능)
load_locale "$SCRIPT_DIR"
refresh_template_dir

run_with_timeout() {
  local timeout_seconds="$1"
  shift

  "$@" &
  local command_pid=$!

  (
    sleep "$timeout_seconds"
    if kill -0 "$command_pid" 2>/dev/null; then
      kill -TERM "$command_pid" 2>/dev/null || true
      sleep 1
      kill -0 "$command_pid" 2>/dev/null && kill -KILL "$command_pid" 2>/dev/null || true
    fi
  ) &
  local watcher_pid=$!

  wait "$command_pid"
  local status=$?

  kill "$watcher_pid" 2>/dev/null || true
  wait "$watcher_pid" 2>/dev/null || true

  if [ "$status" -eq 143 ] || [ "$status" -eq 137 ]; then
    return 124
  fi

  return "$status"
}

reset_cli_state
preprocess_subcommand "$@"
run_preparsed_mode_if_needed
parse_cli_args "${CLI_ARGS[@]}"
validate_cli_mode_combinations

if [ "$SYNC_MODE" = true ]; then
  SYNC_MANIFEST="${SYNC_MANIFEST:-$SCRIPT_DIR/projects.manifest}"
  if run_sync_manifest "$SYNC_MANIFEST"; then
    exit 0
  else
    exit 1
  fi
fi

prepare_target_context "${TARGET:-.}"

if [ "$UPDATE_MODE" = true ]; then
  SKIP_AI=true
fi

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

echo -e "${CYAN}${MSG_INIT_TITLE}${NC}"
printf "${MSG_INIT_SOURCE}\n" "$SCRIPT_DIR"
printf "${MSG_INIT_TARGET}\n" "$TARGET"
printf "${MSG_INIT_CLAUDE_PROFILE}\n" "$CLAUDE_PROFILE"
if [ "$LINK_MODE" = true ]; then
  echo -e "$MSG_INIT_ASSET_SYMLINK"
else
  echo -e "$MSG_INIT_ASSET_COPY"
fi
if [ "$MERGE_SETTINGS" = true ]; then
  echo -e "$MSG_INIT_SETTINGS_MERGE"
fi
printf "${MSG_INIT_MCP_PRESET}\n" "$MCP_PRESET_LABEL"
printf "${MSG_INIT_MCP_RECOMMENDED}\n" "$RECOMMENDED_MCP_PRESET_LABEL"
printf "${MSG_INIT_PROJECT_NAME}\n" "$PROJECT_NAME"
printf "${MSG_INIT_CONTEXT_MODE}\n" "$PROJECT_CONTEXT_MODE"
printf "${MSG_INIT_PROJECT_TYPE}\n" "$PROJECT_ARCHETYPE"
printf "${MSG_INIT_MAIN_STACK}\n" "$PROJECT_STACK"
if [ "$HAS_USER_GUIDANCE" = true ]; then
  printf "${MSG_INIT_USER_HINTS}\n" "${USER_PROJECT_NAME_HINT:-none}" "${USER_ARCHETYPE_HINT:-none}" "${USER_STACK_HINT:-none}"
fi
if [ "$AUTO_MCP" = true ]; then
  if [ "$AUTO_MCP_APPLIED" = true ]; then
    echo -e "$MSG_INIT_AUTOMCP_ON"
  else
    echo -e "$MSG_INIT_AUTOMCP_PREEMPTED"
  fi
fi
if [ "$UPDATE_MODE" = true ]; then
  echo -e "$MSG_INIT_MODE_UPDATE"
fi
if [ "$DRY_RUN" = true ]; then
  echo -e "$MSG_INIT_MODE_DRYRUN"
fi
if [ "$BACKUP_ALL" = true ]; then
  echo -e "$MSG_INIT_MODE_BACKUP"
fi
if [ "$REAPPLY_MODE" = true ]; then
  echo -e "$MSG_INIT_MODE_REAPPLY"
fi
echo ""

ensure_jq_dependency

if [ "$BACKUP_ALL" = true ]; then
  perform_backup_all
fi

# ============================================================
# 1단계: Claude Code 설정 복사
# ============================================================
echo -e "${GREEN}${MSG_INIT_STEP1}${NC}"

if [ -d "$TARGET/.claude" ]; then
  backup_existing_path "$TARGET/.claude" ".claude/"
fi

cleanup_managed_claude_assets "$MERGE_SETTINGS"
copy_claude_profile_assets

if [ "$CLAUDE_PROFILE" = "minimal" ]; then
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_MINIMAL_LINK_PLANNED"
    else
      echo "$MSG_INIT_STEP1_MINIMAL_PLANNED"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_MINIMAL_LINK_DONE"
    else
      echo "$MSG_INIT_STEP1_MINIMAL_DONE"
    fi
  fi
elif [ "$CLAUDE_PROFILE" = "strict" ]; then
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_STRICT_LINK_PLANNED"
    else
      echo "$MSG_INIT_STEP1_STRICT_PLANNED"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_STRICT_LINK_DONE"
    else
      echo "$MSG_INIT_STEP1_STRICT_DONE"
    fi
  fi
elif [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_TEAM_LINK_PLANNED"
    else
      echo "$MSG_INIT_STEP1_TEAM_PLANNED"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_TEAM_LINK_DONE"
    else
      echo "$MSG_INIT_STEP1_TEAM_DONE"
    fi
  fi
else
  if [ "$DRY_RUN" = true ]; then
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_STANDARD_LINK_PLANNED"
    else
      echo "$MSG_INIT_STEP1_STANDARD_PLANNED"
    fi
  else
    if [ "$LINK_MODE" = true ]; then
      echo "$MSG_INIT_STEP1_STANDARD_LINK_DONE"
    else
      echo "$MSG_INIT_STEP1_STANDARD_DONE"
    fi
  fi
fi

# ============================================================
# 2단계: 추가 AI 도구 설정 복사
# ============================================================
if tool_enabled "cursor" || tool_enabled "gemini" || tool_enabled "copilot"; then
  echo -e "${GREEN}${MSG_INIT_STEP2}${NC}"

  if tool_enabled "cursor"; then
    copy_cursor_assets
    echo "$MSG_INIT_STEP2_CURSOR"
  fi

  if tool_enabled "gemini"; then
    copy_gemini_assets
    echo "$MSG_INIT_STEP2_GEMINI"
  fi

  if tool_enabled "copilot"; then
    copy_copilot_assets
    echo "$MSG_INIT_STEP2_COPILOT"
  fi
else
  echo -e "${GREEN}${MSG_INIT_STEP2_SKIP}${NC}"
fi

# ============================================================
# 3단계: Codex 설정 복사
# ============================================================
if tool_enabled "codex"; then
  echo -e "${GREEN}${MSG_INIT_STEP3}${NC}"
  copy_codex_assets
  echo "$MSG_INIT_STEP3_OK"
else
  echo -e "${GREEN}${MSG_INIT_STEP3_SKIP}${NC}"
fi

# ============================================================
# 4단계: 프로젝트 로컬 MCP preset 생성
# ============================================================
echo -e "${GREEN}${MSG_INIT_STEP4}${NC}"

if [ "$MCP_ENABLED" = false ]; then
  echo -e "  ${YELLOW}${MSG_INIT_STEP4_NOMCP}${NC}"
else
  if [ -f "$TARGET/.mcp.json" ]; then
    backup_existing_path "$TARGET/.mcp.json" ".mcp.json"
  fi
  if [ -f "$TARGET/.mcp.notes.md" ]; then
    backup_existing_path "$TARGET/.mcp.notes.md" ".mcp.notes.md"
  fi

  if tool_enabled "codex"; then
    for preset in "${MCP_PRESETS[@]}"; do
      append_codex_mcp_preset "$preset" "$TARGET/.codex/config.toml"
    done
    printf "$MSG_INIT_STEP4_CODEX_MCP\n" "$MCP_PRESET_LABEL"
  fi
  write_claude_mcp_config "$TARGET/.mcp.json"
  write_mcp_notes "$TARGET/.mcp.notes.md"
  echo "$MSG_INIT_STEP4_CLAUDE_MCP"
  check_mcp_commands
fi

# ============================================================
# 5단계: 프로젝트 문서 템플릿 복사
# ============================================================
echo -e "${GREEN}${MSG_INIT_STEP5}${NC}"

TEMPLATES_COPIED=false

if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/BEHAVIORAL_CORE.md" ]; then
  backup_existing_path "$TARGET/BEHAVIORAL_CORE.md" "BEHAVIORAL_CORE.md"
  run_copy "$TEMPLATE_DIR/BEHAVIORAL_CORE.md.template" "$TARGET/BEHAVIORAL_CORE.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_BEHAVIORAL_REAPPLY_PLANNED"
  else
    echo "$MSG_INIT_BEHAVIORAL_REAPPLY_DONE"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/BEHAVIORAL_CORE.md" ]; then
  run_copy "$TEMPLATE_DIR/BEHAVIORAL_CORE.md.template" "$TARGET/BEHAVIORAL_CORE.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_BEHAVIORAL_PLANNED"
  else
    echo "$MSG_INIT_BEHAVIORAL_DONE"
  fi
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}${MSG_INIT_BEHAVIORAL_SKIP}${NC}"
fi

if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/CLAUDE.md" ]; then
  backup_existing_path "$TARGET/CLAUDE.md" "CLAUDE.md"
  run_copy "$TEMPLATE_DIR/CLAUDE.md.template" "$TARGET/CLAUDE.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_CLAUDEMD_REAPPLY_PLANNED"
  else
    echo "$MSG_INIT_CLAUDEMD_REAPPLY_DONE"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/CLAUDE.md" ]; then
  run_copy "$TEMPLATE_DIR/CLAUDE.md.template" "$TARGET/CLAUDE.md"
  echo "$MSG_INIT_CLAUDEMD_DONE"
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}${MSG_INIT_CLAUDEMD_SKIP}${NC}"
fi

# archetype partial 삽입 (마커 기반 중복 방지, 사용자 커스텀 보호)
ARCHETYPE_PARTIAL="$TEMPLATE_DIR/archetype/${PROJECT_ARCHETYPE}.partial.md"
ARCHETYPE_MARKER="<!-- ai-setting:archetype-rules -->"
if [ -f "$ARCHETYPE_PARTIAL" ] && [ -f "$TARGET/CLAUDE.md" ] && [ "$DRY_RUN" != true ]; then
  if grep -qF "$ARCHETYPE_MARKER" "$TARGET/CLAUDE.md" 2>/dev/null; then
    # 마커가 있으면 → 기존 마커 블록의 언어를 감지하여 동일 locale로 교체
    _use_partial="$ARCHETYPE_PARTIAL"
    _ko_heading="$(head -1 "$SCRIPT_DIR/templates/ko/archetype/${PROJECT_ARCHETYPE}.partial.md" 2>/dev/null)"
    if [ -n "$_ko_heading" ] && sed -n "/$ARCHETYPE_MARKER/,\$p" "$TARGET/CLAUDE.md" 2>/dev/null | grep -qF "$_ko_heading"; then
      _use_partial="$SCRIPT_DIR/templates/ko/archetype/${PROJECT_ARCHETYPE}.partial.md"
    fi
    truncate_file_from_marker "$TARGET/CLAUDE.md" "$ARCHETYPE_MARKER"
    echo "" >> "$TARGET/CLAUDE.md"
    echo "$ARCHETYPE_MARKER" >> "$TARGET/CLAUDE.md"
    cat "$_use_partial" >> "$TARGET/CLAUDE.md"
    printf "$MSG_INIT_ARCHETYPE_DONE\n" "$PROJECT_ARCHETYPE"
  else
    # 마커가 없으면 → 기존 archetype heading이 있는지 확인 (en/ko 양쪽)
    _has_existing=false
    for _check_partial in "$SCRIPT_DIR/templates/en/archetype/${PROJECT_ARCHETYPE}.partial.md" "$SCRIPT_DIR/templates/ko/archetype/${PROJECT_ARCHETYPE}.partial.md"; do
      if [ -f "$_check_partial" ]; then
        _heading="$(head -1 "$_check_partial")"
        if [ -n "$_heading" ] && grep -qF "$_heading" "$TARGET/CLAUDE.md" 2>/dev/null; then
          _has_existing=true
          break
        fi
      fi
    done

    if [ "$_has_existing" = true ]; then
      # 사용자가 작성한 archetype 섹션이 이미 있음 → 건드리지 않음
      :
    else
      # 아무 것도 없음 → 신규 삽입
      echo "" >> "$TARGET/CLAUDE.md"
      echo "$ARCHETYPE_MARKER" >> "$TARGET/CLAUDE.md"
      cat "$ARCHETYPE_PARTIAL" >> "$TARGET/CLAUDE.md"
      printf "$MSG_INIT_ARCHETYPE_DONE\n" "$PROJECT_ARCHETYPE"
    fi
  fi
elif [ -f "$ARCHETYPE_PARTIAL" ] && [ "$DRY_RUN" = true ]; then
  dry_run_note "$(printf "$MSG_INIT_ARCHETYPE_DRYRUN" "$PROJECT_ARCHETYPE")"
fi

if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/AGENTS.md" ]; then
  backup_existing_path "$TARGET/AGENTS.md" "AGENTS.md"
  run_copy "$TEMPLATE_DIR/AGENTS.md.template" "$TARGET/AGENTS.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_AGENTSMD_REAPPLY_PLANNED"
  else
    echo "$MSG_INIT_AGENTSMD_REAPPLY_DONE"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/AGENTS.md" ]; then
  run_copy "$TEMPLATE_DIR/AGENTS.md.template" "$TARGET/AGENTS.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_AGENTSMD_PLANNED"
  else
    echo "$MSG_INIT_AGENTSMD_DONE"
  fi
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}${MSG_INIT_AGENTSMD_SKIP}${NC}"
fi

if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/docs/research-notes.md" ]; then
  backup_existing_path "$TARGET/docs/research-notes.md" "docs/research-notes.md"
  run_mkdir_p "$TARGET/docs"
  run_copy "$TEMPLATE_DIR/research-notes.md.template" "$TARGET/docs/research-notes.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_RESEARCH_REAPPLY_PLANNED"
  else
    echo "$MSG_INIT_RESEARCH_REAPPLY_DONE"
  fi
  TEMPLATES_COPIED=true
elif [ ! -f "$TARGET/docs/research-notes.md" ]; then
  run_mkdir_p "$TARGET/docs"
  run_copy "$TEMPLATE_DIR/research-notes.md.template" "$TARGET/docs/research-notes.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_RESEARCH_PLANNED"
  else
    echo "$MSG_INIT_RESEARCH_DONE"
  fi
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}${MSG_INIT_RESEARCH_SKIP}${NC}"
fi

if tool_enabled "gemini"; then
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/GEMINI.md" ]; then
    backup_existing_path "$TARGET/GEMINI.md" "GEMINI.md"
    run_copy "$TEMPLATE_DIR/GEMINI.md.template" "$TARGET/GEMINI.md"
    echo "$MSG_INIT_GEMINIMD_REAPPLY_DONE"
    TEMPLATES_COPIED=true
  elif [ ! -f "$TARGET/GEMINI.md" ]; then
    run_copy "$TEMPLATE_DIR/GEMINI.md.template" "$TARGET/GEMINI.md"
    echo "$MSG_INIT_GEMINIMD_DONE"
    TEMPLATES_COPIED=true
  else
    echo -e "  ${YELLOW}${MSG_INIT_GEMINIMD_SKIP}${NC}"
  fi
fi

if tool_enabled "copilot"; then
  run_mkdir_p "$TARGET/.github"
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/.github/copilot-instructions.md" ]; then
    backup_existing_path "$TARGET/.github/copilot-instructions.md" ".github/copilot-instructions.md"
    run_copy "$TEMPLATE_DIR/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"
    echo "$MSG_INIT_COPILOTMD_REAPPLY_DONE"
    TEMPLATES_COPIED=true
  elif [ ! -f "$TARGET/.github/copilot-instructions.md" ]; then
    run_copy "$TEMPLATE_DIR/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"
    echo "$MSG_INIT_COPILOTMD_DONE"
    TEMPLATES_COPIED=true
  else
    echo -e "  ${YELLOW}${MSG_INIT_COPILOTMD_SKIP}${NC}"
  fi
fi


if [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/.github/pull_request_template.md" ]; then
    backup_existing_path "$TARGET/.github/pull_request_template.md" ".github/pull_request_template.md"
    run_copy "$TEMPLATE_DIR/pull_request_template.md.template" "$TARGET/.github/pull_request_template.md"
    if [ "$DRY_RUN" = true ]; then
      echo "$MSG_INIT_PR_TEMPLATE_REAPPLY_PLANNED"
    else
      echo "$MSG_INIT_PR_TEMPLATE_REAPPLY_DONE"
    fi
  elif [ ! -f "$TARGET/.github/pull_request_template.md" ]; then
    run_copy "$TEMPLATE_DIR/pull_request_template.md.template" "$TARGET/.github/pull_request_template.md"
    if [ "$DRY_RUN" = true ]; then
      echo "$MSG_INIT_PR_TEMPLATE_PLANNED"
    else
      echo "$MSG_INIT_PR_TEMPLATE_DONE"
    fi
  else
    echo -e "  ${YELLOW}${MSG_INIT_PR_TEMPLATE_SKIP}${NC}"
  fi

  run_mkdir_p "$TARGET/.ai-setting"
  if [ "$REAPPLY_MODE" = true ] && [ -f "$TARGET/.ai-setting/team-webhook.json" ]; then
    backup_existing_path "$TARGET/.ai-setting/team-webhook.json" ".ai-setting/team-webhook.json"
    run_copy "$TEMPLATE_DIR/team-webhook.json.template" "$TARGET/.ai-setting/team-webhook.json"
    if [ "$DRY_RUN" = true ]; then
      echo "$MSG_INIT_WEBHOOK_REAPPLY_PLANNED"
    else
      echo "$MSG_INIT_WEBHOOK_REAPPLY_DONE"
    fi
  elif [ ! -f "$TARGET/.ai-setting/team-webhook.json" ]; then
    run_copy "$TEMPLATE_DIR/team-webhook.json.template" "$TARGET/.ai-setting/team-webhook.json"
    if [ "$DRY_RUN" = true ]; then
      echo "$MSG_INIT_WEBHOOK_PLANNED"
    else
      echo "$MSG_INIT_WEBHOOK_DONE"
    fi
  else
    echo -e "  ${YELLOW}${MSG_INIT_WEBHOOK_SKIP}${NC}"
  fi
fi

run_mkdir_p "$TARGET/docs"
if [ ! -f "$TARGET/docs/decisions.md" ]; then
  run_copy "$TEMPLATE_DIR/decisions.md.template" "$TARGET/docs/decisions.md"
  if [ "$DRY_RUN" = true ]; then
    echo "$MSG_INIT_DECISIONS_PLANNED"
  else
    echo "$MSG_INIT_DECISIONS_DONE"
  fi
else
  if [ "$REAPPLY_MODE" = true ]; then
    echo -e "  ${YELLOW}${MSG_INIT_DECISIONS_REAPPLY_SKIP}${NC}"
  else
    echo -e "  ${YELLOW}${MSG_INIT_DECISIONS_SKIP}${NC}"
  fi
fi

# .gitignore에 런타임 데이터 패턴 추가 (ISS-015)
if [ "$DRY_RUN" != true ]; then
  gitignore_path="$TARGET/.gitignore"
  gitignore_patterns=(".claude/context/" ".claude.backup.*")
  for pat in "${gitignore_patterns[@]}"; do
    if [ ! -f "$gitignore_path" ] || ! grep -qF "$pat" "$gitignore_path" 2>/dev/null; then
      echo "$pat" >> "$gitignore_path"
    fi
  done
fi

# ============================================================
# 6단계: AI로 템플릿 자동 채우기 (Claude Code → Codex → 수동)
# ============================================================
echo -e "${GREEN}${MSG_INIT_STEP6}${NC}"

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

# --skip-ai여도 감지된 프로젝트 정보로 기본 플레이스홀더를 치환하는 함수
fill_rule_based_placeholders() {
  local test_backend_cmd="" test_frontend_cmd="" lint_cmd="" deploy_backend_cmd=""
  local deploy_frontend_cmd="" test_cmd="" deploy_cmd=""

  # archetype + stack 기반 명령 매핑
  case "$PROJECT_ARCHETYPE" in
    backend-api|worker-batch|data-automation)
      case "$PROJECT_STACK" in
        *python*|*fastapi*|*django*|*flask*)
          test_backend_cmd="pytest -q"
          lint_cmd="ruff check ."
          if [ -f "$TARGET/uv.lock" ] || [ -f "$TARGET/backend/uv.lock" ]; then
            test_backend_cmd="uv run pytest -q"
            lint_cmd="uv run ruff check ."
          fi
          deploy_backend_cmd="# TODO: 프로젝트에 맞는 배포 명령을 설정하세요"
          ;;
        *go*)
          test_backend_cmd="go test ./..."
          lint_cmd="golangci-lint run"
          ;;
        *node*|*express*|*nest*)
          test_backend_cmd="npm test"
          lint_cmd="npx eslint ."
          ;;
      esac
      ;;
    frontend-web)
      case "$PROJECT_STACK" in
        *next*|*react*|*vue*|*svelte*)
          test_frontend_cmd="npm test"
          lint_cmd="npx eslint ."
          deploy_frontend_cmd="npm run build"
          ;;
      esac
      ;;
    cli-tool)
      case "$PROJECT_STACK" in
        *python*) test_cmd="pytest -q"; lint_cmd="ruff check ." ;;
        *go*) test_cmd="go test ./..."; lint_cmd="golangci-lint run" ;;
        *node*) test_cmd="npm test"; lint_cmd="npx eslint ." ;;
      esac
      ;;
  esac

  # monorepo 구조 감지: backend/ + frontend/ 분리
  if [ -d "$TARGET/backend" ] && [ -d "$TARGET/frontend" ]; then
    if [ -z "$test_backend_cmd" ] && [ -f "$TARGET/backend/pyproject.toml" ]; then
      test_backend_cmd="cd backend && pytest -q"
      if [ -f "$TARGET/backend/uv.lock" ]; then
        test_backend_cmd="cd backend && uv run pytest -q"
      fi
    fi
    if [ -z "$test_frontend_cmd" ] && [ -f "$TARGET/frontend/package.json" ]; then
      test_frontend_cmd="cd frontend && npm test"
    fi
  fi

  # 기본값 설정
  test_cmd="${test_cmd:-${test_backend_cmd:-${test_frontend_cmd:-"# TODO: 테스트 명령을 설정하세요"}}}"
  lint_cmd="${lint_cmd:-"# TODO: 린트 명령을 설정하세요"}"
  deploy_backend_cmd="${deploy_backend_cmd:-"# TODO: 백엔드 배포 명령을 설정하세요"}"
  deploy_frontend_cmd="${deploy_frontend_cmd:-"# TODO: 프론트엔드 배포 명령을 설정하세요"}"
  deploy_cmd="${deploy_cmd:-"# TODO: 배포 명령을 설정하세요"}"

  # 치환 대상 파일들
  local files_to_process=()
  [ -f "$TARGET/docs/decisions.md" ] && files_to_process+=("$TARGET/docs/decisions.md")
  [ -f "$TARGET/docs/research-notes.md" ] && files_to_process+=("$TARGET/docs/research-notes.md")

  # skills 디렉토리의 SKILL.md 파일들
  if [ -d "$TARGET/.claude/skills" ]; then
    while IFS= read -r -d '' f; do
      files_to_process+=("$f")
    done < <(find "$TARGET/.claude/skills" -name "SKILL.md" -print0 2>/dev/null)
  fi

  local replaced=0
  local file

  for file in "${files_to_process[@]}"; do
    local changed=false

    # [프로젝트명] 치환
    if grep -q '\[프로젝트명\]' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "[프로젝트명]" "$PROJECT_NAME"
      changed=true
    fi

    # {{...}} 플레이스홀더 치환
    if grep -q '{{TEST_BACKEND_CMD}}' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "{{TEST_BACKEND_CMD}}" "$test_backend_cmd"
      changed=true
    fi
    if grep -q '{{TEST_FRONTEND_CMD}}' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "{{TEST_FRONTEND_CMD}}" "$test_frontend_cmd"
      changed=true
    fi
    if grep -q '{{TEST_CMD}}' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "{{TEST_CMD}}" "$test_cmd"
      changed=true
    fi
    if grep -q '{{LINT_CMD}}' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "{{LINT_CMD}}" "$lint_cmd"
      changed=true
    fi
    if grep -q '{{DEPLOY_BACKEND_CMD}}' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "{{DEPLOY_BACKEND_CMD}}" "$deploy_backend_cmd"
      changed=true
    fi
    if grep -q '{{DEPLOY_FRONTEND_CMD}}' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "{{DEPLOY_FRONTEND_CMD}}" "$deploy_frontend_cmd"
      changed=true
    fi
    if grep -q '{{DEPLOY_CMD}}' "$file" 2>/dev/null; then
      replace_literal_in_file "$file" "{{DEPLOY_CMD}}" "$deploy_cmd"
      changed=true
    fi

    if [ "$changed" = true ]; then
      replaced=$((replaced + 1))
    fi
  done

  if [ "$replaced" -gt 0 ]; then
    printf "$MSG_INIT_AI_RULE_BASED_OK\n" "$replaced"
  fi
}

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
${AI_SKILL_TASK}
5. docs/research-notes.md가 있으면 조사 기록 템플릿을 프로젝트에 맞게 정리해줘. 실제로 확인한 로컬 문서/설정/코드 근거가 있으면 출처와 핵심 내용을 채우고, 외부 문서 확인이 없었다면 placeholder는 TODO 형태로 남겨도 돼.
6. .github/pull_request_template.md가 있으면 팀이 바로 쓸 수 있도록 유지하고, placeholder가 있다면 실제 검증/리스크 항목에 맞게 다듬어줘.
7. docs/decisions.md를 새로 채우거나 수정한다면 관련 조사 항목(R-xxx)과 근거 문서를 함께 연결해줘.
8. 문서와 구현이 충돌하면 CLAUDE.md 끝에 '## Detected Mismatches' 섹션을 추가하고, 확인한 불일치를 짧게 정리해. 충돌이 없으면 이 섹션은 만들지 마.
9. 확실하지 않은 내용은 사실처럼 단정하지 말고 TODO, 가정, 예정으로 표시해.
EOF
)

if [ "$UPDATE_MODE" = true ]; then
  echo -e "  ${YELLOW}${MSG_INIT_AI_UPDATE_SKIP}${NC}"
elif [ "$SKIP_AI" = true ]; then
  echo -e "  ${YELLOW}${MSG_INIT_AI_SKIPAI}${NC}"
  # rule-based 치환: AI 없이도 감지된 프로젝트 정보로 플레이스홀더 교체
  fill_rule_based_placeholders
elif [ "$DRY_RUN" = true ]; then
  echo -e "  ${YELLOW}${MSG_INIT_AI_DRYRUN_SKIP}${NC}"
elif [ "$PROJECT_CONTEXT_MODE" = "blank-start" ] && [ "$HAS_USER_GUIDANCE" = false ]; then
  echo "  mode: ${PROJECT_CONTEXT_MODE} (${PROJECT_CONTEXT_REASON})"
  echo -e "  ${YELLOW}${MSG_INIT_AI_BLANKSTART_SKIP}${NC}"
  echo "  $MSG_INIT_AI_BLANKSTART_HINT"
elif [ "$TEMPLATES_COPIED" = false ]; then
  echo -e "  ${YELLOW}${MSG_INIT_AI_NO_TEMPLATES}${NC}"
else
  AI_SUCCESS=false
  CLAUDE_TIMEOUT_SECONDS="${AI_SETTING_CLAUDE_TIMEOUT_SEC:-20}"
  echo "  mode: ${PROJECT_CONTEXT_MODE} (${PROJECT_CONTEXT_REASON})"
  if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ] && [ "$HAS_USER_GUIDANCE" = true ]; then
    echo "  $MSG_INIT_AI_GUIDED_BLANKSTART"
  fi
  echo "  archetype: ${PROJECT_ARCHETYPE} (${PROJECT_ARCHETYPE_REASON})"
  echo "  stack: ${PROJECT_STACK} [${PROJECT_STACK_SIGNALS}]"
  if [ "$HAS_USER_GUIDANCE" = true ]; then
    printf "  ${MSG_INIT_USER_HINTS}\n" "${USER_PROJECT_NAME_HINT:-none}" "${USER_ARCHETYPE_HINT:-none}" "${USER_STACK_HINT:-none}"
  fi
  echo "  signals: docs=[${PROJECT_DOC_SIGNALS}] | impl=[${PROJECT_IMPLEMENTATION_SIGNALS}] | tests=[${PROJECT_TEST_SIGNALS}] | ops=[${PROJECT_OPS_SIGNALS}]"

  # 시도 1: Claude Code
  if command -v claude &> /dev/null; then
    printf "  ${MSG_INIT_AI_CLAUDE_RUNNING}\n" "$CLAUDE_TIMEOUT_SECONDS"
    if cd "$TARGET" && run_with_timeout "$CLAUDE_TIMEOUT_SECONDS" claude -p "$AI_PROMPT" --allowedTools Write,Edit,Read,Glob,Grep 2>/dev/null; then
      AI_SUCCESS=true
      echo "$MSG_INIT_AI_CLAUDE_OK"
    else
      claude_status=$?
      if [ "$claude_status" -eq 124 ]; then
        printf "  ${YELLOW}${MSG_INIT_AI_CLAUDE_TIMEOUT}${NC}\n" "$CLAUDE_TIMEOUT_SECONDS"
      else
        echo -e "  ${YELLOW}${MSG_INIT_AI_CLAUDE_FAIL}${NC}"
      fi
    fi
  else
    echo -e "  ${YELLOW}${MSG_INIT_AI_CLAUDE_MISSING}${NC}"
  fi

  # 시도 2: Codex (fallback)
  if [ "$AI_SUCCESS" = false ]; then
    if command -v codex &> /dev/null; then
      echo "$MSG_INIT_AI_CODEX_RUNNING"
      if (cd "$TARGET" && codex exec --skip-git-repo-check "$AI_PROMPT") 2>/dev/null; then
        AI_SUCCESS=true
        echo "$MSG_INIT_AI_CODEX_OK"
      else
        echo -e "  ${YELLOW}${MSG_INIT_AI_CODEX_FAIL}${NC}"
      fi
    else
      echo -e "  ${YELLOW}${MSG_INIT_AI_CODEX_MISSING}${NC}"
    fi
  fi

  # 시도 3: 수동 안내 (최종 fallback)
  if [ "$AI_SUCCESS" = false ]; then
    echo ""
    echo -e "  ${RED}${MSG_INIT_AI_MANUAL_TITLE}${NC}"
    echo -e "  $MSG_INIT_AI_MANUAL_DESC"
    echo ""
    echo -e "  ${CYAN}${MSG_INIT_AI_MANUAL_HEADER}${NC}"
    echo "$MSG_INIT_AI_MANUAL_STEP1"
    echo "$MSG_INIT_AI_MANUAL_STEP2"
    echo "$MSG_INIT_AI_MANUAL_CMD"
    echo ""
  fi
fi

# ============================================================
# 7단계: 완료 요약
# ============================================================
echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${GREEN}${MSG_INIT_STEP7_DRYRUN}${NC}"
else
  echo -e "${GREEN}${MSG_INIT_STEP7_DONE}${NC}"
fi
echo ""
echo -e "${CYAN}${MSG_INIT_SUMMARY_TITLE}${NC}"
echo ""
echo "$MSG_INIT_SUMMARY_READY"
if [ "$CLAUDE_PROFILE" = "minimal" ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "$MSG_INIT_SUMMARY_MINIMAL_LINK"
  else
    echo "$MSG_INIT_SUMMARY_MINIMAL_COPY"
  fi
  echo "$MSG_INIT_SUMMARY_MINIMAL_HOOKS"
elif [ "$CLAUDE_PROFILE" = "strict" ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "$MSG_INIT_SUMMARY_STRICT_LINK"
  else
    echo "$MSG_INIT_SUMMARY_STRICT_COPY"
  fi
  echo "$MSG_INIT_SUMMARY_STRICT_HOOKS"
  echo "$MSG_INIT_SUMMARY_STRICT_AGENTS"
  echo "$MSG_INIT_SUMMARY_STRICT_SKILLS"
elif [ "$CLAUDE_PROFILE" = "team" ]; then
  if [ "$LINK_MODE" = true ]; then
    echo "$MSG_INIT_SUMMARY_TEAM_LINK"
  else
    echo "$MSG_INIT_SUMMARY_TEAM_COPY"
  fi
  echo "$MSG_INIT_SUMMARY_TEAM_HOOKS"
  echo "$MSG_INIT_SUMMARY_TEAM_AGENTS"
  echo "$MSG_INIT_SUMMARY_TEAM_SKILLS"
else
  if [ "$LINK_MODE" = true ]; then
    echo "$MSG_INIT_SUMMARY_STANDARD_LINK"
  else
    echo "$MSG_INIT_SUMMARY_STANDARD_COPY"
  fi
  echo "$MSG_INIT_SUMMARY_STANDARD_HOOKS"
  echo "$MSG_INIT_SUMMARY_STANDARD_AGENTS"
  echo "$MSG_INIT_SUMMARY_STANDARD_SKILLS"
fi
if [ "$LINK_MODE" = true ]; then
  echo "$MSG_INIT_SUMMARY_CURSOR_LINK"
  echo "$MSG_INIT_SUMMARY_GEMINI_LINK"
else
  echo "$MSG_INIT_SUMMARY_CURSOR"
  echo "$MSG_INIT_SUMMARY_GEMINI"
fi
echo "$MSG_INIT_SUMMARY_CODEX"
if [ "$MCP_ENABLED" = true ]; then
  echo "$MSG_INIT_SUMMARY_MCP"
fi
echo ""

if [ "$TEMPLATES_COPIED" = true ]; then
  echo "$MSG_INIT_SUMMARY_CUSTOM_HEADER"
  echo "$MSG_INIT_SUMMARY_CLAUDEMD"
  echo "$MSG_INIT_SUMMARY_AGENTSMD"
  echo "$MSG_INIT_SUMMARY_GEMINIMD"
  echo "$MSG_INIT_SUMMARY_COPILOTMD"
  if [ "$CLAUDE_PROFILE" = "team" ]; then
    echo "$MSG_INIT_SUMMARY_PR_TEMPLATE"
  fi
  echo "$MSG_INIT_SUMMARY_DECISIONS"
fi
if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ]; then
  echo ""
  echo "$MSG_INIT_SUMMARY_BLANKSTART_HEADER"
  echo "$MSG_INIT_SUMMARY_BLANKSTART_HINT"
fi
if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "$MSG_INIT_SUMMARY_DRYRUN"
fi
if [ "$UPDATE_MODE" = true ]; then
  echo ""
  echo "$MSG_INIT_SUMMARY_UPDATE"
fi
echo ""
