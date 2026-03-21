#!/bin/bash
# lib/fileops.sh — file/directory creation, copy, symlink, permission

resolve_copy_destination() {
  local src="$1"
  local dst="$2"

  if [ -d "$dst" ] || [[ "$dst" == */ ]]; then
    printf '%s%s\n' "$dst" "$(basename "$src")"
  else
    printf '%s\n' "$dst"
  fi
}

run_mkdir_p() {
  local path="$1"

  if [ "$DRY_RUN" = true ]; then
    if [ -d "$path" ]; then
      dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_DIR_KEEP" "$path")"
    else
      dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_DIR_CREATE" "$path")"
    fi
  else
    mkdir -p "$path"
  fi
}

run_remove_path() {
  local path="$1"

  if [ ! -e "$path" ]; then
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_REMOVE" "$path")"
  else
    rm -rf "$path"
  fi
}

run_copy() {
  local src="$1"
  local dst="$2"
  local final_path

  final_path="$(resolve_copy_destination "$src" "$dst")"

  if [ "$DRY_RUN" = true ]; then
    if [ -e "$final_path" ]; then
      dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_OVERWRITE" "$final_path")"
    else
      dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_FILE_CREATE" "$final_path")"
    fi
  else
    cp "$src" "$dst"
  fi
}

run_symlink() {
  local src="$1"
  local dst="$2"
  local final_path

  final_path="$(resolve_copy_destination "$src" "$dst")"

  if [ "$DRY_RUN" = true ]; then
    if [ -L "$final_path" ]; then
      dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_SYMLINK_UPDATE" "$final_path" "$src")"
    else
      dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_SYMLINK_CREATE" "$final_path" "$src")"
    fi
    return
  fi

  mkdir -p "$(dirname "$final_path")"
  ln -sfn "$src" "$final_path"
}

run_chmod_file() {
  local path="$1"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "$(printf "$MSG_FILEOPS_DRYRUN_CHMOD" "$path")"
  else
    chmod +x "$path"
  fi
}
