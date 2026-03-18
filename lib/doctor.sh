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

  if [ -f "$target/.claude/settings.local.json" ]; then
    if command -v jq &>/dev/null && jq empty "$target/.claude/settings.local.json" >/dev/null 2>&1; then
      doctor_ok ".claude/settings.local.json 존재 (유효한 JSON)"
    elif command -v jq &>/dev/null; then
      doctor_error ".claude/settings.local.json JSON 형식이 올바르지 않음"
    else
      doctor_warn ".claude/settings.local.json 존재하지만 jq가 없어 형식 검증은 건너뜀"
    fi
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

  if [ -f "$target/CODEX.md" ]; then
    doctor_ok "CODEX.md 존재"
  else
    doctor_warn "CODEX.md 없음 — Codex CLI 프로젝트 컨텍스트가 아직 생성되지 않았을 수 있음"
  fi

  if [ -f "$target/.github/copilot-instructions.md" ]; then
    doctor_ok ".github/copilot-instructions.md 존재"
  else
    doctor_warn ".github/copilot-instructions.md 없음 — GitHub Copilot 지원 파일이 아직 생성되지 않았을 수 있음"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "team" ]; then
    if [ -x "$target/.claude/hooks/team-webhook-notify.sh" ]; then
      doctor_ok ".claude/hooks/team-webhook-notify.sh 실행 가능"
    else
      doctor_error ".claude/hooks/team-webhook-notify.sh 없음 또는 실행 권한 없음"
    fi

    if [ -f "$target/.github/pull_request_template.md" ]; then
      doctor_ok ".github/pull_request_template.md 존재"
    else
      doctor_error ".github/pull_request_template.md 없음"
    fi

    if [ -f "$target/.ai-setting/team-webhook.json" ]; then
      doctor_ok ".ai-setting/team-webhook.json 존재"
      if command -v jq >/dev/null 2>&1; then
        if [ "$(jq -r '.enabled // false' "$target/.ai-setting/team-webhook.json")" = "true" ]; then
          local webhook_url
          local webhook_url_env
          webhook_url="$(jq -r '.url // empty' "$target/.ai-setting/team-webhook.json")"
          webhook_url_env="$(jq -r '.url_env // "AI_SETTING_TEAM_WEBHOOK_URL"' "$target/.ai-setting/team-webhook.json")"
          if [ -n "$webhook_url" ] || [ -n "${!webhook_url_env:-}" ]; then
            doctor_ok "team webhook 활성화 설정 감지"
          else
            doctor_warn "team webhook 활성화 상태이지만 URL이 비어 있음"
          fi
        else
          doctor_ok "team webhook 기본 비활성 상태"
        fi
      else
        doctor_warn "jq가 없어 team-webhook.json 세부 검증은 건너뜀"
      fi
    else
      doctor_error ".ai-setting/team-webhook.json 없음"
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

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "minimal 프로필 — session-context hook 비활성"
  elif [ -x "$target/.claude/hooks/session-context.sh" ]; then
    doctor_ok ".claude/hooks/session-context.sh 실행 가능"
  else
    doctor_error ".claude/hooks/session-context.sh 없음 또는 실행 권한 없음"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "minimal 프로필 — compact-backup hook 비활성"
  elif [ -x "$target/.claude/hooks/compact-backup.sh" ]; then
    doctor_ok ".claude/hooks/compact-backup.sh 실행 가능"
  else
    doctor_error ".claude/hooks/compact-backup.sh 없음 또는 실행 권한 없음"
  fi

  if [ "$DETECTED_CLAUDE_PROFILE" = "minimal" ]; then
    doctor_ok "minimal 프로필 — async-test hook 비활성"
  elif [ -x "$target/.claude/hooks/async-test.sh" ]; then
    doctor_ok ".claude/hooks/async-test.sh 실행 가능"
    detect_async_test_strategy "$target"
    case "$ASYNC_TEST_STRATEGY" in
      project-file)
        doctor_ok "async test 명령 파일 존재 (.ai-setting/test-command)"
        ;;
      env)
        doctor_ok "async test 명령 환경변수 감지 (AI_SETTING_ASYNC_TEST_CMD)"
        ;;
      auto-*)
        doctor_ok "async test 자동 감지 가능 (${ASYNC_TEST_COMMAND_PREVIEW})"
        ;;
      *)
        doctor_warn "async test 명령 미설정 — .ai-setting/test-command 또는 AI_SETTING_ASYNC_TEST_CMD 권장"
        ;;
    esac
  else
    doctor_error ".claude/hooks/async-test.sh 없음 또는 실행 권한 없음"
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
  managed_paths+=(".cursor/rules/ai-setting.mdc" ".gemini/settings.json" "GEMINI.md" ".github/copilot-instructions.md" ".github/pull_request_template.md" ".ai-setting/team-webhook.json")
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
