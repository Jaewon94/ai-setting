#!/bin/bash
# lib/cli.sh — subcommand preprocessing and option parsing

reset_cli_state() {
  UPDATE_MODE=false
  SYNC_MODE=false
  PLUGIN_MODE=false
  ADD_TOOL_MODE=false
  PLUGIN_SUBCOMMAND=""
  PLUGIN_NAME=""
  PLUGIN_TARGET=""
  ADD_TOOL_NAME=""
  ADD_TOOL_TARGET="."

  DOCTOR_MODE=false
  DRY_RUN=false
  DIFF_MODE=false
  BACKUP_ALL=false
  REAPPLY_MODE=false
  AUTO_MCP=false
  LINK_MODE=false
  LINK_DIR_MODE=false
  MERGE_SETTINGS=false
  SKIP_AI=false
  MCP_ENABLED=true
  MCP_PRESETS=()
  TOOLS=(claude)
  ALL_TOOLS=false
  TARGET=""
  CLAUDE_PROFILE="standard"
  USER_PROJECT_NAME_HINT=""
  USER_ARCHETYPE_HINT=""
  USER_STACK_HINT=""
  USER_MCP_PRESET_SPECIFIED=false
  SYNC_MODE_KIND="update"
  SYNC_MANIFEST=""
  SYNC_CONFLICT_STRATEGY="backup"
}

refresh_template_dir() {
  TEMPLATE_DIR="$SCRIPT_DIR/templates/${AI_SETTING_LOCALE}"
  if [ ! -d "$TEMPLATE_DIR" ]; then
    TEMPLATE_DIR="$SCRIPT_DIR/templates/en"
  fi
}

preprocess_subcommand() {
  case "${1:-}" in
    update)
      UPDATE_MODE=true
      shift
      ;;
    sync)
      SYNC_MODE=true
      shift
      ;;
    plugin)
      PLUGIN_MODE=true
      shift
      PLUGIN_SUBCOMMAND="${1:-}"
      shift
      case "$PLUGIN_SUBCOMMAND" in
        install|uninstall|upgrade)
          PLUGIN_NAME="${1:-}"
          PLUGIN_TARGET="${2:-.}"
          ;;
        list|check-update)
          PLUGIN_TARGET="${1:-.}"
          ;;
      esac
      ;;
    add-tool)
      ADD_TOOL_MODE=true
      shift
      ADD_TOOL_NAME="${1:-}"
      ADD_TOOL_TARGET="${2:-.}"
      ;;
    init)
      shift
      ;;
  esac

  CLI_ARGS=("$@")
}

run_preparsed_mode_if_needed() {
  if [ "$ADD_TOOL_MODE" = true ]; then
    if [ -z "$ADD_TOOL_NAME" ]; then
      echo -e "${RED}${MSG_INIT_ERR_ADDTOOL_USAGE}${NC}" >&2
      echo "$MSG_INIT_ERR_ADDTOOL_SUPPORTED"
      exit 1
    fi
    cmd_add_tool "$ADD_TOOL_NAME" "$ADD_TOOL_TARGET"
    exit 0
  fi

  if [ "$PLUGIN_MODE" = true ]; then
    case "$PLUGIN_SUBCOMMAND" in
      list)
        cmd_plugin_list "$PLUGIN_TARGET"
        ;;
      install)
        if [ -z "$PLUGIN_NAME" ]; then
          echo -e "${RED}${MSG_INIT_ERR_PLUGIN_INSTALL_USAGE}${NC}" >&2
          exit 1
        fi
        cmd_plugin_install "$PLUGIN_NAME" "$PLUGIN_TARGET"
        ;;
      uninstall)
        if [ -z "$PLUGIN_NAME" ]; then
          echo -e "${RED}${MSG_INIT_ERR_PLUGIN_UNINSTALL_USAGE}${NC}" >&2
          exit 1
        fi
        cmd_plugin_uninstall "$PLUGIN_NAME" "$PLUGIN_TARGET"
        ;;
      check-update)
        cmd_plugin_check_update "$PLUGIN_TARGET"
        ;;
      upgrade)
        if [ -z "$PLUGIN_NAME" ]; then
          echo -e "${RED}${MSG_INIT_ERR_PLUGIN_UPGRADE_USAGE}${NC}" >&2
          exit 1
        fi
        cmd_plugin_upgrade "$PLUGIN_NAME" "$PLUGIN_TARGET"
        ;;
      *)
        printf "${RED}${MSG_INIT_ERR_UNKNOWN_PLUGIN_SUB}${NC}\n" "$PLUGIN_SUBCOMMAND" >&2
        echo "$MSG_INIT_ERR_PLUGIN_USAGE"
        exit 1
        ;;
    esac
    exit 0
  fi
}

parse_cli_args() {
  local requested_presets preset

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_PROFILE_VALUE}${NC}" >&2
          usage
          exit 1
        fi
        validate_profile "$2"
        CLAUDE_PROFILE="$2"
        shift
        ;;
      --doctor)
        DOCTOR_MODE=true
        ;;
      --link)
        LINK_MODE=true
        ;;
      --link-dir)
        LINK_MODE=true
        LINK_DIR_MODE=true
        ;;
      --merge)
        MERGE_SETTINGS=true
        ;;
      --all)
        ALL_TOOLS=true
        TOOLS=(claude codex cursor gemini copilot)
        ;;
      --tools)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_TOOLS_VALUE}${NC}" >&2
          exit 1
        fi
        IFS=',' read -r -a TOOLS <<< "$2"
        shift
        ;;
      --update)
        UPDATE_MODE=true
        ;;
      --sync-mode)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_SYNCMODE_VALUE}${NC}" >&2
          usage
          exit 1
        fi
        validate_sync_mode "$2"
        SYNC_MODE_KIND="$2"
        shift
        ;;
      --sync-conflict)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_SYNCCONFLICT_VALUE}${NC}" >&2
          exit 1
        fi
        case "$2" in
          overwrite|skip|backup) SYNC_CONFLICT_STRATEGY="$2" ;;
          *) echo -e "${RED}${MSG_INIT_ERR_SYNCCONFLICT_INVALID}${NC}" >&2; exit 1 ;;
        esac
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      --diff)
        DIFF_MODE=true
        ;;
      --backup-all)
        BACKUP_ALL=true
        ;;
      --reapply)
        REAPPLY_MODE=true
        ;;
      --auto-mcp)
        AUTO_MCP=true
        ;;
      --project-name)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_PROJECTNAME_VALUE}${NC}" >&2
          usage
          exit 1
        fi
        USER_PROJECT_NAME_HINT="$2"
        shift
        ;;
      --archetype)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_ARCHETYPE_VALUE}${NC}" >&2
          usage
          exit 1
        fi
        USER_ARCHETYPE_HINT="$2"
        shift
        ;;
      --stack)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_STACK_VALUE}${NC}" >&2
          usage
          exit 1
        fi
        USER_STACK_HINT="$2"
        shift
        ;;
      --skip-ai)
        SKIP_AI=true
        ;;
      --lang)
        AI_SETTING_LANG="$2"
        load_locale "$SCRIPT_DIR"
        refresh_template_dir
        shift
        ;;
      --no-mcp)
        MCP_ENABLED=false
        USER_MCP_PRESET_SPECIFIED=true
        ;;
      --mcp-preset)
        if [ -z "${2:-}" ]; then
          echo -e "${RED}${MSG_INIT_ERR_MCPPRESET_VALUE}${NC}" >&2
          usage
          exit 1
        fi
        MCP_ENABLED=true
        USER_MCP_PRESET_SPECIFIED=true
        IFS=',' read -r -a requested_presets <<< "$2"
        for preset in "${requested_presets[@]}"; do
          preset="${preset// /}"
          if [ -n "$preset" ]; then
            add_mcp_preset "$preset"
          fi
        done
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --*)
        printf "${RED}${MSG_INIT_ERR_UNKNOWN_OPTION}${NC}\n" "$1" >&2
        usage
        exit 1
        ;;
      *)
        if [ "$SYNC_MODE" = true ]; then
          if [ -n "$SYNC_MANIFEST" ]; then
            echo -e "${RED}${MSG_INIT_ERR_SYNC_MANIFEST_DUP}${NC}" >&2
            usage
            exit 1
          fi
          SYNC_MANIFEST="$1"
        else
          if [ -n "$TARGET" ]; then
            echo -e "${RED}${MSG_INIT_ERR_TARGET_DUP}${NC}" >&2
            usage
            exit 1
          fi
          TARGET="$1"
        fi
        ;;
    esac
    shift
  done
}

validate_cli_mode_combinations() {
  local mode_count=0

  if [ "$DOCTOR_MODE" = true ]; then
    mode_count=$((mode_count + 1))
  fi
  if [ "$DRY_RUN" = true ]; then
    mode_count=$((mode_count + 1))
  fi
  if [ "$DIFF_MODE" = true ]; then
    mode_count=$((mode_count + 1))
  fi
  if [ "$mode_count" -gt 1 ]; then
    echo -e "${RED}${MSG_INIT_ERR_MODE_EXCLUSIVE}${NC}" >&2
    usage
    exit 1
  fi
  if [ "$SYNC_MODE" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
    echo -e "${RED}${MSG_INIT_ERR_SYNC_EXCLUSIVE}${NC}" >&2
    usage
    exit 1
  fi
  if [ "$UPDATE_MODE" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
    echo -e "${RED}${MSG_INIT_ERR_UPDATE_EXCLUSIVE}${NC}" >&2
    usage
    exit 1
  fi
  if [ "$BACKUP_ALL" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
    echo -e "${RED}${MSG_INIT_ERR_BACKUP_EXCLUSIVE}${NC}" >&2
    usage
    exit 1
  fi
  if [ "$REAPPLY_MODE" = true ] && { [ "$DOCTOR_MODE" = true ] || [ "$DIFF_MODE" = true ]; }; then
    echo -e "${RED}${MSG_INIT_ERR_REAPPLY_EXCLUSIVE}${NC}" >&2
    usage
    exit 1
  fi
}
