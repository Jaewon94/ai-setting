#!/bin/bash
# lib/profile.sh — Claude/Cursor/Gemini 프로필 자산 설치 및 정리

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
  local preserve_settings="${1:-false}"
  local managed_file
  local managed_dir
  local managed_files=(
    "$TARGET/.claude/settings.json"
    "$TARGET/.claude/hooks/protect-files.sh"
    "$TARGET/.claude/hooks/format-on-write.sh"
    "$TARGET/.claude/hooks/block-dangerous-commands.sh"
    "$TARGET/.claude/hooks/protect-main-branch.sh"
    "$TARGET/.claude/hooks/session-context.sh"
    "$TARGET/.claude/hooks/compact-backup.sh"
    "$TARGET/.claude/hooks/async-test.sh"
    "$TARGET/.claude/hooks/team-webhook-notify.sh"
    "$TARGET/.claude/hooks/metadata.json"
    "$TARGET/.claude/agents/security-reviewer.md"
    "$TARGET/.claude/agents/architect-reviewer.md"
    "$TARGET/.claude/agents/test-writer.md"
    "$TARGET/.claude/agents/research.md"
    "$TARGET/.claude/skills/deploy/SKILL.md"
    "$TARGET/.claude/skills/review/SKILL.md"
    "$TARGET/.claude/skills/fix-issue/SKILL.md"
    "$TARGET/.claude/skills/gap-check/SKILL.md"
    "$TARGET/.claude/skills/cross-validate/SKILL.md"
    "$TARGET/.claude/skills/document-feature/SKILL.md"
    "$TARGET/.claude/skills/document-infra/SKILL.md"
    "$TARGET/.claude/skills/document-security/SKILL.md"
    "$TARGET/.claude/skills/metadata.json"
  )
  local managed_dirs=(
    "$TARGET/.claude/agents"
    "$TARGET/.claude/skills/deploy"
    "$TARGET/.claude/skills/review"
    "$TARGET/.claude/skills/fix-issue"
    "$TARGET/.claude/skills/gap-check"
    "$TARGET/.claude/skills/cross-validate"
    "$TARGET/.claude/skills/document-feature"
    "$TARGET/.claude/skills/document-infra"
    "$TARGET/.claude/skills/document-security"
    "$TARGET/.claude/skills"
    "$TARGET/.claude/hooks"
  )

  for managed_file in "${managed_files[@]}"; do
    if [ "$preserve_settings" = true ] && [ "$managed_file" = "$TARGET/.claude/settings.json" ]; then
      continue
    fi
    run_remove_path "$managed_file"
  done

  for managed_dir in "${managed_dirs[@]}"; do
    cleanup_empty_parent_dir "$managed_dir"
  done
}

merge_claude_settings_template() {
  local settings_path="$TARGET/.claude/settings.json"
  local settings_template="$1"

  if [ ! -f "$settings_path" ] || [ "$MERGE_SETTINGS" != true ]; then
    install_shared_asset "$settings_template" "$settings_path"
    return
  fi

  if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}  $MSG_PROFILE_MERGE_NOJQ_WARN${NC}"
    install_shared_asset "$settings_template" "$settings_path"
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "$(printf "$MSG_PROFILE_MERGE_DRYRUN" "$settings_path")"
    return
  fi

  if [ -L "$settings_path" ]; then
    local resolved
    resolved="$(readlink "$settings_path")"
    cp "$resolved" "$settings_path.tmp"
    rm "$settings_path"
    mv "$settings_path.tmp" "$settings_path"
    echo -e "  ${YELLOW}$MSG_PROFILE_MERGE_SYMLINK_WARN${NC}"
  fi

  local merged
  merged="$(jq -s '
    def is_managed: ._source == "ai-setting";
    def strip_managed_hooks:
      if . == null then [] else [.[] | .hooks = [(.hooks // [])[] | select(is_managed | not)]] | [.[] | select((.hooks | length) > 0)] end;
    def hook_key:
      (.matcher // "") + "|" + ((.hooks // []) | map(.type + ":" + (.command // .prompt // "")) | join("|"));
    def merge_hook_arrays($base; $incoming):
      (($base | strip_managed_hooks) + ($incoming // []) | unique_by(hook_key));
    def merge_hooks_map($base; $incoming):
      reduce (($incoming // {}) | keys_unsorted[]) as $event ($base // {};
        .[$event] = merge_hook_arrays(.[$event]; $incoming[$event])
      );
    .[0] as $base | .[1] as $incoming |
    reduce ($incoming | to_entries[]) as $entry ($base;
      if $entry.key == "hooks" then
        .hooks = merge_hooks_map(.hooks; $incoming.hooks)
      elif has($entry.key) then
        .
      else
        . + {($entry.key): $entry.value}
      end
    )
  ' "$settings_path" "$settings_template" 2>/dev/null)"
  if [ $? -eq 0 ] && [ -n "$merged" ]; then
    echo "$merged" > "$settings_path"
    echo -e "$MSG_PROFILE_MERGE_OK"
  else
    echo -e "${RED}$MSG_PROFILE_MERGE_FAIL${NC}"
    return 1
  fi
}

merge_settings_local() {
  local settings_path="$TARGET/.claude/settings.json"
  local local_path="$TARGET/.claude/settings.local.json"

  if [ ! -f "$local_path" ]; then
    return
  fi

  if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}  $MSG_PROFILE_LOCAL_NOJQ_WARN${NC}"
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "$(printf "$MSG_PROFILE_LOCAL_DRYRUN" "$local_path")"
    return
  fi

  if [ -L "$settings_path" ]; then
    local resolved
    resolved="$(readlink "$settings_path")"
    cp "$resolved" "$settings_path.tmp"
    rm "$settings_path"
    mv "$settings_path.tmp" "$settings_path"
    echo -e "  ${YELLOW}$MSG_PROFILE_LOCAL_SYMLINK_WARN${NC}"
  fi

  local merged
  merged="$(jq -s '.[0] * .[1]' "$settings_path" "$local_path" 2>/dev/null)"
  if [ $? -eq 0 ] && [ -n "$merged" ]; then
    echo "$merged" > "$settings_path"
    echo -e "$MSG_PROFILE_LOCAL_OK"
  else
    echo -e "${RED}$MSG_PROFILE_LOCAL_FAIL${NC}"
  fi
}

copy_claude_profile_assets() {
  local settings_template

  settings_template="$(get_profile_settings_template "$CLAUDE_PROFILE")"

  if [ "$LINK_DIR_MODE" = true ]; then
    run_mkdir_p "$TARGET/.claude"
    merge_claude_settings_template "$settings_template"
    install_shared_directory_link "$SCRIPT_DIR/claude/hooks" "$TARGET/.claude/hooks"
    if [ "$CLAUDE_PROFILE" != "minimal" ]; then
      install_shared_directory_link "$SCRIPT_DIR/claude/agents" "$TARGET/.claude/agents"
      install_shared_directory_link "$SCRIPT_DIR/claude/skills" "$TARGET/.claude/skills"
    fi
    merge_settings_local
    return
  fi

  run_mkdir_p "$TARGET/.claude/hooks"
  merge_claude_settings_template "$settings_template"
  install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/protect-files.sh" "$TARGET/.claude/hooks/protect-files.sh"
  install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/format-on-write.sh" "$TARGET/.claude/hooks/format-on-write.sh"
  install_shared_asset "$SCRIPT_DIR/claude/hooks/metadata.json" "$TARGET/.claude/hooks/metadata.json"

  if [ "$CLAUDE_PROFILE" != "minimal" ]; then
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/block-dangerous-commands.sh" "$TARGET/.claude/hooks/block-dangerous-commands.sh"
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/session-context.sh" "$TARGET/.claude/hooks/session-context.sh"
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/compact-backup.sh" "$TARGET/.claude/hooks/compact-backup.sh"
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/async-test.sh" "$TARGET/.claude/hooks/async-test.sh"
  fi

  if [ "$CLAUDE_PROFILE" = "strict" ] || [ "$CLAUDE_PROFILE" = "team" ]; then
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/protect-main-branch.sh" "$TARGET/.claude/hooks/protect-main-branch.sh"
  fi

  if [ "$CLAUDE_PROFILE" = "team" ]; then
    install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/team-webhook-notify.sh" "$TARGET/.claude/hooks/team-webhook-notify.sh"
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
    run_mkdir_p "$TARGET/.claude/skills/document-feature"
    run_mkdir_p "$TARGET/.claude/skills/document-infra"
    run_mkdir_p "$TARGET/.claude/skills/document-security"
    install_shared_asset "$SCRIPT_DIR/claude/skills/deploy/SKILL.md" "$TARGET/.claude/skills/deploy/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/review/SKILL.md" "$TARGET/.claude/skills/review/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/fix-issue/SKILL.md" "$TARGET/.claude/skills/fix-issue/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/gap-check/SKILL.md" "$TARGET/.claude/skills/gap-check/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/cross-validate/SKILL.md" "$TARGET/.claude/skills/cross-validate/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/document-feature/SKILL.md" "$TARGET/.claude/skills/document-feature/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/document-infra/SKILL.md" "$TARGET/.claude/skills/document-infra/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/document-security/SKILL.md" "$TARGET/.claude/skills/document-security/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/metadata.json" "$TARGET/.claude/skills/metadata.json"
  fi

  merge_settings_local
}

copy_cursor_assets() {
  local selected_rule
  local target_rule
  local selected_rules=()

  run_mkdir_p "$TARGET/.cursor/rules"

  while IFS= read -r selected_rule; do
    [ -n "$selected_rule" ] || continue
    selected_rules+=("$selected_rule")
    target_rule="$TARGET/.cursor/rules/$selected_rule"
    if [ -f "$target_rule" ] || [ -L "$target_rule" ]; then
      backup_existing_path "$target_rule" ".cursor/rules/$selected_rule"
    fi
    install_shared_asset "$SCRIPT_DIR/cursor/rules/$selected_rule" "$target_rule"
  done < <(get_cursor_rule_paths "${PROJECT_STACK:-}" "${PROJECT_CONTEXT_MODE:-}" "${PROJECT_ARCHETYPE:-}")

  while IFS= read -r selected_rule; do
    [ -n "$selected_rule" ] || continue
    if contains_value "$selected_rule" "${selected_rules[@]}"; then
      continue
    fi
    target_rule="$TARGET/.cursor/rules/$selected_rule"
    if [ -e "$target_rule" ] || [ -L "$target_rule" ]; then
      backup_existing_path "$target_rule" ".cursor/rules/$selected_rule"
      run_remove_path "$target_rule"
    fi
  done < <(get_all_cursor_rule_paths)
}

copy_gemini_assets() {
  run_mkdir_p "$TARGET/.gemini"
  if [ -f "$TARGET/.gemini/settings.json" ]; then
    backup_existing_path "$TARGET/.gemini/settings.json" ".gemini/settings.json"
  fi
  install_shared_asset "$SCRIPT_DIR/gemini/settings.json" "$TARGET/.gemini/settings.json"
  if [ -f "$TARGET/.gemini/settings.notes.md" ]; then
    backup_existing_path "$TARGET/.gemini/settings.notes.md" ".gemini/settings.notes.md"
  fi
  run_copy "$TEMPLATE_DIR/gemini-settings.notes.md.template" "$TARGET/.gemini/settings.notes.md"
}

copy_copilot_assets() {
  local instruction
  local target_instruction
  local selected_instructions=()

  run_mkdir_p "$TARGET/.github"
  run_mkdir_p "$TARGET/.github/instructions"
  if [ -f "$TARGET/.github/copilot-instructions.md" ]; then
    backup_existing_path "$TARGET/.github/copilot-instructions.md" ".github/copilot-instructions.md"
  fi
  run_copy "$TEMPLATE_DIR/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"

  while IFS= read -r instruction; do
    [ -n "$instruction" ] || continue
    selected_instructions+=("$instruction")
    target_instruction="$TARGET/.github/instructions/$instruction"
    if [ -f "$target_instruction" ] || [ -L "$target_instruction" ]; then
      backup_existing_path "$target_instruction" ".github/instructions/$instruction"
    fi
    run_copy "$TEMPLATE_DIR/copilot-instructions/$instruction.template" "$target_instruction"
  done < <(get_copilot_instruction_paths "${PROJECT_STACK:-}" "${PROJECT_CONTEXT_MODE:-}" "${PROJECT_ARCHETYPE:-}")

  while IFS= read -r instruction; do
    [ -n "$instruction" ] || continue
    if contains_value "$instruction" "${selected_instructions[@]}"; then
      continue
    fi
    target_instruction="$TARGET/.github/instructions/$instruction"
    if [ -e "$target_instruction" ] || [ -L "$target_instruction" ]; then
      backup_existing_path "$target_instruction" ".github/instructions/$instruction"
      run_remove_path "$target_instruction"
    fi
  done < <(get_all_copilot_instruction_paths)
}

copy_codex_assets() {
  run_mkdir_p "$TARGET/.codex"
  if [ -f "$TARGET/.codex/config.toml" ]; then
    backup_existing_path "$TARGET/.codex/config.toml" ".codex/config.toml"
  fi
  run_copy "$(get_codex_config_template "$CLAUDE_PROFILE")" "$TARGET/.codex/config.toml"
  if [ -f "$TARGET/.codex/config.notes.md" ]; then
    backup_existing_path "$TARGET/.codex/config.notes.md" ".codex/config.notes.md"
  fi
  run_copy "$TEMPLATE_DIR/codex-config.notes.md.template" "$TARGET/.codex/config.notes.md"
}

cmd_add_tool() {
  local tool_name="$1"
  local target="${2:-.}"

  prepare_target_context "$target"

  printf "${CYAN}$(printf "$MSG_ADDTOOL_TITLE" "$tool_name")${NC}\n"
  printf "$MSG_ADDTOOL_TARGET\n" "$TARGET"

  case "$tool_name" in
    cursor)
      copy_cursor_assets
      echo -e "${GREEN}$MSG_ADDTOOL_CURSOR_OK${NC}"
      echo "  .cursor/rules/*.mdc"
      ;;
    gemini)
      copy_gemini_assets
      if [ ! -f "$TARGET/GEMINI.md" ]; then
        run_copy "$SCRIPT_DIR/templates/GEMINI.md.template" "$TARGET/GEMINI.md"
        echo "$MSG_ADDTOOL_GEMINIMD_CREATED"
      fi
      echo -e "${GREEN}$MSG_ADDTOOL_GEMINI_OK${NC}"
      ;;
    copilot)
      copy_copilot_assets
      echo -e "${GREEN}$MSG_ADDTOOL_COPILOT_OK${NC}"
      echo "  .github/copilot-instructions.md"
      ;;
    codex)
      copy_codex_assets
      if [ "$MCP_ENABLED" != false ] && [ -f "$TARGET/.codex/config.toml" ]; then
        for preset in "${MCP_PRESETS[@]:-core}"; do
          append_codex_mcp_preset "$preset" "$TARGET/.codex/config.toml"
        done
        echo "$MSG_ADDTOOL_CODEX_MCP"
      fi
      echo -e "${GREEN}$MSG_ADDTOOL_CODEX_OK${NC}"
      ;;
    claude)
      echo -e "${YELLOW}$MSG_ADDTOOL_CLAUDE_HINT${NC}"
      ;;
    *)
      printf "${RED}$MSG_ADDTOOL_ERR_UNKNOWN${NC}\n" "$tool_name" >&2
      echo "$MSG_ADDTOOL_SUPPORTED"
      return 1
      ;;
  esac
}
