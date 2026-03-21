#!/bin/bash
# lib/sync.sh — manifest 기반 다중 프로젝트 동기화

resolve_manifest_target_path() {
  local manifest_dir="$1"
  local raw_path="$2"

  case "$raw_path" in
    ~/*)
      printf '%s/%s\n' "$HOME" "${raw_path#~/}"
      ;;
    /*)
      printf '%s\n' "$raw_path"
      ;;
    *)
      printf '%s/%s\n' "$manifest_dir" "$raw_path"
      ;;
  esac
}

parse_manifest_line() {
  local line="$1"
  local tokens=()
  read -ra tokens <<< "$line"

  MANIFEST_LINE_PATH="${tokens[0]}"
  MANIFEST_LINE_PROFILE=""
  MANIFEST_LINE_MCP_PRESET=""
  MANIFEST_LINE_ARCHETYPE=""
  MANIFEST_LINE_STACK=""

  local i=1
  while [ $i -lt ${#tokens[@]} ]; do
    local token="${tokens[$i]}"
    case "$token" in
      profile=*)
        MANIFEST_LINE_PROFILE="${token#profile=}"
        ;;
      mcp-preset=*)
        MANIFEST_LINE_MCP_PRESET="${token#mcp-preset=}"
        ;;
      archetype=*)
        MANIFEST_LINE_ARCHETYPE="${token#archetype=}"
        ;;
      stack=*)
        MANIFEST_LINE_STACK="${token#stack=}"
        ;;
    esac
    i=$((i + 1))
  done
}

get_shared_asset_paths() {
  local profile="${1:-standard}"
  local paths=(
    ".claude/settings.json"
    ".claude/hooks/protect-files.sh"
  )
  if [ "$profile" != "minimal" ]; then
    paths+=(
      ".claude/hooks/block-dangerous-commands.sh"
      ".claude/hooks/session-context.sh"
      ".claude/hooks/compact-backup.sh"
      ".claude/hooks/async-test.sh"
    )
  fi
  if [ "$profile" = "strict" ] || [ "$profile" = "team" ]; then
    paths+=(".claude/hooks/protect-main-branch.sh")
  fi
  if [ "$profile" = "team" ]; then
    paths+=(".claude/hooks/team-webhook-notify.sh")
  fi
  paths+=(
    ".cursor/rules/ai-setting.mdc"
    ".gemini/settings.json"
  )
  printf '%s\n' "${paths[@]}"
}

detect_sync_conflicts() {
  local target="$1"
  local profile="${2:-standard}"
  local conflict_count=0
  local conflict_files=()

  while IFS= read -r rel_path; do
    local target_file="$target/$rel_path"

    [ -f "$target_file" ] || continue
    [ -L "$target_file" ] && continue

    local source_file=""
    case "$rel_path" in
      .claude/settings.json)
        source_file="$(get_profile_settings_template "$profile")"
        ;;
      .claude/hooks/*)
        local hook_name="${rel_path#.claude/hooks/}"
        source_file="$SCRIPT_DIR/claude/hooks/$hook_name"
        ;;
      .cursor/rules/ai-setting.mdc)
        source_file="$SCRIPT_DIR/cursor/rules/ai-setting.mdc"
        ;;
      .gemini/settings.json)
        source_file="$SCRIPT_DIR/gemini/settings.json"
        ;;
    esac

    [ -f "$source_file" ] || continue

    if ! diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
      conflict_count=$((conflict_count + 1))
      conflict_files+=("$rel_path")
    fi
  done < <(get_shared_asset_paths "$profile")

  SYNC_CONFLICT_COUNT=$conflict_count
  SYNC_CONFLICT_FILES=("${conflict_files[@]}")
}

run_sync_manifest() {
  local manifest_path="$1"
  local raw_line=""
  local line=""
  local manifest_dir=""
  local target_path=""
  local total=0
  local success_count=0
  local failure_count=0
  local skipped_count=0
  local child_command=()
  local child_mode_label=""

  if [ ! -f "$manifest_path" ]; then
    printf "${RED}${MSG_SYNC_ERR_NOT_FOUND}${NC}\n" "$manifest_path" >&2
    echo -e "${MSG_SYNC_ERR_HINT}" >&2
    return 1
  fi

  manifest_path="$(cd "$(dirname "$manifest_path")" && pwd)/$(basename "$manifest_path")"
  manifest_dir="$(dirname "$manifest_path")"

  echo -e "${CYAN}${MSG_SYNC_TITLE}${NC}"
  printf "${MSG_SYNC_SOURCE}\n" "$SCRIPT_DIR"
  printf "${MSG_SYNC_MANIFEST}\n" "$manifest_path"
  printf "${MSG_SYNC_MODE}\n" "$SYNC_MODE_KIND"
  printf "${MSG_SYNC_CLAUDE_PROFILE}\n" "$CLAUDE_PROFILE"
  if [ "$LINK_MODE" = true ]; then
    echo -e "${MSG_SYNC_ASSET_SYMLINK}"
  else
    echo -e "${MSG_SYNC_ASSET_COPY}"
  fi
  if [ "$DRY_RUN" = true ]; then
    echo -e "${MSG_SYNC_EXEC_DRYRUN}"
  fi
  if [ "$BACKUP_ALL" = true ]; then
    echo -e "${MSG_SYNC_BACKUP_ALL}"
  fi
  if [ "$REAPPLY_MODE" = true ]; then
    echo -e "${MSG_SYNC_REAPPLY}"
  fi
  echo ""

  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    line="${raw_line%$'\r'}"
    line="$(trim_whitespace "$line")"

    if [ -z "$line" ] || [[ "$line" == \#* ]]; then
      continue
    fi

    total=$((total + 1))

    parse_manifest_line "$line"
    target_path="$(resolve_manifest_target_path "$manifest_dir" "$MANIFEST_LINE_PATH")"

    local per_project_profile="${MANIFEST_LINE_PROFILE:-$CLAUDE_PROFILE}"
    local per_project_mcp_preset="$MANIFEST_LINE_MCP_PRESET"
    local per_project_archetype="${MANIFEST_LINE_ARCHETYPE:-$USER_ARCHETYPE_HINT}"
    local per_project_stack="${MANIFEST_LINE_STACK:-$USER_STACK_HINT}"

    echo -e "${GREEN}[${total}]${NC} ${target_path}"
    if [ -n "$MANIFEST_LINE_PROFILE" ] || [ -n "$MANIFEST_LINE_MCP_PRESET" ] || [ -n "$MANIFEST_LINE_ARCHETYPE" ] || [ -n "$MANIFEST_LINE_STACK" ]; then
      local opts_display=""
      [ -n "$MANIFEST_LINE_PROFILE" ] && opts_display+="profile=${MANIFEST_LINE_PROFILE} "
      [ -n "$MANIFEST_LINE_MCP_PRESET" ] && opts_display+="mcp-preset=${MANIFEST_LINE_MCP_PRESET} "
      [ -n "$MANIFEST_LINE_ARCHETYPE" ] && opts_display+="archetype=${MANIFEST_LINE_ARCHETYPE} "
      [ -n "$MANIFEST_LINE_STACK" ] && opts_display+="stack=${MANIFEST_LINE_STACK} "
      printf "${MSG_SYNC_LINE_OPTS}\n" "$opts_display"
    fi

    if [ ! -d "$target_path" ]; then
      echo -e "  ${YELLOW}${MSG_SYNC_SKIP_DIR}${NC}"
      skipped_count=$((skipped_count + 1))
      echo ""
      continue
    fi

    detect_sync_conflicts "$target_path" "$per_project_profile"
    if [ "$SYNC_CONFLICT_COUNT" -gt 0 ]; then
      printf "  ${YELLOW}${MSG_SYNC_CONFLICT_DETECTED}${NC}\n" "$SYNC_CONFLICT_COUNT" "${SYNC_CONFLICT_FILES[*]}"
      case "$SYNC_CONFLICT_STRATEGY" in
        skip)
          echo -e "  ${YELLOW}${MSG_SYNC_CONFLICT_SKIP}${NC}"
          skipped_count=$((skipped_count + 1))
          echo ""
          continue
          ;;
        backup)
          echo -e "${MSG_SYNC_CONFLICT_BACKUP}"
          ;;
        overwrite)
          echo -e "${MSG_SYNC_CONFLICT_OVERWRITE}"
          ;;
      esac
    fi

    child_command=("$SCRIPT_DIR/init.sh")
    if [ "$SYNC_MODE_KIND" = "update" ]; then
      child_command+=("update")
      child_mode_label="update"
    else
      child_mode_label="init"
    fi

    child_command+=("--profile" "$per_project_profile")

    if [ "$LINK_DIR_MODE" = true ]; then
      child_command+=("--link-dir")
    elif [ "$LINK_MODE" = true ]; then
      child_command+=("--link")
    fi
    if [ "$AUTO_MCP" = true ]; then
      child_command+=("--auto-mcp")
    fi
    if [ "$SKIP_AI" = true ]; then
      child_command+=("--skip-ai")
    fi
    if [ "$DRY_RUN" = true ]; then
      child_command+=("--dry-run")
    fi
    if [ "$BACKUP_ALL" = true ]; then
      child_command+=("--backup-all")
    fi
    if [ "$REAPPLY_MODE" = true ]; then
      child_command+=("--reapply")
    fi
    if [ "$MCP_ENABLED" = false ]; then
      child_command+=("--no-mcp")
    elif [ -n "$per_project_mcp_preset" ]; then
      child_command+=("--mcp-preset" "$per_project_mcp_preset")
    elif [ "$USER_MCP_PRESET_SPECIFIED" = true ] && [ "${#MCP_PRESETS[@]}" -gt 0 ]; then
      child_command+=("--mcp-preset" "$(IFS=,; echo "${MCP_PRESETS[*]}")")
    fi
    if [ -n "$per_project_archetype" ]; then
      child_command+=("--archetype" "$per_project_archetype")
    fi
    if [ -n "$per_project_stack" ]; then
      child_command+=("--stack" "$per_project_stack")
    fi

    child_command+=("$target_path")

    printf "${MSG_SYNC_APPLY_START}\n" "$child_mode_label"
    if "${child_command[@]}"; then
      success_count=$((success_count + 1))
      echo "${MSG_SYNC_APPLY_OK}"
    else
      failure_count=$((failure_count + 1))
      echo -e "${RED}${MSG_SYNC_APPLY_FAIL}${NC}"
    fi
    echo ""
  done < "$manifest_path"

  echo -e "${CYAN}${MSG_SYNC_SUMMARY_TITLE}${NC}"
  echo "  manifest entries: ${total}"
  echo "  success: ${success_count}"
  echo "  skipped: ${skipped_count}"
  echo "  failed: ${failure_count}"

  if [ "$failure_count" -gt 0 ]; then
    return 1
  fi

  return 0
}
