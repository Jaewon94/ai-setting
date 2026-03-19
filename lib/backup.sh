#!/bin/bash
# lib/backup.sh — 백업 스냅샷 생성 및 기존 경로 백업

build_backup_managed_paths() {
  BACKUP_MANAGED_PATHS=(
    ".claude"
    ".cursor/rules/ai-setting.mdc"
    ".cursor/rules/typescript.mdc"
    ".cursor/rules/python.mdc"
    ".cursor/rules/testing.mdc"
    ".gemini/settings.json"
    ".codex/config.toml"
    ".mcp.json"
    "CLAUDE.md"
    "AGENTS.md"
    "GEMINI.md"
    ".github/copilot-instructions.md"
    ".github/pull_request_template.md"
    ".ai-setting/team-webhook.json"
    "docs/decisions.md"
  )
}

snapshot_managed_path() {
  local rel_path="$1"
  local source_path="$TARGET/$rel_path"
  local backup_path="$BACKUP_SNAPSHOT_DIR/$rel_path"

  if [ ! -e "$source_path" ]; then
    return
  fi

  BACKUP_ALL_CREATED=true

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "backup-all 스냅샷: ${source_path} -> ${backup_path}"
    return
  fi

  mkdir -p "$(dirname "$backup_path")"
  if [ -d "$source_path" ]; then
    cp -R "$source_path" "$backup_path"
  else
    cp "$source_path" "$backup_path"
  fi
}

perform_backup_all() {
  local rel_path

  build_backup_managed_paths
  BACKUP_ALL_CREATED=false
  BACKUP_SNAPSHOT_DIR="$TARGET/.ai-setting.backup.$RUN_TIMESTAMP"

  echo -e "${CYAN}backup-all:${NC} 관리 대상 전체 스냅샷 생성"
  echo "  📦 경로: ${BACKUP_SNAPSHOT_DIR}"

  for rel_path in "${BACKUP_MANAGED_PATHS[@]}"; do
    snapshot_managed_path "$rel_path"
  done

  if [ "$BACKUP_ALL_CREATED" = true ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  ✅ backup-all 스냅샷 생성 예정"
    else
      echo "  ✅ backup-all 스냅샷 생성됨"
    fi
  else
    echo -e "  ${YELLOW}관리 대상 기존 파일이 없어 백업할 내용이 없습니다${NC}"
  fi

  echo ""
}

backup_existing_path() {
  local path="$1"
  local label="$2"
  local backup_path

  if [ ! -e "$path" ]; then
    return
  fi

  if [ "$BACKUP_ALL" = true ] && [ "$BACKUP_ALL_CREATED" = true ]; then
    echo -e "${YELLOW}  ⚠ ${label} 이미 존재 — backup-all snapshot에 포함됨${NC}"
    echo -e "  📦 snapshot: ${BACKUP_SNAPSHOT_DIR}"
    return
  fi

  backup_path="${path}.backup.${RUN_TIMESTAMP}"
  echo -e "${YELLOW}  ⚠ ${label} 이미 존재 — 백업 후 덮어쓰기${NC}"
  echo -e "  📦 백업: ${backup_path}"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "백업 생성: ${backup_path}"
  elif [ -d "$path" ]; then
    cp -r "$path" "$backup_path"
  else
    cp "$path" "$backup_path"
  fi
}

count_existing_paths() {
  local base="$1"
  shift
  local count=0
  local rel_path

  for rel_path in "$@"; do
    if [ -e "$base/$rel_path" ]; then
      count=$((count + 1))
    fi
  done

  echo "$count"
}

join_existing_paths() {
  local base="$1"
  shift
  local rel_path
  local matches=()
  local old_ifs="$IFS"

  for rel_path in "$@"; do
    if [ -e "$base/$rel_path" ]; then
      matches+=("$rel_path")
    fi
  done

  if [ "${#matches[@]}" -eq 0 ]; then
    echo "없음"
    return
  fi

  IFS=', '
  echo "${matches[*]}"
  IFS="$old_ifs"
}
