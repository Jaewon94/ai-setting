#!/bin/bash
# protect-files.sh — Block edits to sensitive files
# PreToolUse hook for Edit|Write tools

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 디렉토리 패턴 (경로에 포함되면 차단)
DIR_PATTERNS=(
  ".git/"
  "node_modules/"
  "__pycache__/"
  ".venv/"
  "dist/"
  "build/"
  ".next/"
)

# 파일명 패턴 (basename 기준으로 매칭)
FILE_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.development"
  "package-lock.json"
  "pnpm-lock.yaml"
  "yarn.lock"
  "uv.lock"
  "credentials.json"
)

# 확장자 패턴 (basename 끝이 매칭)
EXT_PATTERNS=(
  ".sqlite"
  ".sqlite3"
  ".pem"
  ".key"
)

BASENAME=$(basename "$FILE_PATH")

for pattern in "${DIR_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected directory '$pattern'. Edit manually if needed." >&2
    exit 2
  fi
done

for pattern in "${FILE_PATTERNS[@]}"; do
  if [[ "$BASENAME" == "$pattern" ]]; then
    echo "Blocked: $FILE_PATH matches protected file '$pattern'. Edit manually if needed." >&2
    exit 2
  fi
done

for pattern in "${EXT_PATTERNS[@]}"; do
  if [[ "$BASENAME" == *"$pattern" ]]; then
    echo "Blocked: $FILE_PATH matches protected extension '$pattern'. Edit manually if needed." >&2
    exit 2
  fi
done

exit 0
