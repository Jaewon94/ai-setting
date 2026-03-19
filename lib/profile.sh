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
  local managed_file
  local managed_dir
  local managed_files=(
    "$TARGET/.claude/settings.json"
    "$TARGET/.claude/hooks/protect-files.sh"
    "$TARGET/.claude/hooks/block-dangerous-commands.sh"
    "$TARGET/.claude/hooks/protect-main-branch.sh"
    "$TARGET/.claude/hooks/session-context.sh"
    "$TARGET/.claude/hooks/compact-backup.sh"
    "$TARGET/.claude/hooks/async-test.sh"
    "$TARGET/.claude/hooks/team-webhook-notify.sh"
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

merge_settings_local() {
  local settings_path="$TARGET/.claude/settings.json"
  local local_path="$TARGET/.claude/settings.local.json"

  if [ ! -f "$local_path" ]; then
    return
  fi

  if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}  ⚠ jq가 없어 settings.local.json merge를 건너뜁니다${NC}"
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "settings.local.json merge 적용: ${local_path}"
    return
  fi

  if [ -L "$settings_path" ]; then
    local resolved
    resolved="$(readlink "$settings_path")"
    cp "$resolved" "$settings_path.tmp"
    rm "$settings_path"
    mv "$settings_path.tmp" "$settings_path"
    echo -e "  ${YELLOW}⚠ settings.json 심링크를 파일로 전환 (local override 적용 위해)${NC}"
  fi

  local merged
  merged="$(jq -s '.[0] * .[1]' "$settings_path" "$local_path" 2>/dev/null)"
  if [ $? -eq 0 ] && [ -n "$merged" ]; then
    echo "$merged" > "$settings_path"
    echo -e "  ✅ settings.local.json merge 적용 완료"
  else
    echo -e "  ${RED}✗ settings.local.json merge 실패 (JSON 형식 확인 필요)${NC}"
  fi
}

copy_claude_profile_assets() {
  local settings_template

  settings_template="$(get_profile_settings_template "$CLAUDE_PROFILE")"

  if [ "$LINK_DIR_MODE" = true ]; then
    run_mkdir_p "$TARGET/.claude"
    install_shared_asset "$settings_template" "$TARGET/.claude/settings.json"
    install_shared_directory_link "$SCRIPT_DIR/claude/hooks" "$TARGET/.claude/hooks"
    if [ "$CLAUDE_PROFILE" != "minimal" ]; then
      install_shared_directory_link "$SCRIPT_DIR/claude/agents" "$TARGET/.claude/agents"
      install_shared_directory_link "$SCRIPT_DIR/claude/skills" "$TARGET/.claude/skills"
    fi
    merge_settings_local
    return
  fi

  run_mkdir_p "$TARGET/.claude/hooks"
  install_shared_asset "$settings_template" "$TARGET/.claude/settings.json"
  install_shared_executable_asset "$SCRIPT_DIR/claude/hooks/protect-files.sh" "$TARGET/.claude/hooks/protect-files.sh"

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
    install_shared_asset "$SCRIPT_DIR/claude/skills/deploy/SKILL.md" "$TARGET/.claude/skills/deploy/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/review/SKILL.md" "$TARGET/.claude/skills/review/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/fix-issue/SKILL.md" "$TARGET/.claude/skills/fix-issue/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/gap-check/SKILL.md" "$TARGET/.claude/skills/gap-check/"
    install_shared_asset "$SCRIPT_DIR/claude/skills/cross-validate/SKILL.md" "$TARGET/.claude/skills/cross-validate/"
  fi

  merge_settings_local
}

copy_cursor_assets() {
  run_mkdir_p "$TARGET/.cursor/rules"
  if [ -f "$TARGET/.cursor/rules/ai-setting.mdc" ]; then
    backup_existing_path "$TARGET/.cursor/rules/ai-setting.mdc" ".cursor/rules/ai-setting.mdc"
  fi
  install_shared_asset "$SCRIPT_DIR/cursor/rules/ai-setting.mdc" "$TARGET/.cursor/rules/ai-setting.mdc"

  # 스택 기반 파일 타입별 규칙 추가
  case "${PROJECT_STACK:-}" in
    *TypeScript*|*JavaScript*|*Next.js*|*Vite*|*Node*)
      install_shared_asset "$SCRIPT_DIR/cursor/rules/typescript.mdc" "$TARGET/.cursor/rules/typescript.mdc"
      ;;
    *Python*)
      install_shared_asset "$SCRIPT_DIR/cursor/rules/python.mdc" "$TARGET/.cursor/rules/python.mdc"
      ;;
  esac

  # testing.mdc는 모든 프로젝트에 적용 (blank-start 제외)
  if [ "${PROJECT_CONTEXT_MODE:-}" != "blank-start" ]; then
    install_shared_asset "$SCRIPT_DIR/cursor/rules/testing.mdc" "$TARGET/.cursor/rules/testing.mdc"
  fi
}

copy_gemini_assets() {
  run_mkdir_p "$TARGET/.gemini"
  if [ -f "$TARGET/.gemini/settings.json" ]; then
    backup_existing_path "$TARGET/.gemini/settings.json" ".gemini/settings.json"
  fi
  install_shared_asset "$SCRIPT_DIR/gemini/settings.json" "$TARGET/.gemini/settings.json"
}

copy_copilot_assets() {
  run_mkdir_p "$TARGET/.github"
  if [ -f "$TARGET/.github/copilot-instructions.md" ]; then
    backup_existing_path "$TARGET/.github/copilot-instructions.md" ".github/copilot-instructions.md"
  fi
  run_copy "$SCRIPT_DIR/templates/copilot-instructions.md.template" "$TARGET/.github/copilot-instructions.md"
}

copy_codex_assets() {
  run_mkdir_p "$TARGET/.codex"
  if [ -f "$TARGET/.codex/config.toml" ]; then
    backup_existing_path "$TARGET/.codex/config.toml" ".codex/config.toml"
  fi
  run_copy "$(get_codex_config_template "$CLAUDE_PROFILE")" "$TARGET/.codex/config.toml"
}

cmd_add_tool() {
  local tool_name="$1"
  local target="${2:-.}"

  TARGET="$(cd "$target" && pwd)"
  TARGET_BASENAME="$(basename "$TARGET")"

  detect_project_context_mode "$TARGET"
  detect_project_stack "$TARGET"
  detect_project_archetype "$TARGET"

  echo -e "${CYAN}━━━ Add Tool: ${tool_name} ━━━${NC}"
  echo -e "대상: ${TARGET}"

  case "$tool_name" in
    cursor)
      copy_cursor_assets
      echo -e "${GREEN}✅ Cursor 설정 추가 완료${NC}"
      echo "  .cursor/rules/*.mdc"
      ;;
    gemini)
      copy_gemini_assets
      if [ ! -f "$TARGET/GEMINI.md" ]; then
        run_copy "$SCRIPT_DIR/templates/GEMINI.md.template" "$TARGET/GEMINI.md"
        echo "  GEMINI.md 생성됨"
      fi
      echo -e "${GREEN}✅ Gemini CLI 설정 추가 완료${NC}"
      ;;
    copilot)
      copy_copilot_assets
      echo -e "${GREEN}✅ GitHub Copilot 설정 추가 완료${NC}"
      echo "  .github/copilot-instructions.md"
      ;;
    codex)
      copy_codex_assets
      if [ "$MCP_ENABLED" != false ] && [ -f "$TARGET/.codex/config.toml" ]; then
        for preset in "${MCP_PRESETS[@]:-core}"; do
          append_codex_mcp_preset "$preset" "$TARGET/.codex/config.toml"
        done
        echo "  MCP preset 적용됨"
      fi
      echo -e "${GREEN}✅ Codex CLI 설정 추가 완료${NC}"
      ;;
    claude)
      echo -e "${YELLOW}claude는 기본 설치에 포함됩니다. init.sh를 사용하세요.${NC}"
      ;;
    *)
      echo -e "${RED}오류: 알 수 없는 도구 '${tool_name}'${NC}" >&2
      echo "지원 도구: claude, codex, cursor, gemini, copilot"
      return 1
      ;;
  esac
}
