#!/bin/bash
# block-dangerous-commands.sh — Block dangerous bash commands
# PreToolUse hook for Bash tool

JQ_BIN=""
if command -v jq >/dev/null 2>&1; then
  JQ_BIN="jq"
elif [ -f "$HOME/jq.exe" ]; then
  JQ_BIN="$HOME/jq.exe"
elif [ -f "/usr/local/bin/jq" ]; then
  JQ_BIN="/usr/local/bin/jq"
fi
if [ -z "$JQ_BIN" ]; then
  echo "BLOCKED: jq is not installed — cannot verify tool input safely." >&2
  exit 2
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | $JQ_BIN -r '.tool_input.command // empty')

DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf ."
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
