#!/bin/bash
# lib/validate.sh — input validation and usage display

usage() {
  printf '%s\n' "$MSG_VALIDATE_USAGE_HEADER"
  printf "$MSG_VALIDATE_USAGE_CMD_INIT\n" "$USAGE_NAME"
  printf "$MSG_VALIDATE_USAGE_CMD_UPDATE\n" "$USAGE_NAME"
  printf "$MSG_VALIDATE_USAGE_CMD_SYNC\n" "$USAGE_NAME"
  printf "$MSG_VALIDATE_USAGE_CMD_ADDTOOL\n" "$USAGE_NAME"
  printf "$MSG_VALIDATE_USAGE_CMD_PLUGIN\n" "$USAGE_NAME"
  echo ""
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPTIONS_HEADER"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_TOOLS"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_ALL"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_PROFILE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_LINK"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_LINKDIR"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_MERGE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_UPDATE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_SYNCMODE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_SYNCCONFLICT"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_DOCTOR"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_DRYRUN"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_DIFF"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_BACKUPALL"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_REAPPLY"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_AUTOMCP"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_PROJECTNAME"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_ARCHETYPE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_STACK"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_SKIPAI"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_MCPPRESET"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_NOMCP"
  printf '%s\n' "$MSG_VALIDATE_USAGE_OPT_HELP"
  echo ""
  printf '%s\n' "$MSG_VALIDATE_USAGE_PLUGIN_HEADER"
  printf '%s\n' "$MSG_VALIDATE_USAGE_PLUGIN_LIST"
  printf '%s\n' "$MSG_VALIDATE_USAGE_PLUGIN_INSTALL"
  printf '%s\n' "$MSG_VALIDATE_USAGE_PLUGIN_UNINSTALL"
  printf '%s\n' "$MSG_VALIDATE_USAGE_PLUGIN_CHECKUPDATE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_PLUGIN_UPGRADE"
  echo ""
  printf '%s\n' "$MSG_VALIDATE_USAGE_MCP_HEADER"
  printf '%s\n' "$MSG_VALIDATE_USAGE_MCP_CORE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_MCP_WEB"
  printf '%s\n' "$MSG_VALIDATE_USAGE_MCP_INFRA"
  printf '%s\n' "$MSG_VALIDATE_USAGE_MCP_LOCAL"
  echo ""
  printf '%s\n' "$MSG_VALIDATE_USAGE_ARCHETYPE_HEADER"
  printf '%s\n' "$MSG_VALIDATE_USAGE_ARCHETYPE_LIST"
  echo ""
  printf '%s\n' "$MSG_VALIDATE_USAGE_TOOLS_HEADER"
  printf '%s\n' "$MSG_VALIDATE_USAGE_TOOL_CLAUDE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_TOOL_CODEX"
  printf '%s\n' "$MSG_VALIDATE_USAGE_TOOL_CURSOR"
  printf '%s\n' "$MSG_VALIDATE_USAGE_TOOL_GEMINI"
  printf '%s\n' "$MSG_VALIDATE_USAGE_TOOL_COPILOT"
  echo ""
  printf '%s\n' "$MSG_VALIDATE_USAGE_ADDTOOL_HEADER"
  printf '%s\n' "$MSG_VALIDATE_USAGE_ADDTOOL_DESC"
  printf "$MSG_VALIDATE_USAGE_ADDTOOL_EXAMPLE\n" "$USAGE_NAME"
  echo ""
  printf '%s\n' "$MSG_VALIDATE_USAGE_SYNC_HEADER"
  printf '%s\n' "$MSG_VALIDATE_USAGE_SYNC_LINE"
  printf '%s\n' "$MSG_VALIDATE_USAGE_SYNC_OPTS"
  printf '%s\n' "$MSG_VALIDATE_USAGE_SYNC_COMMENTS"
  printf '%s\n' "$MSG_VALIDATE_USAGE_SYNC_RELPATH"
}

validate_profile() {
  local profile="$1"

  case "$profile" in
    standard|minimal|strict|team)
      ;;
    *)
      printf "${RED}${MSG_VALIDATE_ERR_UNKNOWN_PROFILE}${NC}\n" "$profile" >&2
      usage
      exit 1
      ;;
  esac
}

validate_sync_mode() {
  local sync_mode="$1"

  case "$sync_mode" in
    update|init)
      ;;
    *)
      printf "${RED}${MSG_VALIDATE_ERR_UNKNOWN_SYNCMODE}${NC}\n" "$sync_mode" >&2
      usage
      exit 1
      ;;
  esac
}

get_profile_settings_template() {
  local profile="$1"

  case "$profile" in
    standard)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.json"
      ;;
    minimal)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.minimal.json"
      ;;
    strict)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.strict.json"
      ;;
    team)
      printf '%s\n' "$SCRIPT_DIR/claude/settings.team.json"
      ;;
  esac
}

get_codex_config_template() {
  local profile="$1"

  case "$profile" in
    minimal)
      printf '%s\n' "$SCRIPT_DIR/codex/config.minimal.toml"
      ;;
    strict)
      printf '%s\n' "$SCRIPT_DIR/codex/config.strict.toml"
      ;;
    team)
      printf '%s\n' "$SCRIPT_DIR/codex/config.team.toml"
      ;;
    *)
      printf '%s\n' "$SCRIPT_DIR/codex/config.toml"
      ;;
  esac
}

validate_archetype_hint() {
  local archetype="$1"

  case "$archetype" in
    frontend-web|backend-api|cli-tool|worker-batch|data-automation|library-sdk|infra-iac|general-app)
      ;;
    *)
      printf "${RED}${MSG_VALIDATE_ERR_UNKNOWN_ARCHETYPE}${NC}\n" "$archetype" >&2
      usage
      exit 1
      ;;
  esac
}
