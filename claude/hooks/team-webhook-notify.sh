#!/bin/bash
# team-webhook-notify.sh — Optional webhook notifications for the team profile

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MODE="${1:-stop}"
PROFILE="${2:-team}"
CONTEXT_DIR="$PROJECT_DIR/.claude/context"
STATUS_FILE="$CONTEXT_DIR/team-webhook-status.md"
CONFIG_FILE="$PROJECT_DIR/.ai-setting/team-webhook.json"

ensure_context_dir() {
  mkdir -p "$CONTEXT_DIR" 2>/dev/null || true
}

mask_url() {
  local url="$1"

  if [ -z "$url" ]; then
    printf '%s\n' ""
    return
  fi

  printf '%s\n' "$url" | sed -E 's#(https?://[^/]+/).*#\1...#'
}

write_status() {
  local status="$1"
  local config_source="$2"
  local webhook_url="${3:-}"
  local note="${4:-}"
  local async_status="${5:-}"
  local masked_url=""

  ensure_context_dir
  masked_url="$(mask_url "$webhook_url")"

  {
    echo "# Team Webhook Status"
    echo
    echo "- updated_at: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "- event: $MODE"
    echo "- status: $status"
    if [ -n "$config_source" ]; then
      echo "- config_source: $config_source"
    fi
    if [ -n "$masked_url" ]; then
      echo "- webhook_url: $masked_url"
    fi
    if [ -n "$async_status" ]; then
      echo "- async_test_status: $async_status"
    fi
    if [ -n "$note" ]; then
      echo
      echo "$note"
    fi
  } > "$STATUS_FILE"
}

load_config() {
  TEAM_WEBHOOK_ENABLED="false"
  TEAM_WEBHOOK_URL=""
  TEAM_WEBHOOK_URL_SOURCE=""
  TEAM_WEBHOOK_USERNAME="Claude Code"
  TEAM_WEBHOOK_CHANNEL=""
  TEAM_WEBHOOK_MENTION=""
  TEAM_WEBHOOK_CONFIG_SOURCE="none"

  if [ -f "$CONFIG_FILE" ]; then
    if ! command -v jq >/dev/null 2>&1; then
      write_status "disabled" "project-file" "" "jq가 없어 team webhook 설정 파일을 해석하지 못했습니다."
      exit 0
    fi

    TEAM_WEBHOOK_ENABLED="$(jq -r '.enabled // false' "$CONFIG_FILE")"
    TEAM_WEBHOOK_USERNAME="$(jq -r '.username // "Claude Code"' "$CONFIG_FILE")"
    TEAM_WEBHOOK_CHANNEL="$(jq -r '.channel // empty' "$CONFIG_FILE")"
    TEAM_WEBHOOK_MENTION="$(jq -r '.mention // empty' "$CONFIG_FILE")"
    TEAM_WEBHOOK_URL="$(jq -r '.url // empty' "$CONFIG_FILE")"
    TEAM_WEBHOOK_CONFIG_SOURCE="project-file"

    if [ -n "$TEAM_WEBHOOK_URL" ]; then
      TEAM_WEBHOOK_URL_SOURCE="project-file:url"
    else
      local url_env_name
      url_env_name="$(jq -r '.url_env // "AI_SETTING_TEAM_WEBHOOK_URL"' "$CONFIG_FILE")"
      TEAM_WEBHOOK_URL="${!url_env_name:-}"
      if [ -n "$TEAM_WEBHOOK_URL" ]; then
        TEAM_WEBHOOK_URL_SOURCE="env:${url_env_name}"
      fi
    fi
  else
    TEAM_WEBHOOK_ENABLED="${AI_SETTING_TEAM_WEBHOOK_ENABLED:-false}"
    TEAM_WEBHOOK_URL="${AI_SETTING_TEAM_WEBHOOK_URL:-}"
    TEAM_WEBHOOK_URL_SOURCE="env:AI_SETTING_TEAM_WEBHOOK_URL"
    TEAM_WEBHOOK_CONFIG_SOURCE="env"
  fi
}

event_enabled() {
  if [ ! -f "$CONFIG_FILE" ]; then
    return 0
  fi

  jq -e --arg mode "$MODE" '(.events // ["stop"]) | index($mode)' "$CONFIG_FILE" >/dev/null 2>&1
}

extract_async_test_status() {
  local async_status_file="$PROJECT_DIR/.claude/context/async-test-status.md"

  if [ -f "$async_status_file" ]; then
    awk -F': ' '/^- status:/ { print $2; exit }' "$async_status_file"
  fi
}

send_webhook() {
  local project_name
  local branch="unknown"
  local async_status=""
  local message=""
  local payload=""

  if ! command -v curl >/dev/null 2>&1; then
    write_status "disabled" "$TEAM_WEBHOOK_CONFIG_SOURCE" "$TEAM_WEBHOOK_URL" "curl이 없어 팀 웹훅을 전송할 수 없습니다."
    exit 0
  fi

  project_name="$(basename "$PROJECT_DIR")"
  async_status="$(extract_async_test_status)"

  if [ -d "$PROJECT_DIR/.git" ]; then
    branch="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo unknown)"
  fi

  message="[$PROFILE] Claude Code stop — project=${project_name}, branch=${branch}"
  if [ -n "$async_status" ]; then
    message="${message}, async_test=${async_status}"
  fi
  if [ -n "$TEAM_WEBHOOK_MENTION" ]; then
    message="${TEAM_WEBHOOK_MENTION} ${message}"
  fi

  payload="$(jq -n \
    --arg text "$message" \
    --arg content "$message" \
    --arg username "$TEAM_WEBHOOK_USERNAME" \
    --arg channel "$TEAM_WEBHOOK_CHANNEL" \
    '{
      text: $text,
      content: $content,
      username: $username
    } + (if $channel != "" then {channel: $channel} else {} end)')"

  if curl -fsS -X POST -H 'Content-Type: application/json' -d "$payload" "$TEAM_WEBHOOK_URL" >/dev/null 2>&1; then
    write_status "sent" "$TEAM_WEBHOOK_CONFIG_SOURCE" "$TEAM_WEBHOOK_URL" "팀 웹훅 전송에 성공했습니다." "$async_status"
  else
    write_status "failed" "$TEAM_WEBHOOK_CONFIG_SOURCE" "$TEAM_WEBHOOK_URL" "팀 웹훅 전송에 실패했습니다. URL, 네트워크, 수신 endpoint를 확인하세요." "$async_status"
  fi
}

load_config

if [ "$TEAM_WEBHOOK_ENABLED" != "true" ]; then
  write_status "disabled" "$TEAM_WEBHOOK_CONFIG_SOURCE" "$TEAM_WEBHOOK_URL" "team webhook이 비활성화되어 있습니다."
  exit 0
fi

if ! event_enabled; then
  write_status "disabled" "$TEAM_WEBHOOK_CONFIG_SOURCE" "$TEAM_WEBHOOK_URL" "현재 이벤트($MODE)는 team webhook 전송 대상이 아닙니다."
  exit 0
fi

if [ -z "$TEAM_WEBHOOK_URL" ]; then
  write_status "disabled" "$TEAM_WEBHOOK_CONFIG_SOURCE" "" "웹훅 URL이 설정되지 않았습니다. team-webhook.json의 url_env 또는 url 값을 확인하세요."
  exit 0
fi

send_webhook
