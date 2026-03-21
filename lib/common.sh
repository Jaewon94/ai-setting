#!/bin/bash
# lib/common.sh — 색상 상수, 타임스탬프, 공통 유틸리티

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
RUN_TIMESTAMP="$(date +%Y%m%d%H%M%S)"
USAGE_NAME="${AI_SETTING_USAGE_NAME:-init.sh}"

# i18n: locale 감지 및 메시지 파일 로드
# 우선순위: --lang flag > AI_SETTING_LANG env > LANG/LC_MESSAGES > en (기본)
detect_locale() {
  local lang="${AI_SETTING_LANG:-}"
  if [ -z "$lang" ]; then
    lang="${LC_MESSAGES:-${LANG:-en}}"
  fi
  case "$lang" in
    ko*) echo "ko" ;;
    *)   echo "en" ;;
  esac
}

load_locale() {
  local locale_dir="$1/locale"
  AI_SETTING_LOCALE="$(detect_locale)"
  if [ -f "$locale_dir/${AI_SETTING_LOCALE}.sh" ]; then
    source "$locale_dir/${AI_SETTING_LOCALE}.sh"
  elif [ -f "$locale_dir/en.sh" ]; then
    source "$locale_dir/en.sh"
  fi
}

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

contains_value() {
  local needle="$1"
  shift
  local value
  for value in "$@"; do
    if [ "$value" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

dry_run_note() {
  echo -e "  ${CYAN}[dry-run]${NC} $1"
}

tool_enabled() {
  local tool="$1"
  contains_value "$tool" "${TOOLS[@]}"
}
