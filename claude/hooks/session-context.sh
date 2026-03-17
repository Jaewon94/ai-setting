#!/bin/bash
# Stop / SessionStart(compact) hook for Claude Code
# Writes and restores a compact-friendly project context snapshot.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MODE="${1:-read}"
PROFILE="${2:-standard}"
CONTEXT_DIR="$PROJECT_DIR/.claude/context"
CONTEXT_FILE="$CONTEXT_DIR/session-context.md"

ensure_context_dir() {
  mkdir -p "$CONTEXT_DIR" 2>/dev/null || true
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

write_context() {
  local branch="unknown"

  ensure_context_dir

  if [ -d "$PROJECT_DIR/.git" ]; then
    branch="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo unknown)"
  fi

  {
    echo "# Session Context Snapshot"
    echo
    echo "- generated_at: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "- profile: $PROFILE"
    echo "- project_dir: $PROJECT_DIR"
    echo "- git_branch: $branch"
    echo
    echo "다음 compact 세션에서 우선 확인할 요약입니다."
    echo
    print_excerpt "CLAUDE.md" "$PROJECT_DIR/CLAUDE.md" 60
    print_excerpt "AGENTS.md" "$PROJECT_DIR/AGENTS.md" 50
    print_excerpt "docs/decisions.md" "$PROJECT_DIR/docs/decisions.md" 40
  } > "$CONTEXT_FILE"
}

read_context() {
  if [ -f "$CONTEXT_FILE" ]; then
    cat "$CONTEXT_FILE"
    echo
    echo "Reminder: 최신 변경이 있었다면 CLAUDE.md, AGENTS.md, docs/decisions.md도 함께 확인해."
  else
    echo "Reminder: Read CLAUDE.md and AGENTS.md for project context. Run tests before committing."
  fi
}

case "$MODE" in
  write)
    write_context
    ;;
  read)
    read_context
    ;;
  *)
    echo "usage: session-context.sh [write|read] [profile]" >&2
    exit 1
    ;;
esac
