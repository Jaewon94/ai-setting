#!/bin/bash
# lib/mcp.sh — MCP preset 관리, Codex/Claude MCP 설정 생성

add_mcp_preset() {
  local preset="$1"
  case "$preset" in
    core|web|infra|local)
      ;;
    *)
      echo -e "${RED}오류: 알 수 없는 MCP preset '$preset'${NC}" >&2
      usage
      exit 1
      ;;
  esac

  if ! contains_value "$preset" "${MCP_PRESETS[@]}"; then
    MCP_PRESETS+=("$preset")
  fi
}

normalize_mcp_presets() {
  if [ "$MCP_ENABLED" = false ]; then
    MCP_PRESETS=()
    return
  fi

  if [ "${#MCP_PRESETS[@]}" -eq 0 ]; then
    MCP_PRESETS=("core")
    return
  fi

  if ! contains_value "core" "${MCP_PRESETS[@]}"; then
    MCP_PRESETS=("core" "${MCP_PRESETS[@]}")
  fi
}

add_recommended_mcp_preset() {
  local preset="$1"

  if ! contains_value "$preset" "${RECOMMENDED_MCP_PRESETS[@]}"; then
    RECOMMENDED_MCP_PRESETS+=("$preset")
  fi
}

calculate_recommended_mcp_presets() {
  RECOMMENDED_MCP_PRESETS=("core")

  case "$PROJECT_ARCHETYPE" in
    frontend-web)
      add_recommended_mcp_preset "web"
      ;;
    infra-iac)
      add_recommended_mcp_preset "infra"
      ;;
    backend-api|worker-batch|data-automation)
      if [ "$OPS_SIGNAL_COUNT" -ge 1 ]; then
        add_recommended_mcp_preset "infra"
      fi
      ;;
  esac

  RECOMMENDED_MCP_PRESET_LABEL="$(IFS=,; echo "${RECOMMENDED_MCP_PRESETS[*]}")"
}

apply_auto_mcp_presets() {
  local preset

  if [ "$AUTO_MCP" = true ] && [ "$MCP_ENABLED" = true ] && [ "$USER_MCP_PRESET_SPECIFIED" = false ]; then
    for preset in "${RECOMMENDED_MCP_PRESETS[@]}"; do
      add_mcp_preset "$preset"
    done
    AUTO_MCP_APPLIED=true
  else
    AUTO_MCP_APPLIED=false
  fi

  normalize_mcp_presets
}

append_codex_mcp_preset() {
  local preset="$1"
  local file="$2"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "Codex MCP preset 추가: ${preset} -> ${file}"
    return
  fi

  case "$preset" in
    core)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: core
[mcp_servers.sequential-thinking]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-sequential-thinking"]

[mcp_servers.serena]
command = "uvx"
args = ["--from", "git+https://github.com/oraios/serena", "serena-mcp-server", "--enable-web-dashboard", "false", "start-mcp-server"]

[mcp_servers.upstash-context-7-mcp]
command = "npx"
args = ["-y", "@upstash/context7-mcp@latest"]
EOF
      ;;
    web)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: web
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]
EOF
      ;;
    infra)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: infra
[mcp_servers.docker]
command = "npx"
args = ["-y", "@hypnosis/docker-mcp-server"]
EOF
      ;;
    local)
      cat <<EOF >> "$file"

# Project-local MCP preset: local
[mcp_servers.filesystem]
command = "npx"
args = ["-y", "@anthropic/mcp-filesystem", "${TARGET:-.}"]

[mcp_servers.fetch]
command = "npx"
args = ["-y", "@anthropic/mcp-fetch"]
EOF
      ;;
  esac
}

check_mcp_commands() {
  local commands_to_check=()
  local preset

  for preset in "${MCP_PRESETS[@]}"; do
    case "$preset" in
      core)
        commands_to_check+=("npx" "uvx")
        ;;
      web|infra|local)
        commands_to_check+=("npx")
        ;;
    esac
  done

  local seen=()
  local cmd
  for cmd in "${commands_to_check[@]}"; do
    if contains_value "$cmd" "${seen[@]:-}"; then
      continue
    fi
    seen+=("$cmd")
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo -e "  ${YELLOW}⚠ MCP 서버에 필요한 '$cmd'가 PATH에 없습니다. 해당 MCP 서버가 실행되지 않을 수 있습니다.${NC}"
    fi
  done
}

CLAUDE_MCP_FIRST=true

append_claude_mcp_server() {
  local file="$1"
  local server_name="$2"
  local command_name="$3"
  local args_json="$4"

  if [ "$CLAUDE_MCP_FIRST" = true ]; then
    CLAUDE_MCP_FIRST=false
  else
    printf ',\n' >> "$file"
  fi

  printf '    "%s": {\n      "command": "%s",\n      "args": %s\n    }' \
    "$server_name" \
    "$command_name" \
    "$args_json" >> "$file"
}

write_claude_mcp_config() {
  local file="$1"
  local preset

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "Claude MCP config 생성: ${file}"
    return
  fi

  cat <<'EOF' > "$file"
{
  "mcpServers": {
EOF

  CLAUDE_MCP_FIRST=true

  for preset in "${MCP_PRESETS[@]}"; do
    case "$preset" in
      core)
        append_claude_mcp_server "$file" "sequential-thinking" "npx" '["-y", "@modelcontextprotocol/server-sequential-thinking"]'
        append_claude_mcp_server "$file" "serena" "uvx" '["--from", "git+https://github.com/oraios/serena", "serena-mcp-server", "--enable-web-dashboard", "false", "start-mcp-server"]'
        append_claude_mcp_server "$file" "upstash-context-7-mcp" "npx" '["-y", "@upstash/context7-mcp@latest"]'
        ;;
      web)
        append_claude_mcp_server "$file" "playwright" "npx" '["-y", "@playwright/mcp@latest"]'
        ;;
      infra)
        append_claude_mcp_server "$file" "docker" "npx" '["-y", "@hypnosis/docker-mcp-server"]'
        ;;
      local)
        append_claude_mcp_server "$file" "filesystem" "npx" '["--yes", "@anthropic/mcp-filesystem", "."]'
        append_claude_mcp_server "$file" "fetch" "npx" '["--yes", "@anthropic/mcp-fetch"]'
        ;;
    esac
  done

  printf '\n' >> "$file"

  cat <<'EOF' >> "$file"

  }
}
EOF
}
