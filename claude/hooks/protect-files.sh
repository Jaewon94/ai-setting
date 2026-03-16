#!/bin/bash
# protect-files.sh — Block edits to sensitive files
# PreToolUse hook for Edit|Write tools

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(
  # 시크릿 / 환경변수
  ".env"
  ".env.local"
  ".env.production"
  ".env.development"

  # Git 내부
  ".git/"

  # 의존성 / 빌드 산출물
  "node_modules/"
  "__pycache__/"
  ".venv/"
  "dist/"
  "build/"
  ".next/"

  # Lock 파일 (패키지 매니저가 관리)
  "package-lock.json"
  "pnpm-lock.yaml"
  "yarn.lock"
  "uv.lock"

  # DB / 데이터
  "*.sqlite"
  "*.sqlite3"

  # 인증 / 키
  "*.pem"
  "*.key"
  "credentials.json"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'. Edit manually if needed." >&2
    exit 2
  fi
done

exit 0
