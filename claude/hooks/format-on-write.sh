#!/bin/bash
# format-on-write.sh — format edited files using the nearest project config

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

read_input() {
  cat
}

extract_file_path() {
  local input="$1"

  if ! command -v jq >/dev/null 2>&1; then
    return 1
  fi

  printf '%s' "$input" | jq -r '.tool_input.file_path // empty'
}

find_parent_with_markers() {
  local rel_path="$1"
  shift
  local markers=("$@")
  local dir
  local marker

  dir="$(dirname "$rel_path")"

  while :; do
    for marker in "${markers[@]}"; do
      if [ -f "$PROJECT_DIR/$dir/$marker" ]; then
        printf '%s\n' "$dir"
        return 0
      fi
    done

    if [ "$dir" = "." ]; then
      break
    fi

    dir="$(dirname "$dir")"
  done

  printf '.\n'
}

relative_to_workdir() {
  local file_path="$1"
  local workdir_rel="$2"

  if [ "$workdir_rel" = "." ]; then
    printf '%s\n' "$file_path"
  else
    printf '%s\n' "${file_path#"$workdir_rel"/}"
  fi
}

run_python_formatter() {
  local file_path="$1"
  local workdir_rel
  local workdir_abs
  local rel_file

  workdir_rel="$(find_parent_with_markers "$file_path" "pyproject.toml" "requirements.txt" "requirements-dev.txt")"
  workdir_abs="$PROJECT_DIR"
  if [ "$workdir_rel" != "." ]; then
    workdir_abs="$PROJECT_DIR/$workdir_rel"
  fi

  rel_file="$(relative_to_workdir "$file_path" "$workdir_rel")"

  if [ -f "$workdir_abs/uv.lock" ] && command -v uv >/dev/null 2>&1; then
    (
      cd "$workdir_abs"
      uv run ruff format "$rel_file" 2>/dev/null || true
      uv run ruff check --fix "$rel_file" 2>/dev/null || true
    )
    return
  fi

  if command -v ruff >/dev/null 2>&1; then
    (
      cd "$workdir_abs"
      ruff format "$rel_file" 2>/dev/null || true
      ruff check --fix "$rel_file" 2>/dev/null || true
    )
  fi
}

run_prettier_formatter() {
  local file_path="$1"
  local workdir_rel
  local workdir_abs
  local rel_file

  workdir_rel="$(find_parent_with_markers "$file_path" "package.json")"
  workdir_abs="$PROJECT_DIR"
  if [ "$workdir_rel" != "." ]; then
    workdir_abs="$PROJECT_DIR/$workdir_rel"
  fi

  rel_file="$(relative_to_workdir "$file_path" "$workdir_rel")"

  if command -v npx >/dev/null 2>&1; then
    (
      cd "$workdir_abs"
      npx prettier --write "$rel_file" 2>/dev/null || true
    )
  fi
}

main() {
  local input
  local file_path

  input="$(read_input)"
  file_path="$(extract_file_path "$input" || true)"

  if [ -z "$file_path" ]; then
    exit 0
  fi

  case "$file_path" in
    *.py|*.pyi)
      run_python_formatter "$file_path"
      ;;
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
      run_prettier_formatter "$file_path"
      ;;
  esac
}

main "$@"
