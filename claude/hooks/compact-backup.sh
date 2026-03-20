#!/bin/bash
# compact-backup.sh — Persist compact-friendly context snapshots with history

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MODE="${1:-write}"
PROFILE="${2:-standard}"
CONTEXT_DIR="$PROJECT_DIR/.claude/context"
SESSION_CONTEXT_FILE="$CONTEXT_DIR/session-context.md"
LATEST_FILE="$CONTEXT_DIR/compact-latest.md"
HISTORY_DIR="$CONTEXT_DIR/compact-history"
ASYNC_STATUS_FILE="$CONTEXT_DIR/async-test-status.md"
TEAM_WEBHOOK_STATUS_FILE="$CONTEXT_DIR/team-webhook-status.md"

ensure_context_dirs() {
  mkdir -p "$CONTEXT_DIR" "$HISTORY_DIR" 2>/dev/null || true
}

print_excerpt() {
  local title="$1"
  local path="$2"
  local max_lines="$3"

  if [ ! -f "$path" ]; then
    return
  fi

  echo "## $title"
  echo
  sed -n "1,${max_lines}p" "$path"
  echo
}

write_backup() {
  local branch="unknown"
  local timestamp
  local history_file
  local temp_file

  ensure_context_dirs
  timestamp="$(date +%Y%m%d%H%M%S)"
  history_file="$HISTORY_DIR/compact-${timestamp}.md"
  temp_file="$(mktemp)"

  if [ -d "$PROJECT_DIR/.git" ]; then
    branch="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo unknown)"
  fi

  {
    echo "# Compact Backup Snapshot"
    echo
    echo "- generated_at: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "- profile: $PROFILE"
    echo "- project_dir: $PROJECT_DIR"
    echo "- git_branch: $branch"
    echo
    echo "compact 이후 세션에서 복원하기 위한 최신 컨텍스트 백업입니다."
    echo

    if [ -f "$SESSION_CONTEXT_FILE" ]; then
      print_excerpt "Session Context" "$SESSION_CONTEXT_FILE" 120
    else
      print_excerpt "CLAUDE.md" "$PROJECT_DIR/CLAUDE.md" 60
      print_excerpt "AGENTS.md" "$PROJECT_DIR/AGENTS.md" 50
      print_excerpt "docs/decisions.md" "$PROJECT_DIR/docs/decisions.md" 40
      print_excerpt "docs/research-notes.md" "$PROJECT_DIR/docs/research-notes.md" 40
    fi

    print_excerpt "Async Test Status" "$ASYNC_STATUS_FILE" 30
    print_excerpt "Team Webhook Status" "$TEAM_WEBHOOK_STATUS_FILE" 30

    if [ -d "$PROJECT_DIR/.git" ]; then
      echo "## Git Status"
      echo
      git -C "$PROJECT_DIR" status --short 2>/dev/null || true
      echo
    fi
  } > "$temp_file"

  cp "$temp_file" "$LATEST_FILE"
  cp "$temp_file" "$history_file"
  rm -f "$temp_file"
}

read_backup() {
  if [ -f "$LATEST_FILE" ]; then
    cat "$LATEST_FILE"
  else
    echo "Reminder: compact backup가 아직 없습니다. 첫 Stop/compact 이후부터 최신 스냅샷이 저장됩니다."
  fi
}

case "$MODE" in
  write)
    write_backup
    ;;
  read)
    read_backup
    ;;
  *)
    echo "usage: compact-backup.sh [write|read] [profile]" >&2
    exit 1
    ;;
esac
