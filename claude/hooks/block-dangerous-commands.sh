#!/bin/bash
# block-dangerous-commands.sh — Block dangerous bash commands
# PreToolUse hook for Bash tool

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \."
  "sudo "
  "git push --force"
  "git push -f "
  "git reset --hard"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "chmod 777"
  "mkfs"
  "> /dev/sda"
  ":(){ :|:& };:"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    echo "Blocked: Command contains dangerous pattern '$pattern'. Execute manually if truly needed." >&2
    exit 2
  fi
done

exit 0
