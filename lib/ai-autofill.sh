#!/bin/bash
# lib/ai-autofill.sh — AI autofill flow, prompt generation, and fallback helpers

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

set_ai_profile_guidance() {
  case "$CLAUDE_PROFILE" in
    minimal)
      AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 minimal profile을 사용하므로 managed agents/skills를 새로 만들거나 복원하지 마.
- `.claude/skills`가 없으면 생성하지 말고, skills 전용 placeholder도 건드릴 수 없으면 그대로 둬.
EOF
)
      AI_SKILL_TASK="4. minimal profile이므로 .claude/skills/ 관련 파일이 이미 없으면 새로 만들지 마. 존재하는 경우에만 {{중괄호}} 플레이스홀더를 프로젝트에 맞게 교체해."
      ;;
    strict)
      AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 strict profile을 사용하므로 검증, 문서 동기화, feature branch 사용 원칙을 더 엄격하게 반영해.
- main/master 직접 작업 대신 feature branch + PR 흐름을 자연스럽게 유도해.
EOF
)
      AI_SKILL_TASK="4. .claude/skills/ 안의 SKILL.md 파일들에서 {{중괄호}} 플레이스홀더({{TEST_CMD}}, {{LINT_CMD}}, {{DEPLOY_BACKEND_CMD}} 등)를 프로젝트에 맞는 실제 명령어로 교체해줘."
      ;;
    team)
      AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 team profile을 사용하므로 협업, PR 설명, 검증 기록이 드러나도록 문서를 정리해.
- main/master 직접 작업 대신 feature branch + PR 흐름을 자연스럽게 유도해.
EOF
)
      AI_SKILL_TASK="4. .claude/skills/ 안의 SKILL.md 파일들에서 {{중괄호}} 플레이스홀더({{TEST_CMD}}, {{LINT_CMD}}, {{DEPLOY_BACKEND_CMD}} 등)를 프로젝트에 맞는 실제 명령어로 교체해줘."
      ;;
    *)
      AI_PROFILE_GUIDANCE=$(cat <<'EOF'
Claude 프로필 지침:
- 현재 프로젝트는 standard profile을 사용하므로 managed skills placeholder도 함께 실제 명령어로 치환해.
EOF
)
      AI_SKILL_TASK="4. .claude/skills/ 안의 SKILL.md 파일들에서 {{중괄호}} 플레이스홀더({{TEST_CMD}}, {{LINT_CMD}}, {{DEPLOY_BACKEND_CMD}} 등)를 프로젝트에 맞는 실제 명령어로 교체해줘."
      ;;
  esac
}

fill_rule_based_placeholders() {
  local test_backend_cmd="" test_frontend_cmd="" lint_cmd="" deploy_backend_cmd=""
  local deploy_frontend_cmd="" test_cmd="" deploy_cmd=""
  local files_to_process=()
  local replacements=()
  local replaced=0 file f

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

  test_cmd="${test_cmd:-${test_backend_cmd:-${test_frontend_cmd:-"# TODO: 테스트 명령을 설정하세요"}}}"
  lint_cmd="${lint_cmd:-"# TODO: 린트 명령을 설정하세요"}"
  deploy_backend_cmd="${deploy_backend_cmd:-"# TODO: 백엔드 배포 명령을 설정하세요"}"
  deploy_frontend_cmd="${deploy_frontend_cmd:-"# TODO: 프론트엔드 배포 명령을 설정하세요"}"
  deploy_cmd="${deploy_cmd:-"# TODO: 배포 명령을 설정하세요"}"

  replacements=(
    "[프로젝트명]" "$PROJECT_NAME"
    "{{TEST_BACKEND_CMD}}" "$test_backend_cmd"
    "{{TEST_FRONTEND_CMD}}" "$test_frontend_cmd"
    "{{TEST_CMD}}" "$test_cmd"
    "{{LINT_CMD}}" "$lint_cmd"
    "{{DEPLOY_BACKEND_CMD}}" "$deploy_backend_cmd"
    "{{DEPLOY_FRONTEND_CMD}}" "$deploy_frontend_cmd"
    "{{DEPLOY_CMD}}" "$deploy_cmd"
  )

  [ -f "$TARGET/docs/decisions.md" ] && files_to_process+=("$TARGET/docs/decisions.md")
  [ -f "$TARGET/docs/research-notes.md" ] && files_to_process+=("$TARGET/docs/research-notes.md")

  if [ -d "$TARGET/.claude/skills" ]; then
    while IFS= read -r -d '' f; do
      files_to_process+=("$f")
  done < <(find "$TARGET/.claude/skills" -name "SKILL.md" -print0 2>/dev/null)
  fi

  for file in "${files_to_process[@]}"; do
    if replace_literals_in_file "$file" "${replacements[@]}"; then
      replaced=$((replaced + 1))
    fi
  done

  if [ "$replaced" -gt 0 ]; then
    printf "$MSG_INIT_AI_RULE_BASED_OK\n" "$replaced"
  fi
}

build_ai_prompt() {
  set_ai_profile_guidance
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
}

run_claude_autofill() {
  local claude_timeout_seconds="$1"
  local claude_status

  if ! command -v claude >/dev/null 2>&1; then
    echo -e "  ${YELLOW}${MSG_INIT_AI_CLAUDE_MISSING}${NC}"
    return 1
  fi

  printf "  ${MSG_INIT_AI_CLAUDE_RUNNING}\n" "$claude_timeout_seconds"
  (
    cd "$TARGET" &&
    run_with_timeout "$claude_timeout_seconds" claude -p "$AI_PROMPT" --allowedTools Write,Edit,Read,Glob,Grep 2>/dev/null
  )
  claude_status=$?
  if [ "$claude_status" -eq 0 ]; then
    echo "$MSG_INIT_AI_CLAUDE_OK"
    return 0
  fi

  if [ "$claude_status" -eq 124 ]; then
    printf "  ${YELLOW}${MSG_INIT_AI_CLAUDE_TIMEOUT}${NC}\n" "$claude_timeout_seconds"
  else
    echo -e "  ${YELLOW}${MSG_INIT_AI_CLAUDE_FAIL}${NC}"
  fi
  return 1
}

run_codex_autofill() {
  if ! command -v codex >/dev/null 2>&1; then
    echo -e "  ${YELLOW}${MSG_INIT_AI_CODEX_MISSING}${NC}"
    return 1
  fi

  echo "$MSG_INIT_AI_CODEX_RUNNING"
  if (cd "$TARGET" && codex exec --skip-git-repo-check "$AI_PROMPT") 2>/dev/null; then
    echo "$MSG_INIT_AI_CODEX_OK"
    return 0
  fi

  echo -e "  ${YELLOW}${MSG_INIT_AI_CODEX_FAIL}${NC}"
  return 1
}

print_manual_autofill_fallback() {
  echo ""
  echo -e "  ${RED}${MSG_INIT_AI_MANUAL_TITLE}${NC}"
  echo -e "  $MSG_INIT_AI_MANUAL_DESC"
  echo ""
  echo -e "  ${CYAN}${MSG_INIT_AI_MANUAL_HEADER}${NC}"
  echo "$MSG_INIT_AI_MANUAL_STEP1"
  echo "$MSG_INIT_AI_MANUAL_STEP2"
  echo "$MSG_INIT_AI_MANUAL_CMD"
  echo ""
}

run_ai_autofill_step() {
  local claude_timeout_seconds

  echo -e "${GREEN}${MSG_INIT_STEP6}${NC}"

  if [ "$UPDATE_MODE" = true ]; then
    echo -e "  ${YELLOW}${MSG_INIT_AI_UPDATE_SKIP}${NC}"
    return
  fi
  if [ "$SKIP_AI" = true ]; then
    echo -e "  ${YELLOW}${MSG_INIT_AI_SKIPAI}${NC}"
    fill_rule_based_placeholders
    return
  fi
  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${YELLOW}${MSG_INIT_AI_DRYRUN_SKIP}${NC}"
    return
  fi
  if [ "$PROJECT_CONTEXT_MODE" = "blank-start" ] && [ "$HAS_USER_GUIDANCE" = false ]; then
    echo "  mode: ${PROJECT_CONTEXT_MODE} (${PROJECT_CONTEXT_REASON})"
    echo -e "  ${YELLOW}${MSG_INIT_AI_BLANKSTART_SKIP}${NC}"
    echo "  $MSG_INIT_AI_BLANKSTART_HINT"
    return
  fi
  if [ "$TEMPLATES_COPIED" = false ]; then
    echo -e "  ${YELLOW}${MSG_INIT_AI_NO_TEMPLATES}${NC}"
    return
  fi

  build_ai_prompt
  claude_timeout_seconds="${AI_SETTING_CLAUDE_TIMEOUT_SEC:-20}"

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

  if run_claude_autofill "$claude_timeout_seconds"; then
    return
  fi
  if run_codex_autofill; then
    return
  fi

  print_manual_autofill_fallback
}
