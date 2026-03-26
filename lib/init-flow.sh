#!/bin/bash
# lib/init-flow.sh — init execution steps and summary output

print_init_overview() {
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
}

print_claude_profile_step_message() {
  case "$CLAUDE_PROFILE:$DRY_RUN:$LINK_MODE" in
    minimal:true:true) echo "$MSG_INIT_STEP1_MINIMAL_LINK_PLANNED" ;;
    minimal:true:false) echo "$MSG_INIT_STEP1_MINIMAL_PLANNED" ;;
    minimal:false:true) echo "$MSG_INIT_STEP1_MINIMAL_LINK_DONE" ;;
    minimal:false:false) echo "$MSG_INIT_STEP1_MINIMAL_DONE" ;;
    strict:true:true) echo "$MSG_INIT_STEP1_STRICT_LINK_PLANNED" ;;
    strict:true:false) echo "$MSG_INIT_STEP1_STRICT_PLANNED" ;;
    strict:false:true) echo "$MSG_INIT_STEP1_STRICT_LINK_DONE" ;;
    strict:false:false) echo "$MSG_INIT_STEP1_STRICT_DONE" ;;
    team:true:true) echo "$MSG_INIT_STEP1_TEAM_LINK_PLANNED" ;;
    team:true:false) echo "$MSG_INIT_STEP1_TEAM_PLANNED" ;;
    team:false:true) echo "$MSG_INIT_STEP1_TEAM_LINK_DONE" ;;
    team:false:false) echo "$MSG_INIT_STEP1_TEAM_DONE" ;;
    standard:true:true) echo "$MSG_INIT_STEP1_STANDARD_LINK_PLANNED" ;;
    standard:true:false) echo "$MSG_INIT_STEP1_STANDARD_PLANNED" ;;
    standard:false:true) echo "$MSG_INIT_STEP1_STANDARD_LINK_DONE" ;;
    *) echo "$MSG_INIT_STEP1_STANDARD_DONE" ;;
  esac
}

run_step1_claude_assets() {
  echo -e "${GREEN}${MSG_INIT_STEP1}${NC}"

  if [ -d "$TARGET/.claude" ]; then
    backup_existing_path "$TARGET/.claude" ".claude/"
  fi

  cleanup_managed_claude_assets "$MERGE_SETTINGS"
  copy_claude_profile_assets
  print_claude_profile_step_message
}

run_step2_tool_assets() {
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
}

run_step3_codex_assets() {
  if tool_enabled "codex"; then
    echo -e "${GREEN}${MSG_INIT_STEP3}${NC}"
    copy_codex_assets
    echo "$MSG_INIT_STEP3_OK"
  else
    echo -e "${GREEN}${MSG_INIT_STEP3_SKIP}${NC}"
  fi
}

run_step4_mcp_setup() {
  local preset

  echo -e "${GREEN}${MSG_INIT_STEP4}${NC}"

  if [ "$MCP_ENABLED" = false ]; then
    echo -e "  ${YELLOW}${MSG_INIT_STEP4_NOMCP}${NC}"
    return
  fi

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
}

copy_or_reapply_template() {
  local target_path="$1"
  local template_path="$2"
  local backup_label="$3"
  local done_message="$4"
  local planned_message="$5"
  local reapply_done_message="$6"
  local reapply_planned_message="$7"
  local skip_message="$8"

  if [ "$REAPPLY_MODE" = true ] && [ -f "$target_path" ]; then
    backup_existing_path "$target_path" "$backup_label"
    run_copy "$template_path" "$target_path"
    if [ "$DRY_RUN" = true ]; then
      echo "$reapply_planned_message"
    else
      echo "$reapply_done_message"
    fi
    TEMPLATES_COPIED=true
  elif [ ! -f "$target_path" ]; then
    run_copy "$template_path" "$target_path"
    if [ "$DRY_RUN" = true ] && [ -n "$planned_message" ]; then
      echo "$planned_message"
    else
      echo "$done_message"
    fi
    TEMPLATES_COPIED=true
  else
    echo -e "  ${YELLOW}${skip_message}${NC}"
  fi
}

insert_file_partial_if_needed() {
  local target_file="$1"
  local partial_dir="$2"
  local marker="$3"
  local archetype_partial use_partial ko_heading check_partial heading has_existing

  archetype_partial="$TEMPLATE_DIR/$partial_dir/${PROJECT_ARCHETYPE}.partial.md"

  if [ -f "$archetype_partial" ] && [ -f "$target_file" ] && [ "$DRY_RUN" != true ]; then
    if grep -qF "$marker" "$target_file" 2>/dev/null; then
      use_partial="$archetype_partial"
      ko_heading="$(head -1 "$SCRIPT_DIR/templates/ko/$partial_dir/${PROJECT_ARCHETYPE}.partial.md" 2>/dev/null)"
      if [ -n "$ko_heading" ] && sed -n "/$marker/,\$p" "$target_file" 2>/dev/null | grep -qF "$ko_heading"; then
        use_partial="$SCRIPT_DIR/templates/ko/$partial_dir/${PROJECT_ARCHETYPE}.partial.md"
      fi
      truncate_file_from_marker "$target_file" "$marker"
      echo "" >> "$target_file"
      echo "$marker" >> "$target_file"
      cat "$use_partial" >> "$target_file"
      printf "$MSG_INIT_ARCHETYPE_DONE\n" "$PROJECT_ARCHETYPE"
      return
    fi

    has_existing=false
    for check_partial in "$SCRIPT_DIR/templates/en/$partial_dir/${PROJECT_ARCHETYPE}.partial.md" "$SCRIPT_DIR/templates/ko/$partial_dir/${PROJECT_ARCHETYPE}.partial.md"; do
      if [ -f "$check_partial" ]; then
        heading="$(head -1 "$check_partial")"
        if [ -n "$heading" ] && grep -qF "$heading" "$target_file" 2>/dev/null; then
          has_existing=true
          break
        fi
      fi
    done

    if [ "$has_existing" = false ]; then
      echo "" >> "$target_file"
      echo "$marker" >> "$target_file"
      cat "$archetype_partial" >> "$target_file"
      printf "$MSG_INIT_ARCHETYPE_DONE\n" "$PROJECT_ARCHETYPE"
    fi
  elif [ -f "$archetype_partial" ] && [ "$DRY_RUN" = true ]; then
    dry_run_note "$(printf "$MSG_INIT_ARCHETYPE_DRYRUN" "$PROJECT_ARCHETYPE")"
  fi
}

insert_archetype_partials_if_needed() {
  insert_file_partial_if_needed "$TARGET/CLAUDE.md" "archetype" "<!-- ai-setting:archetype-rules -->"
  insert_file_partial_if_needed "$TARGET/AGENTS.md" "agents-archetype" "<!-- ai-setting:archetype-agent-rules -->"
}

ensure_decisions_template() {
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
}

ensure_runtime_gitignore_patterns() {
  local gitignore_path pat

  if [ "$DRY_RUN" = true ]; then
    return
  fi

  gitignore_path="$TARGET/.gitignore"
  for pat in ".claude/context/" ".claude.backup.*"; do
    if [ ! -f "$gitignore_path" ] || ! grep -qF "$pat" "$gitignore_path" 2>/dev/null; then
      echo "$pat" >> "$gitignore_path"
    fi
  done
}

run_step5_project_templates() {
  echo -e "${GREEN}${MSG_INIT_STEP5}${NC}"

  TEMPLATES_COPIED=false

  copy_or_reapply_template \
    "$TARGET/BEHAVIORAL_CORE.md" \
    "$TEMPLATE_DIR/BEHAVIORAL_CORE.md.template" \
    "BEHAVIORAL_CORE.md" \
    "$MSG_INIT_BEHAVIORAL_DONE" \
    "$MSG_INIT_BEHAVIORAL_PLANNED" \
    "$MSG_INIT_BEHAVIORAL_REAPPLY_DONE" \
    "$MSG_INIT_BEHAVIORAL_REAPPLY_PLANNED" \
    "$MSG_INIT_BEHAVIORAL_SKIP"

  copy_or_reapply_template \
    "$TARGET/CLAUDE.md" \
    "$TEMPLATE_DIR/CLAUDE.md.template" \
    "CLAUDE.md" \
    "$MSG_INIT_CLAUDEMD_DONE" \
    "" \
    "$MSG_INIT_CLAUDEMD_REAPPLY_DONE" \
    "$MSG_INIT_CLAUDEMD_REAPPLY_PLANNED" \
    "$MSG_INIT_CLAUDEMD_SKIP"

  copy_or_reapply_template \
    "$TARGET/AGENTS.md" \
    "$TEMPLATE_DIR/AGENTS.md.template" \
    "AGENTS.md" \
    "$MSG_INIT_AGENTSMD_DONE" \
    "$MSG_INIT_AGENTSMD_PLANNED" \
    "$MSG_INIT_AGENTSMD_REAPPLY_DONE" \
    "$MSG_INIT_AGENTSMD_REAPPLY_PLANNED" \
    "$MSG_INIT_AGENTSMD_SKIP"

  insert_archetype_partials_if_needed

  run_mkdir_p "$TARGET/docs"
  copy_or_reapply_template \
    "$TARGET/docs/research-notes.md" \
    "$TEMPLATE_DIR/research-notes.md.template" \
    "docs/research-notes.md" \
    "$MSG_INIT_RESEARCH_DONE" \
    "$MSG_INIT_RESEARCH_PLANNED" \
    "$MSG_INIT_RESEARCH_REAPPLY_DONE" \
    "$MSG_INIT_RESEARCH_REAPPLY_PLANNED" \
    "$MSG_INIT_RESEARCH_SKIP"

  if tool_enabled "gemini"; then
    copy_or_reapply_template \
      "$TARGET/GEMINI.md" \
      "$TEMPLATE_DIR/GEMINI.md.template" \
      "GEMINI.md" \
      "$MSG_INIT_GEMINIMD_DONE" \
      "" \
      "$MSG_INIT_GEMINIMD_REAPPLY_DONE" \
      "$MSG_INIT_GEMINIMD_REAPPLY_DONE" \
      "$MSG_INIT_GEMINIMD_SKIP"
  fi

  if tool_enabled "copilot"; then
    run_mkdir_p "$TARGET/.github"
    copy_or_reapply_template \
      "$TARGET/.github/copilot-instructions.md" \
      "$TEMPLATE_DIR/copilot-instructions.md.template" \
      ".github/copilot-instructions.md" \
      "$MSG_INIT_COPILOTMD_DONE" \
      "" \
      "$MSG_INIT_COPILOTMD_REAPPLY_DONE" \
      "$MSG_INIT_COPILOTMD_REAPPLY_DONE" \
      "$MSG_INIT_COPILOTMD_SKIP"
  fi

  if [ "$CLAUDE_PROFILE" = "team" ]; then
    run_mkdir_p "$TARGET/.github"
    copy_or_reapply_template \
      "$TARGET/.github/pull_request_template.md" \
      "$TEMPLATE_DIR/pull_request_template.md.template" \
      ".github/pull_request_template.md" \
      "$MSG_INIT_PR_TEMPLATE_DONE" \
      "$MSG_INIT_PR_TEMPLATE_PLANNED" \
      "$MSG_INIT_PR_TEMPLATE_REAPPLY_DONE" \
      "$MSG_INIT_PR_TEMPLATE_REAPPLY_PLANNED" \
      "$MSG_INIT_PR_TEMPLATE_SKIP"

    run_mkdir_p "$TARGET/.ai-setting"
    copy_or_reapply_template \
      "$TARGET/.ai-setting/team-webhook.json" \
      "$TEMPLATE_DIR/team-webhook.json.template" \
      ".ai-setting/team-webhook.json" \
      "$MSG_INIT_WEBHOOK_DONE" \
      "$MSG_INIT_WEBHOOK_PLANNED" \
      "$MSG_INIT_WEBHOOK_REAPPLY_DONE" \
      "$MSG_INIT_WEBHOOK_REAPPLY_PLANNED" \
      "$MSG_INIT_WEBHOOK_SKIP"
  fi

  run_mkdir_p "$TARGET/.ai-setting"
  copy_or_reapply_template \
    "$TARGET/.ai-setting/protect-files.json" \
    "$TEMPLATE_DIR/protect-files.json.template" \
    ".ai-setting/protect-files.json" \
    "  ✅ protect-files override config 생성" \
    "  📝 [dry-run] .ai-setting/protect-files.json 생성 예정" \
    "  ✅ protect-files override config 재적용" \
    "  📝 [dry-run] .ai-setting/protect-files.json 재적용 예정" \
    "  ⚠ .ai-setting/protect-files.json 유지"

  copy_or_reapply_template \
    "$TARGET/.ai-setting/protect-files.notes.md" \
    "$TEMPLATE_DIR/protect-files.notes.md.template" \
    ".ai-setting/protect-files.notes.md" \
    "  ✅ protect-files notes 생성" \
    "  📝 [dry-run] .ai-setting/protect-files.notes.md 생성 예정" \
    "  ✅ protect-files notes 재적용" \
    "  📝 [dry-run] .ai-setting/protect-files.notes.md 재적용 예정" \
    "  ⚠ .ai-setting/protect-files.notes.md 유지"

  ensure_decisions_template
  ensure_runtime_gitignore_patterns
}

run_init_file_setup_steps() {
  if [ "$BACKUP_ALL" = true ]; then
    perform_backup_all
  fi

  run_step1_claude_assets
  run_step2_tool_assets
  run_step3_codex_assets
  run_step4_mcp_setup
  run_step5_project_templates
}

print_init_summary() {
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
}
