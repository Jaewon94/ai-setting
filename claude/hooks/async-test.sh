#!/bin/bash
# async-test.sh — Best-effort background test runner for code edits
# PostToolUse hook for Edit|Write tools

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MODE="${1:-trigger}"
CONTEXT_DIR="$PROJECT_DIR/.claude/context"
STATUS_FILE="$CONTEXT_DIR/async-test-status.md"
LOG_FILE="$CONTEXT_DIR/async-test.log"
PID_FILE="$CONTEXT_DIR/async-test.pid"
CONFIG_FILE="$PROJECT_DIR/.ai-setting/test-command"

ensure_context_dir() {
  mkdir -p "$CONTEXT_DIR" 2>/dev/null || true
}

first_non_comment_line() {
  local path="$1"

  awk '
    {
      sub(/\r$/, "")
      if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) {
        next
      }
      print
      exit
    }
  ' "$path"
}

is_code_file() {
  local path="$1"

  case "$path" in
    *.py|*.pyi|*.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.go|*.rs|*.java|*.kt|*.kts|*.rb|*.php|*.cs)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

cleanup_stale_pid() {
  local pid

  if [ ! -f "$PID_FILE" ]; then
    return
  fi

  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE"
  fi
}

write_status() {
  local status="$1"
  local trigger_file="$2"
  local command="${3:-}"
  local command_source="${4:-}"
  local note="${5:-}"
  local pid=""

  ensure_context_dir

  if [ -f "$PID_FILE" ]; then
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  fi

  {
    echo "# Async Test Status"
    echo
    echo "- updated_at: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "- status: $status"
    if [ -n "$trigger_file" ]; then
      echo "- trigger_file: $trigger_file"
    fi
    if [ -n "$command_source" ]; then
      echo "- command_source: $command_source"
    fi
    if [ -n "$command" ]; then
      echo "- command: \`$command\`"
    fi
    echo "- log_file: .claude/context/async-test.log"
    if [ -n "$pid" ]; then
      echo "- pid: $pid"
    fi
    if [ -n "$note" ]; then
      echo
      echo "$note"
    fi
  } > "$STATUS_FILE"
}

detect_auto_command() {
  if [ -f "$PROJECT_DIR/uv.lock" ] && { [ -d "$PROJECT_DIR/tests" ] || [ -f "$PROJECT_DIR/pytest.ini" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; }; then
    ASYNC_TEST_COMMAND="uv run pytest -q"
    ASYNC_TEST_COMMAND_SOURCE="auto-python-uv"
    return 0
  fi

  if [ -f "$PROJECT_DIR/pytest.ini" ] || { [ -d "$PROJECT_DIR/tests" ] && { [ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/requirements-dev.txt" ]; }; }; then
    ASYNC_TEST_COMMAND="pytest -q"
    ASYNC_TEST_COMMAND_SOURCE="auto-python-pytest"
    return 0
  fi

  if [ -f "$PROJECT_DIR/go.mod" ]; then
    ASYNC_TEST_COMMAND="go test ./..."
    ASYNC_TEST_COMMAND_SOURCE="auto-go"
    return 0
  fi

  if [ -f "$PROJECT_DIR/Cargo.toml" ]; then
    ASYNC_TEST_COMMAND="cargo test --quiet"
    ASYNC_TEST_COMMAND_SOURCE="auto-rust"
    return 0
  fi

  # monorepo: 하위 디렉토리에서 테스트 환경 탐색
  local subdir
  for subdir in backend server api app; do
    if [ -d "$PROJECT_DIR/$subdir" ]; then
      if [ -f "$PROJECT_DIR/$subdir/uv.lock" ] && { [ -d "$PROJECT_DIR/$subdir/tests" ] || [ -f "$PROJECT_DIR/$subdir/pyproject.toml" ]; }; then
        ASYNC_TEST_COMMAND="cd $subdir && uv run pytest -q"
        ASYNC_TEST_COMMAND_SOURCE="auto-monorepo-python-uv"
        return 0
      fi
      if { [ -d "$PROJECT_DIR/$subdir/tests" ] || [ -f "$PROJECT_DIR/$subdir/pytest.ini" ]; } && { [ -f "$PROJECT_DIR/$subdir/pyproject.toml" ] || [ -f "$PROJECT_DIR/$subdir/requirements.txt" ]; }; then
        ASYNC_TEST_COMMAND="cd $subdir && pytest -q"
        ASYNC_TEST_COMMAND_SOURCE="auto-monorepo-python-pytest"
        return 0
      fi
      if [ -f "$PROJECT_DIR/$subdir/go.mod" ]; then
        ASYNC_TEST_COMMAND="cd $subdir && go test ./..."
        ASYNC_TEST_COMMAND_SOURCE="auto-monorepo-go"
        return 0
      fi
    fi
  done

  # monorepo: frontend 하위 디렉토리
  for subdir in frontend web client; do
    if [ -d "$PROJECT_DIR/$subdir" ] && [ -f "$PROJECT_DIR/$subdir/package.json" ]; then
      if grep -q '"vitest\|"jest\|"test"' "$PROJECT_DIR/$subdir/package.json" 2>/dev/null; then
        ASYNC_TEST_COMMAND="cd $subdir && npm test --if-present"
        ASYNC_TEST_COMMAND_SOURCE="auto-monorepo-node"
        return 0
      fi
    fi
  done

  return 1
}

resolve_command() {
  local configured_command=""

  if [ -f "$CONFIG_FILE" ]; then
    configured_command="$(first_non_comment_line "$CONFIG_FILE" || true)"
    if [ -n "$configured_command" ]; then
      ASYNC_TEST_COMMAND="$configured_command"
      ASYNC_TEST_COMMAND_SOURCE="project-file"
      return 0
    fi
  fi

  if [ -n "${AI_SETTING_ASYNC_TEST_CMD:-}" ]; then
    ASYNC_TEST_COMMAND="$AI_SETTING_ASYNC_TEST_CMD"
    ASYNC_TEST_COMMAND_SOURCE="env"
    return 0
  fi

  detect_auto_command
}

run_background_test() {
  local exit_code=0

  ensure_context_dir
  write_status "running" "${ASYNC_TEST_TRIGGER_FILE:-}" "${ASYNC_TEST_COMMAND:-}" "${ASYNC_TEST_COMMAND_SOURCE:-}" "백그라운드 테스트가 실행 중입니다."

  if (
    cd "$PROJECT_DIR"
    bash -c "${ASYNC_TEST_COMMAND:-}"
  ) >"$LOG_FILE" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi

  rm -f "$PID_FILE"

  if [ "$exit_code" -eq 0 ]; then
    write_status "success" "${ASYNC_TEST_TRIGGER_FILE:-}" "${ASYNC_TEST_COMMAND:-}" "${ASYNC_TEST_COMMAND_SOURCE:-}" "최근 백그라운드 테스트가 성공했습니다."
  else
    write_status "failure" "${ASYNC_TEST_TRIGGER_FILE:-}" "${ASYNC_TEST_COMMAND:-}" "${ASYNC_TEST_COMMAND_SOURCE:-}" "최근 백그라운드 테스트가 실패했습니다. 로그를 확인하세요."
  fi
}

trigger_async_test() {
  local input
  local file=""
  local bg_pid=""

  ensure_context_dir
  cleanup_stale_pid

  if ! command -v jq >/dev/null 2>&1; then
    write_status "skipped" "" "" "disabled" "jq가 없어 async-test hook 입력을 해석하지 못했습니다."
    exit 0
  fi

  input="$(cat)"
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"

  if [ -z "$file" ] || ! is_code_file "$file"; then
    exit 0
  fi

  if [ -f "$PID_FILE" ]; then
    write_status "running" "$file" "" "existing-job" "이미 실행 중인 async test job이 있어 이번 변경에서는 새로 시작하지 않았습니다."
    exit 0
  fi

  if ! resolve_command; then
    write_status "skipped" "$file" "" "unconfigured" "비동기 테스트 명령이 설정되지 않았습니다. `.ai-setting/test-command`를 만들거나 `AI_SETTING_ASYNC_TEST_CMD`를 지정하면 자동 실행할 수 있습니다. 자동 감지는 Python/Go/Rust만 1차 지원합니다."
    exit 0
  fi

  ASYNC_TEST_TRIGGER_FILE="$file" \
  ASYNC_TEST_COMMAND="$ASYNC_TEST_COMMAND" \
  ASYNC_TEST_COMMAND_SOURCE="$ASYNC_TEST_COMMAND_SOURCE" \
  nohup "$0" run >/dev/null 2>&1 &
  bg_pid=$!
  printf '%s\n' "$bg_pid" > "$PID_FILE"
  write_status "running" "$file" "$ASYNC_TEST_COMMAND" "$ASYNC_TEST_COMMAND_SOURCE" "백그라운드 테스트를 시작했습니다."
}

case "$MODE" in
  trigger)
    trigger_async_test
    ;;
  run)
    run_background_test
    ;;
  *)
    echo "usage: async-test.sh [trigger|run]" >&2
    exit 1
    ;;
esac
