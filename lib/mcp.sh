#!/bin/bash
# lib/mcp.sh — MCP preset 관리, Codex/Claude MCP 설정 생성

add_mcp_preset() {
  local preset="$1"
  case "$preset" in
    core|web|infra|git|local|chrome|next)
      ;;
    *)
      printf "${RED}${MSG_MCP_ERR_UNKNOWN_PRESET}${NC}\n" "$preset" >&2
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

  if [[ "$PROJECT_STACK" == *"Next.js"* ]]; then
    add_recommended_mcp_preset "next"
  fi

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
    dry_run_note "$(printf "$MSG_MCP_DRYRUN_CODEX" "$preset" "$file")"
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
    git)
      cat <<EOF >> "$file"

# Project-local MCP preset: git
[mcp_servers.git]
command = "uvx"
args = ["mcp-server-git", "--repository", "${TARGET:-.}"]
EOF
      ;;
    chrome)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: chrome
[mcp_servers.chrome-devtools]
command = "npx"
args = ["-y", "chrome-devtools-mcp@latest", "--no-usage-statistics"]
EOF
      ;;
    next)
      cat <<'EOF' >> "$file"

# Project-local MCP preset: next
[mcp_servers.next-devtools]
command = "npx"
args = ["-y", "next-devtools-mcp@latest"]
EOF
      ;;
    local)
      cat <<EOF >> "$file"

# Project-local MCP preset: local
# Note: Replace "${TARGET:-.}" with a narrower absolute path if you want tighter filesystem scope.
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

write_mcp_notes() {
  local file="$1"
  local preset
  local target_path="${TARGET:-.}"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "MCP notes file would be generated at $file"
    return
  fi

  cat > "$file" <<EOF
# MCP Setup Notes

This file explains which values may need manual edits after ai-setting generates project-local MCP config.

## Current presets

Enabled presets: ${MCP_PRESET_LABEL}

EOF

  for preset in "${MCP_PRESETS[@]}"; do
    case "$preset" in
      core)
        cat >> "$file" <<'EOF'
## core

- `sequential-thinking`: no additional user input required.
- `serena`: requires `uvx` availability. No API key is embedded here.
- `upstash-context-7-mcp`: no local value is embedded here.

EOF
        ;;
      web)
        cat >> "$file" <<'EOF'
## web

- `playwright`: no additional user input required.

EOF
        ;;
      infra)
        cat >> "$file" <<'EOF'
## infra

- `docker`: requires Docker to be installed and running locally.

EOF
        ;;
      git)
        cat >> "$file" <<EOF
## git

- `git`: requires `uvx`, an initialized Git repository, and access to the target repository path.
- The generated repository path is currently set to the project root.
  - Current value: \`${target_path}\`
  - If you want stricter scope, replace it with the exact repository directory you want to expose.
  - Example: \`/absolute/path/to/project\`
- This preset is opt-in because it exposes repository history, diffs, and branch state to the MCP client.

EOF
        ;;
      chrome)
        cat >> "$file" <<'EOF'
## chrome

- `chrome-devtools`: requires Node.js 20.19+ and Google Chrome or Chrome for Testing.
- The generated preset uses `--no-usage-statistics` to disable the upstream usage-statistics collection by default.
- Add this preset when you want browser debugging and performance inspection beyond the Playwright-only `web` preset.

EOF
        ;;
      next)
        cat >> "$file" <<'EOF'
## next

- `next-devtools`: requires Node.js 20.19+.
- Runtime diagnostics work best when a Next.js dev server is already running (`npm run dev` or equivalent).
- Upstream telemetry may be enabled by default; if you need stricter privacy controls, review the upstream docs and add the relevant environment override manually.

EOF
        ;;
      local)
        cat >> "$file" <<EOF
## local

- `filesystem`: the generated path is currently set to the project root.
  - Current value: \`${target_path}\`
  - If you want stricter scope, replace it with the exact directory you want to allow.
  - Example: \`/absolute/path/to/project\`
- `fetch`: no additional user input required.

EOF
        ;;
    esac
  done

  cat >> "$file" <<'EOF'
## Optional servers that need manual values

If you manually add an MCP server that requires credentials or explicit paths, keep the config valid and replace placeholders like:

- API key: `YOUR_API_KEY_HERE`
- Absolute directory path: `/absolute/path/to/project`
- Allowed directories list: add only the specific directories you actually want to expose

Recommended rule:

- Do not put explanatory comments inside `.mcp.json`; JSON comments are invalid.
- Put explanations in this file and keep `.mcp.json` machine-parseable.
- For Codex `.codex/config.toml`, inline comments are safe and preferred.
EOF
}

check_mcp_commands() {
  local commands_to_check=()
  local preset

  for preset in "${MCP_PRESETS[@]}"; do
    case "$preset" in
      core)
        commands_to_check+=("npx" "uvx")
        ;;
      git)
        commands_to_check+=("uvx")
        ;;
      web|infra|local|chrome|next)
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
      printf "  ${YELLOW}$(printf "$MSG_MCP_WARN_COMMAND_MISSING" "$cmd")${NC}\n"
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
    dry_run_note "$(printf "$MSG_MCP_DRYRUN_CLAUDE" "$file")"
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
      git)
        append_claude_mcp_server "$file" "git" "uvx" '["mcp-server-git", "--repository", "."]'
        ;;
      chrome)
        append_claude_mcp_server "$file" "chrome-devtools" "npx" '["-y", "chrome-devtools-mcp@latest", "--no-usage-statistics"]'
        ;;
      next)
        append_claude_mcp_server "$file" "next-devtools" "npx" '["-y", "next-devtools-mcp@latest"]'
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
