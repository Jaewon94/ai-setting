#!/bin/bash
# protect-files.sh — Block edits to sensitive files
# PreToolUse hook for Edit|Write tools

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
FILE_PATH=$(echo "$INPUT" | $JQ_BIN -r '.tool_input.file_path // empty')

# 디렉토리 패턴 (경로에 포함되면 차단)
BLOCK_DIR_PATTERNS=(
  ".git/"
  "node_modules/"
  "__pycache__/"
  ".venv/"
  "dist/"
  "build/"
  ".next/"
)

# 파일명 패턴 (basename 기준으로 매칭)
BLOCK_FILE_PATTERNS=(
  "credentials.json"
)

# 확장자 패턴 (basename 끝이 매칭)
BLOCK_EXT_PATTERNS=(
  ".sqlite"
  ".sqlite3"
  ".pem"
  ".key"
)

# 확인 후 허용할 파일 패턴
CONFIRM_FILE_PATTERNS=(
  ".env"
  ".env.*"
  "package-lock.json"
  "pnpm-lock.yaml"
  "yarn.lock"
  "uv.lock"
  "docker-compose.yml"
  "docker-compose.yaml"
  "compose.yml"
  "compose.yaml"
)

CONFIRM_PATH_PATTERNS=(
  ".github/workflows/"
)

BASENAME=$(basename "$FILE_PATH")

for pattern in "${BLOCK_DIR_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected directory '$pattern'. Edit manually if needed." >&2
    exit 2
  fi
done

for pattern in "${BLOCK_FILE_PATTERNS[@]}"; do
  if [[ "$BASENAME" == $pattern ]]; then
    echo "Blocked: $FILE_PATH matches protected file '$pattern'. Edit manually if needed." >&2
    exit 2
  fi
done

for pattern in "${BLOCK_EXT_PATTERNS[@]}"; do
  if [[ "$BASENAME" == *"$pattern" ]]; then
    echo "Blocked: $FILE_PATH matches protected extension '$pattern'. Edit manually if needed." >&2
    exit 2
  fi
done

for pattern in "${CONFIRM_PATH_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Confirm: $FILE_PATH is a sensitive operational path ('$pattern'). Review the diff carefully before accepting the edit." >&2
    exit 0
  fi
done

for pattern in "${CONFIRM_FILE_PATTERNS[@]}"; do
  if [[ "$BASENAME" == $pattern ]]; then
    echo "Confirm: $FILE_PATH matches caution file '$pattern'. Review the diff carefully before accepting the edit." >&2
    exit 0
  fi
done

exit 0
