#\!/bin/bash
# lib/plugin.sh — 플러그인 list/install/uninstall/check-update/upgrade

cmd_plugin_list() {
  local marketplace="$SCRIPT_DIR/.claude-plugin/marketplace.json"

  if [ ! -f "$marketplace" ]; then
    echo -e "${RED}오류: marketplace.json을 찾을 수 없습니다${NC}" >&2
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    echo -e "${RED}오류: jq가 필요합니다${NC}" >&2
    return 1
  fi

  local target="${1:-.}"
  local installed_file="$target/.ai-setting/installed-plugins.json"

  echo -e "${CYAN}━━━ Available Plugins ━━━${NC}"
  jq -r '.plugins[] | "  \(.name) v\(.version) — \(.description)"' "$marketplace"

  if [ -f "$installed_file" ]; then
    echo ""
    echo -e "${CYAN}━━━ Installed Plugins ━━━${NC}"
    jq -r 'to_entries[] | "  \(.key) v\(.value.version) — installed \(.value.installed_at)"' "$installed_file"
  fi
}

cmd_plugin_install() {
  local plugin_name="$1"
  local target="${2:-.}"
  local marketplace="$SCRIPT_DIR/.claude-plugin/marketplace.json"

  if ! command -v jq &>/dev/null; then
    echo -e "${RED}오류: jq가 필요합니다${NC}" >&2
    return 1
  fi

  local plugin_source
  plugin_source="$(jq -r --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .source' "$marketplace")"

  if [ -z "$plugin_source" ]; then
    echo -e "${RED}오류: 플러그인 '${plugin_name}'을 찾을 수 없습니다${NC}" >&2
    return 1
  fi

  local plugin_dir="$SCRIPT_DIR/$plugin_source"
  local plugin_version
  plugin_version="$(jq -r --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .version' "$marketplace")"

  echo -e "${CYAN}━━━ Plugin Install: ${plugin_name} v${plugin_version} ━━━${NC}"

  # Copy hooks scripts
  if [ -d "$plugin_dir/scripts" ]; then
    mkdir -p "$target/.claude/hooks"
    for script in "$plugin_dir/scripts/"*.sh; do
      [ -f "$script" ] || continue
      cp "$script" "$target/.claude/hooks/"
      chmod +x "$target/.claude/hooks/$(basename "$script")"
      echo "  ✅ hook 스크립트 설치: $(basename "$script")"
    done
  fi

  # Copy agents
  if [ -d "$plugin_dir/agents" ]; then
    mkdir -p "$target/.claude/agents"
    for agent in "$plugin_dir/agents/"*.md; do
      [ -f "$agent" ] || continue
      cp "$agent" "$target/.claude/agents/"
      echo "  ✅ agent 설치: $(basename "$agent")"
    done
  fi

  # Copy skills
  if [ -d "$plugin_dir/skills" ]; then
    for skill_dir in "$plugin_dir/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      local skill_name
      skill_name="$(basename "$skill_dir")"
      mkdir -p "$target/.claude/skills/$skill_name"
      cp "$skill_dir"* "$target/.claude/skills/$skill_name/" 2>/dev/null || true
      echo "  ✅ skill 설치: $skill_name"
    done
  fi

  # Merge hooks.json into settings.json
  if [ -f "$plugin_dir/hooks/hooks.json" ] && [ -f "$target/.claude/settings.json" ]; then
    local merged
    merged="$(jq -s '
      def merge_hooks:
        reduce .[] as $item ({}; . * $item);
      .[0] as $base | .[1].hooks as $new_hooks |
      $base * {hooks: ($base.hooks // {} | to_entries | map({key: .key, value: .value}) |
        from_entries) * ($new_hooks // {})}
    ' "$target/.claude/settings.json" "$plugin_dir/hooks/hooks.json" 2>/dev/null)"
    if [ $? -eq 0 ] && [ -n "$merged" ]; then
      echo "$merged" > "$target/.claude/settings.json"
      echo "  ✅ hooks.json → settings.json merge 완료"
    fi
  fi

  # Record installation
  mkdir -p "$target/.ai-setting"
  local installed_file="$target/.ai-setting/installed-plugins.json"
  local now
  now="$(date '+%Y-%m-%d %H:%M:%S')"
  if [ -f "$installed_file" ]; then
    jq --arg name "$plugin_name" --arg ver "$plugin_version" --arg at "$now" \
      '. + {($name): {version: $ver, installed_at: $at}}' "$installed_file" > "${installed_file}.tmp"
    mv "${installed_file}.tmp" "$installed_file"
  else
    jq -n --arg name "$plugin_name" --arg ver "$plugin_version" --arg at "$now" \
      '{($name): {version: $ver, installed_at: $at}}' > "$installed_file"
  fi

  echo ""
  echo -e "${GREEN}✅ ${plugin_name} v${plugin_version} 설치 완료${NC}"
}

cmd_plugin_uninstall() {
  local plugin_name="$1"
  local target="${2:-.}"
  local marketplace="$SCRIPT_DIR/.claude-plugin/marketplace.json"

  if ! command -v jq &>/dev/null; then
    echo -e "${RED}오류: jq가 필요합니다${NC}" >&2
    return 1
  fi

  local plugin_source
  plugin_source="$(jq -r --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .source' "$marketplace")"

  if [ -z "$plugin_source" ]; then
    echo -e "${RED}오류: 플러그인 '${plugin_name}'을 찾을 수 없습니다${NC}" >&2
    return 1
  fi

  local plugin_dir="$SCRIPT_DIR/$plugin_source"

  echo -e "${CYAN}━━━ Plugin Uninstall: ${plugin_name} ━━━${NC}"

  # Remove hooks scripts
  if [ -d "$plugin_dir/scripts" ]; then
    for script in "$plugin_dir/scripts/"*.sh; do
      [ -f "$script" ] || continue
      local target_script="$target/.claude/hooks/$(basename "$script")"
      if [ -f "$target_script" ]; then
        rm "$target_script"
        echo "  🗑 hook 스크립트 제거: $(basename "$script")"
      fi
    done
  fi

  # Remove agents
  if [ -d "$plugin_dir/agents" ]; then
    for agent in "$plugin_dir/agents/"*.md; do
      [ -f "$agent" ] || continue
      local target_agent="$target/.claude/agents/$(basename "$agent")"
      if [ -f "$target_agent" ]; then
        rm "$target_agent"
        echo "  🗑 agent 제거: $(basename "$agent")"
      fi
    done
  fi

  # Remove installed record
  local installed_file="$target/.ai-setting/installed-plugins.json"
  if [ -f "$installed_file" ]; then
    jq --arg name "$plugin_name" 'del(.[$name])' "$installed_file" > "${installed_file}.tmp"
    mv "${installed_file}.tmp" "$installed_file"
  fi

  echo ""
  echo -e "${GREEN}✅ ${plugin_name} 제거 완료${NC}"
}

cmd_plugin_check_update() {
  local target="${1:-.}"
  local marketplace="$SCRIPT_DIR/.claude-plugin/marketplace.json"
  local installed_file="$target/.ai-setting/installed-plugins.json"

  if ! command -v jq &>/dev/null; then
    echo -e "${RED}오류: jq가 필요합니다${NC}" >&2
    return 1
  fi

  if [ ! -f "$installed_file" ]; then
    echo "설치된 플러그인이 없습니다."
    return 0
  fi

  echo -e "${CYAN}━━━ Plugin Update Check ━━━${NC}"
  local has_update=false

  while IFS= read -r name; do
    local installed_ver
    local latest_ver
    installed_ver="$(jq -r --arg n "$name" '.[$n].version' "$installed_file")"
    latest_ver="$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .version' "$marketplace")"

    if [ -z "$latest_ver" ]; then
      echo "  ${name}: marketplace에서 찾을 수 없음"
      continue
    fi

    if [ "$installed_ver" != "$latest_ver" ]; then
      echo -e "  ${YELLOW}${name}: ${installed_ver} → ${latest_ver} (업데이트 가능)${NC}"
      has_update=true
    else
      echo "  ${name}: ${installed_ver} (최신)"
    fi
  done < <(jq -r 'keys[]' "$installed_file")

  if [ "$has_update" = true ]; then
    echo ""
    echo "업데이트하려면: ai-setting plugin upgrade <name> <target>"
  fi
}

cmd_plugin_upgrade() {
  local plugin_name="$1"
  local target="${2:-.}"

  echo "기존 플러그인 제거 후 재설치합니다..."
  cmd_plugin_uninstall "$plugin_name" "$target"
  cmd_plugin_install "$plugin_name" "$target"
}
