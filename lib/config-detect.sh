#!/bin/bash
# lib/config-detect.sh — 기존 설정 감지 (프로필, 공유 자산 모드, async test 전략)

detect_claude_profile() {
  local target="$1"
  local settings_path="$target/.claude/settings.json"
  local standard_template
  local minimal_template
  local strict_template
  local team_template

  standard_template="$SCRIPT_DIR/claude/settings.json"
  minimal_template="$SCRIPT_DIR/claude/settings.minimal.json"
  strict_template="$SCRIPT_DIR/claude/settings.strict.json"
  team_template="$SCRIPT_DIR/claude/settings.team.json"

  if [ ! -f "$settings_path" ]; then
    DETECTED_CLAUDE_PROFILE="unknown"
    return
  fi

  if cmp -s "$settings_path" "$minimal_template"; then
    DETECTED_CLAUDE_PROFILE="minimal"
  elif cmp -s "$settings_path" "$standard_template"; then
    DETECTED_CLAUDE_PROFILE="standard"
  elif cmp -s "$settings_path" "$strict_template"; then
    DETECTED_CLAUDE_PROFILE="strict"
  elif cmp -s "$settings_path" "$team_template"; then
    DETECTED_CLAUDE_PROFILE="team"
  else
    DETECTED_CLAUDE_PROFILE="custom"
  fi
}

detect_shared_asset_mode() {
  local target="$1"
  local symlink_count=0
  local regular_count=0
  local path
  local paths=(
    "$target/.claude/settings.json"
    "$target/.cursor/rules/ai-setting.mdc"
    "$target/.gemini/settings.json"
  )

  for path in "${paths[@]}"; do
    if [ -L "$path" ]; then
      symlink_count=$((symlink_count + 1))
    elif [ -e "$path" ]; then
      regular_count=$((regular_count + 1))
    fi
  done

  if [ "$symlink_count" -gt 0 ] && [ "$regular_count" -gt 0 ]; then
    DETECTED_SHARED_ASSET_MODE="mixed"
  elif [ "$symlink_count" -gt 0 ]; then
    DETECTED_SHARED_ASSET_MODE="symlink"
  else
    DETECTED_SHARED_ASSET_MODE="copy"
  fi
}

detect_async_test_strategy() {
  local target="$1"

  ASYNC_TEST_STRATEGY="none"
  ASYNC_TEST_COMMAND_PREVIEW=""

  if [ -f "$target/.ai-setting/test-command" ]; then
    ASYNC_TEST_COMMAND_PREVIEW="$(awk '{ sub(/\r$/, ""); if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) next; print; exit }' "$target/.ai-setting/test-command")"
    if [ -n "$ASYNC_TEST_COMMAND_PREVIEW" ]; then
      ASYNC_TEST_STRATEGY="project-file"
      return
    fi
  fi

  if [ -n "${AI_SETTING_ASYNC_TEST_CMD:-}" ]; then
    ASYNC_TEST_STRATEGY="env"
    ASYNC_TEST_COMMAND_PREVIEW="$AI_SETTING_ASYNC_TEST_CMD"
    return
  fi

  if [ -f "$target/uv.lock" ] && { [ -d "$target/tests" ] || [ -f "$target/pytest.ini" ] || [ -f "$target/pyproject.toml" ]; }; then
    ASYNC_TEST_STRATEGY="auto-python-uv"
    ASYNC_TEST_COMMAND_PREVIEW="uv run pytest -q"
    return
  fi

  if [ -f "$target/pytest.ini" ] || { [ -d "$target/tests" ] && { [ -f "$target/pyproject.toml" ] || [ -f "$target/requirements.txt" ] || [ -f "$target/requirements-dev.txt" ]; }; }; then
    ASYNC_TEST_STRATEGY="auto-python-pytest"
    ASYNC_TEST_COMMAND_PREVIEW="pytest -q"
    return
  fi

  if [ -f "$target/go.mod" ]; then
    ASYNC_TEST_STRATEGY="auto-go"
    ASYNC_TEST_COMMAND_PREVIEW="go test ./..."
    return
  fi

  if [ -f "$target/Cargo.toml" ]; then
    ASYNC_TEST_STRATEGY="auto-rust"
    ASYNC_TEST_COMMAND_PREVIEW="cargo test --quiet"
    return
  fi
}
