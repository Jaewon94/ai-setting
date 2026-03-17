#!/bin/bash
# protect-main-branch.sh — Block direct git actions on protected branches
# PreToolUse hook for Bash tool

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CURRENT_BRANCH="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || true)"

if [[ -z "$CURRENT_BRANCH" ]]; then
  exit 0
fi

if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
  exit 0
fi

PROTECTED_PATTERNS=(
  "git commit"
  "git merge"
  "git cherry-pick"
  "git push"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "Blocked: '$CURRENT_BRANCH' 브랜치에서 직접 git 작업은 허용되지 않습니다. feat/fix 브랜치에서 작업 후 PR로 반영하세요." >&2
    exit 2
  fi
done

exit 0
