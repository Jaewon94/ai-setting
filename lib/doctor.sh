#!/bin/bash
# lib/doctor.sh — 프로젝트 설정 상태 진단 및 diff preview

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
  local decision_placeholder_count
  local research_placeholder_count
  local claude_ready=false
  local codex_ready=false

  DOCTOR_OK_COUNT=0
  DOCTOR_WARN_COUNT=0
  DOCTOR_ERROR_COUNT=0
  detect_claude_profile "$target"
  detect_shared_asset_mode "$target"

  echo -e "${CYAN}${MSG_DOCTOR_TITLE}${NC}"
  printf "$MSG_DOCTOR_TARGET\n" "$target"
  printf "$MSG_DOCTOR_CLAUDE_PROFILE\n" "$DETECTED_CLAUDE_PROFILE"
  printf "$MSG_DOCTOR_SHARED_ASSET_MODE\n" "$DETECTED_SHARED_ASSET_MODE"
  printf "$MSG_DOCTOR_CONTEXT_MODE\n" "$PROJECT_CONTEXT_MODE"
  printf "$MSG_DOCTOR_PROJECT_TYPE\n" "$PROJECT_ARCHETYPE"
  printf "$MSG_DOCTOR_MAIN_STACK\n" "$PROJECT_STACK"
  echo ""

  if command -v jq &> /dev/null; then
    doctor_ok "$MSG_DOCTOR_JQ_OK"
  else
    doctor_error "$MSG_DOCTOR_JQ_ERR"
  fi

  if command -v npx &> /dev/null; then
    doctor_ok "$MSG_DOCTOR_NPX_OK"
  else
    doctor_warn "$MSG_DOCTOR_NPX_WARN"
  fi

  if command -v uvx &> /dev/null; then
    doctor_ok "$MSG_DOCTOR_UVX_OK"
  else
    doctor_warn "$MSG_DOCTOR_UVX_WARN"
  fi

  if command -v claude &> /dev/null; then
    doctor_ok "$MSG_DOCTOR_CLAUDE_OK"
    if claude --version >/dev/null 2>&1; then
      doctor_ok "$MSG_DOCTOR_CLAUDE_CLI_OK"
      claude_ready=true
    else
      doctor_warn "$MSG_DOCTOR_CLAUDE_CLI_WARN"
    fi
  else
    doctor_warn "$MSG_DOCTOR_CLAUDE_WARN"
  fi

  if command -v codex &> /dev/null; then
    doctor_ok "$MSG_DOCTOR_CODEX_OK"
    if codex exec --help >/dev/null 2>&1; then
      doctor_ok "$MSG_DOCTOR_CODEX_EXEC_OK"
      codex_ready=true
    else
      doctor_warn "$MSG_DOCTOR_CODEX_EXEC_WARN"
    fi
  else
    doctor_warn "$MSG_DOCTOR_CODEX_WARN"
  fi

  if command -v gemini &> /dev/null; then
    doctor_ok "$MSG_DOCTOR_GEMINI_OK"
  else
    doctor_warn "$MSG_DOCTOR_GEMINI_WARN"
  fi

  if [ -f "$target/.claude/settings.json" ]; then
    doctor_ok "$MSG_DOCTOR_SETTINGS_OK"
    if [ "$DETECTED_CLAUDE_PROFILE" = "custom" ]; then
      doctor_warn "$MSG_DOCTOR_SETTINGS_CUSTOM_WARN"
    else
      doctor_ok "$(printf "$MSG_DOCTOR_SETTINGS_PROFILE_OK" "$DETECTED_CLAUDE_PROFILE")"
    fi
  else
    doctor_error "$MSG_DOCTOR_SETTINGS_ERR"
  fi

  if [ -f "$target/.claude/settings.local.json" ]; then
    if command -v jq &>/dev/null && jq empty "$target/.claude/settings.local.json" >/dev/null 2>&1; then
      doctor_ok "$MSG_DOCTOR_SETTINGS_LOCAL_OK"
      # 과도한 permission 경고 (ISS-022)
      local perm_count
      perm_count=$(jq '[.permissions // {} | .allow // [] | .[] | select(test("curl|wget|pip install|npm install|chmod|chown|sudo"))] | length' "$target/.claude/settings.local.json" 2>/dev/null || echo 0)
      if [ "$perm_count" -gt 0 ]; then
        doctor_warn "$(printf "$MSG_DOCTOR_SETTINGS_LOCAL_PERM_WARN" "$perm_count")"
      fi
    elif command -v jq &>/dev/null; then
      doctor_error "$MSG_DOCTOR_SETTINGS_LOCAL_JSON_ERR"
    else
      doctor_warn "$MSG_DOCTOR_SETTINGS_LOCAL_NOJQ_WARN"
    fi
  fi

  if [ -f "$target/.cursor/rules/ai-setting.mdc" ]; then
    doctor_ok "$MSG_DOCTOR_CURSOR_OK"
  else
    doctor_warn "$MSG_DOCTOR_CURSOR_WARN"
  fi

  if [ -f "$target/.gemini/settings.json" ]; then
    doctor_ok "$MSG_DOCTOR_GEMINI_SETTINGS_OK"
  else
    doctor_warn "$MSG_DOCTOR_GEMINI_SETTINGS_WARN"
  fi

  if [ -f "$target/GEMINI.md" ]; then
    doctor_ok "$MSG_DOCTOR_GEMINIMD_OK"
  else
    doctor_warn "$MSG_DOCTOR_GEMINIMD_WARN"
  fi

  if [ -f "$target/BEHAVIORAL_CORE.md" ]; then
    doctor_ok "$MSG_DOCTOR_BEHAVIORAL_OK"
  else
    doctor_warn "$MSG_DOCTOR_BEHAVIORAL_WARN"
  fi

  if [ -f "$target/docs/research-notes.md" ]; then
    doctor_ok "$MSG_DOCTOR_RESEARCH_OK"
  else
    doctor_warn "$MSG_DOCTOR_RESEARCH_WARN"
  fi

  if [ -f "$target/.github/copilot-instructions.md" ]; then
    doctor_ok "$MSG_DOCTOR_COPILOT_OK"
  else
    doctor_warn "$MSG_DOCTOR_COPILOT_WARN"
  fi

  if [ -d "$target/.github/instructions" ]; then
    doctor_ok "$MSG_DOCTOR_INSTRUCTIONS_DIR_OK"
  else
    doctor_warn "$MSG_DOCTOR_INSTRUCTIONS_DIR_WARN"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "team" ]; then
    if [ -x "$target/.claude/hooks/team-webhook-notify.sh" ]; then
      doctor_ok "$MSG_DOCTOR_TEAM_HOOK_OK"
    else
      doctor_error "$MSG_DOCTOR_TEAM_HOOK_ERR"
    fi

    if [ -f "$target/.github/pull_request_template.md" ]; then
      doctor_ok "$MSG_DOCTOR_TEAM_PR_OK"
    else
      doctor_error "$MSG_DOCTOR_TEAM_PR_ERR"
    fi

    if [ -f "$target/.ai-setting/team-webhook.json" ]; then
      doctor_ok "$MSG_DOCTOR_TEAM_WEBHOOK_OK"
      if command -v jq >/dev/null 2>&1; then
        if [ "$(jq -r '.enabled // false' "$target/.ai-setting/team-webhook.json")" = "true" ]; then
          local webhook_url
          local webhook_url_env
          webhook_url="$(jq -r '.url // empty' "$target/.ai-setting/team-webhook.json")"
          webhook_url_env="$(jq -r '.url_env // "AI_SETTING_TEAM_WEBHOOK_URL"' "$target/.ai-setting/team-webhook.json")"
          if [ -n "$webhook_url" ] || [ -n "${!webhook_url_env:-}" ]; then
            doctor_ok "$MSG_DOCTOR_TEAM_WEBHOOK_ACTIVE_OK"
          else
            doctor_warn "$MSG_DOCTOR_TEAM_WEBHOOK_NOURL_WARN"
          fi
        else
          doctor_ok "$MSG_DOCTOR_TEAM_WEBHOOK_DEFAULT_OK"
        fi
      else
        doctor_warn "$MSG_DOCTOR_TEAM_WEBHOOK_NOJQ_WARN"
      fi
    else
      doctor_error "$MSG_DOCTOR_TEAM_WEBHOOK_ERR"
    fi
  fi

  if [ -x "$target/.claude/hooks/protect-files.sh" ]; then
    doctor_ok "$MSG_DOCTOR_PROTECT_OK"
  else
    doctor_error "$MSG_DOCTOR_PROTECT_ERR"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "$MSG_DOCTOR_MINIMAL_BLOCK_OK"
  elif [ -x "$target/.claude/hooks/block-dangerous-commands.sh" ]; then
    doctor_ok "$MSG_DOCTOR_BLOCK_OK"
  else
    doctor_error "$MSG_DOCTOR_BLOCK_ERR"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "$MSG_DOCTOR_MINIMAL_SESSION_OK"
  elif [ -x "$target/.claude/hooks/session-context.sh" ]; then
    doctor_ok "$MSG_DOCTOR_SESSION_OK"
  else
    doctor_error "$MSG_DOCTOR_SESSION_ERR"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "$MSG_DOCTOR_MINIMAL_COMPACT_OK"
  elif [ -x "$target/.claude/hooks/compact-backup.sh" ]; then
    doctor_ok "$MSG_DOCTOR_COMPACT_OK"
  else
    doctor_error "$MSG_DOCTOR_COMPACT_ERR"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "$MSG_DOCTOR_MINIMAL_ASYNC_OK"
  elif [ -x "$target/.claude/hooks/async-test.sh" ]; then
    doctor_ok "$MSG_DOCTOR_ASYNC_OK"
    detect_async_test_strategy "$target"
    case "$ASYNC_TEST_STRATEGY" in
      project-file)
        doctor_ok "$MSG_DOCTOR_ASYNC_PROJECT_FILE_OK"
        ;;
      env)
        doctor_ok "$MSG_DOCTOR_ASYNC_ENV_OK"
        ;;
      auto-*)
        doctor_ok "$(printf "$MSG_DOCTOR_ASYNC_AUTO_OK" "$ASYNC_TEST_COMMAND_PREVIEW")"
        ;;
      *)
        doctor_warn "$MSG_DOCTOR_ASYNC_WARN"
        ;;
    esac
  else
    doctor_error "$MSG_DOCTOR_ASYNC_ERR"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "strict" ] || [ "$DETECTED_CLAUDE_PROFILE" = "team" ]; then
    if [ -x "$target/.claude/hooks/protect-main-branch.sh" ]; then
      doctor_ok "$MSG_DOCTOR_BRANCH_PROTECT_OK"
    else
      doctor_error "$MSG_DOCTOR_BRANCH_PROTECT_ERR"
    fi
  fi

  if [ -f "$target/.codex/config.toml" ]; then
    doctor_ok "$MSG_DOCTOR_CODEX_CONFIG_OK"
  else
    doctor_warn "$MSG_DOCTOR_CODEX_CONFIG_WARN"
  fi

  if [ -f "$target/.mcp.json" ]; then
    if command -v jq &> /dev/null && jq empty "$target/.mcp.json" >/dev/null 2>&1; then
      doctor_ok "$MSG_DOCTOR_MCP_JSON_OK"
    elif command -v jq &> /dev/null; then
      doctor_error "$MSG_DOCTOR_MCP_JSON_ERR"
    else
      doctor_warn "$MSG_DOCTOR_MCP_NOJQ_WARN"
    fi
  else
    doctor_warn "$MSG_DOCTOR_MCP_MISSING_WARN"
  fi

  if [ -f "$target/CLAUDE.md" ]; then
    doctor_ok "$MSG_DOCTOR_CLAUDEMD_OK"
  else
    doctor_error "$MSG_DOCTOR_CLAUDEMD_ERR"
  fi

  if [ -f "$target/AGENTS.md" ]; then
    doctor_ok "$MSG_DOCTOR_AGENTSMD_OK"
  else
    doctor_error "$MSG_DOCTOR_AGENTSMD_ERR"
  fi

  if [ -f "$target/docs/decisions.md" ]; then
    doctor_ok "$MSG_DOCTOR_DECISIONSMD_OK"
  else
    doctor_warn "$MSG_DOCTOR_DECISIONSMD_WARN"
  fi

  if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ]; then
    doctor_ok "$MSG_DOCTOR_BLANKSTART_OK"
    if [ -n "$USER_PROJECT_NAME_HINT" ] || [ -n "$USER_ARCHETYPE_HINT" ] || [ -n "$USER_STACK_HINT" ]; then
      doctor_ok "$MSG_DOCTOR_BLANKSTART_HINTS_OK"
    else
      doctor_warn "$MSG_DOCTOR_BLANKSTART_NOHINT_WARN"
    fi
  fi

  if [ "$claude_ready" = true ] && [ "$codex_ready" = true ]; then
    doctor_ok "$MSG_DOCTOR_AI_BOTH_OK"
  elif [ "$claude_ready" = true ]; then
    doctor_ok "$MSG_DOCTOR_AI_CLAUDE_OK"
  elif [ "$codex_ready" = true ]; then
    doctor_ok "$MSG_DOCTOR_AI_CODEX_OK"
  else
    doctor_warn "$MSG_DOCTOR_AI_NONE_WARN"
  fi

  if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ]; then
    doctor_ok "$MSG_DOCTOR_BLANKSTART_PLACEHOLDER_OK"
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
      doctor_ok "$MSG_DOCTOR_PLACEHOLDER_NONE_OK"
    else
      doctor_warn "$MSG_DOCTOR_PLACEHOLDER_WARN"
    fi

    decision_placeholder_count=0
    research_placeholder_count=0

    if [ -f "$target/docs/decisions.md" ]; then
      decision_placeholder_count=$(rg -o '\[(결정 제목|선택한 것|검토한 대안들|R-001, R-002 또는 없음|YYYY-MM-DD|문서명|URL|왜 이것을 선택했는지|이 선택의 단점/한계)\]' "$target/docs/decisions.md" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$decision_placeholder_count" -eq 0 ]; then
        doctor_ok "$MSG_DOCTOR_DECISIONS_PLACEHOLDER_OK"
      else
        doctor_warn "$MSG_DOCTOR_DECISIONS_PLACEHOLDER_WARN"
      fi

      if rg -q '^\- \*\*관련 조사\*\*: R-[0-9]{3}(, R-[0-9]{3})*$' "$target/docs/decisions.md" 2>/dev/null || \
         rg -q '^\- \*\*관련 조사\*\*: 없음$' "$target/docs/decisions.md" 2>/dev/null; then
        doctor_ok "$MSG_DOCTOR_DECISIONS_REF_OK"
      else
        doctor_warn "$MSG_DOCTOR_DECISIONS_REF_WARN"
      fi

      if rg -q '^\- \*\*확인일\*\*: [0-9]{4}-[0-9]{2}-[0-9]{2}$' "$target/docs/decisions.md" 2>/dev/null; then
        doctor_ok "$MSG_DOCTOR_DECISIONS_DATE_OK"
      else
        doctor_warn "$MSG_DOCTOR_DECISIONS_DATE_WARN"
      fi

      if rg -q '^  - .+ — https?://.+' "$target/docs/decisions.md" 2>/dev/null; then
        doctor_ok "$MSG_DOCTOR_DECISIONS_LINK_OK"
      else
        doctor_warn "$MSG_DOCTOR_DECISIONS_LINK_WARN"
      fi
    fi

    if [ -f "$target/docs/research-notes.md" ]; then
      research_placeholder_count=$(rg -o '\[(조사 주제|YYYY-MM-DD|왜 이 조사가 필요했는지|문서명|URL|출처에서 확인한 중요한 사실 1|출처에서 확인한 중요한 사실 2|이 조사로 인해 어떤 판단을 했는지|D-001 또는 없음)\]' "$target/docs/research-notes.md" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$research_placeholder_count" -eq 0 ]; then
        doctor_ok "$MSG_DOCTOR_RESEARCH_PLACEHOLDER_OK"
      else
        doctor_warn "$MSG_DOCTOR_RESEARCH_PLACEHOLDER_WARN"
      fi

      if rg -q '^### R-[0-9]{3}:' "$target/docs/research-notes.md" 2>/dev/null; then
        doctor_ok "$MSG_DOCTOR_RESEARCH_ID_OK"
      else
        doctor_warn "$MSG_DOCTOR_RESEARCH_ID_WARN"
      fi

      if rg -q '^\- \*\*확인일\*\*: [0-9]{4}-[0-9]{2}-[0-9]{2}$' "$target/docs/research-notes.md" 2>/dev/null; then
        doctor_ok "$MSG_DOCTOR_RESEARCH_DATE_OK"
      else
        doctor_warn "$MSG_DOCTOR_RESEARCH_DATE_WARN"
      fi

      if rg -q '^  - .+ — https?://.+' "$target/docs/research-notes.md" 2>/dev/null; then
        doctor_ok "$MSG_DOCTOR_RESEARCH_LINK_OK"
      else
        doctor_warn "$MSG_DOCTOR_RESEARCH_LINK_WARN"
      fi

      if rg -q '^\- \*\*관련 결정\*\*: D-[0-9]{3}$' "$target/docs/research-notes.md" 2>/dev/null || \
         rg -q '^\- \*\*관련 결정\*\*: 없음$' "$target/docs/research-notes.md" 2>/dev/null; then
        doctor_ok "$MSG_DOCTOR_RESEARCH_DECISION_OK"
      else
        doctor_warn "$MSG_DOCTOR_RESEARCH_DECISION_WARN"
      fi
    fi

    if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
      doctor_ok "$MSG_DOCTOR_MINIMAL_SKILLS_OK"
    else
      skill_placeholder_count=$(rg -o '\{\{[A-Z0-9_]+\}\}' "$target/.claude/skills" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$skill_placeholder_count" -eq 0 ]; then
        doctor_ok "$MSG_DOCTOR_SKILLS_PLACEHOLDER_OK"
      else
        doctor_warn "$MSG_DOCTOR_SKILLS_PLACEHOLDER_WARN"
      fi
    fi
  fi

  echo ""
  echo -e "${CYAN}${MSG_DOCTOR_SUMMARY_TITLE}${NC}"
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

  managed_paths=(".claude" ".codex/config.toml" "CLAUDE.md" "AGENTS.md" "docs/decisions.md" "docs/research-notes.md")
  managed_paths+=(".cursor/rules/ai-setting.mdc" ".gemini/settings.json" "GEMINI.md" "BEHAVIORAL_CORE.md" ".github/copilot-instructions.md" ".github/instructions/typescript.instructions.md" ".github/instructions/python.instructions.md" ".github/instructions/testing.instructions.md" ".github/pull_request_template.md" ".ai-setting/team-webhook.json")
  if [ "$MCP_ENABLED" = true ]; then
    managed_paths+=(".mcp.json" ".mcp.notes.md")
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
    echo -e "${RED}${MSG_DIFF_PREVIEW_FAIL}${NC}" >&2
    cat "$internal_log" >&2
    rm -rf "$staging_dir"
    rm -f "$internal_log"
    return 1
  fi

  echo -e "${CYAN}${MSG_DIFF_TITLE}${NC}"
  printf "$MSG_DIFF_TARGET\n" "$target"
  printf "$MSG_DIFF_CONTEXT_MODE\n" "$PROJECT_CONTEXT_MODE"
  printf "$MSG_DIFF_PROJECT_TYPE\n" "$PROJECT_ARCHETYPE"
  printf "$MSG_DIFF_MAIN_STACK\n" "$PROJECT_STACK"
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
      printf "${RED}${MSG_DIFF_OUTPUT_FAIL}${NC}\n" "$managed_path" >&2
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
    echo "$MSG_DIFF_NO_CHANGES"
  fi

  echo ""
  echo "$MSG_DIFF_NOTE"

  rm -rf "$staging_dir"
  rm -f "$internal_log"
  return 0
}
