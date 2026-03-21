#!/bin/bash
# lib/assets.sh — 공유 자산 설치 (디렉토리 심링크, 파일 복사/심링크, 실행 권한)

install_shared_directory_link() {
  local src_dir="$1"
  local dst_dir="$2"

  if [ "$DRY_RUN" = true ]; then
    dry_run_note "$(printf "$MSG_ASSETS_DRYRUN_DIR_SYMLINK" "$dst_dir" "$src_dir")"
    return
  fi

  if [ -e "$dst_dir" ] && [ ! -L "$dst_dir" ]; then
    rm -rf "$dst_dir"
  fi
  ln -sfn "$src_dir" "$dst_dir"
  printf "  🔗 $MSG_ASSETS_DIR_SYMLINK\n" "$(basename "$dst_dir")" "$src_dir"
}

install_shared_asset() {
  local src="$1"
  local dst="$2"

  if [ "$LINK_MODE" = true ]; then
    run_symlink "$src" "$dst"
  else
    run_copy "$src" "$dst"
  fi
}

install_shared_executable_asset() {
  local src="$1"
  local dst="$2"

  if [ "$LINK_MODE" = true ]; then
    run_symlink "$src" "$dst"
  else
    run_copy "$src" "$dst"
    run_chmod_file "$(resolve_copy_destination "$src" "$dst")"
  fi
}
