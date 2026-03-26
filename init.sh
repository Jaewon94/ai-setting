#!/bin/bash
# init.sh — 새 프로젝트에 AI 도구 설정을 자동 적용
# 사용법: /path/to/ai-setting/init.sh [프로젝트 경로]
#
# 1단계: 공통 설정 파일 복사 (hooks, agents, skills, codex)
# 2단계: 프로젝트 로컬 MCP preset 생성
# 3단계: CLAUDE.md / AGENTS.md 템플릿 복사
# 4단계: AI로 템플릿의 [대괄호] 부분 자동 채우기
#         Claude Code → Codex → 수동 안내 (fallback 체인)

set -e

# 모듈 로드를 위한 SCRIPT_DIR 조기 설정
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 모듈 로드
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/ai-autofill.sh"
source "$SCRIPT_DIR/lib/cli.sh"
source "$SCRIPT_DIR/lib/deps.sh"
source "$SCRIPT_DIR/lib/init-flow.sh"
source "$SCRIPT_DIR/lib/validate.sh"
source "$SCRIPT_DIR/lib/fileops.sh"
source "$SCRIPT_DIR/lib/assets.sh"
source "$SCRIPT_DIR/lib/backup.sh"
source "$SCRIPT_DIR/lib/config-detect.sh"
source "$SCRIPT_DIR/lib/doctor.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/mcp.sh"
source "$SCRIPT_DIR/lib/profile.sh"
source "$SCRIPT_DIR/lib/sync.sh"
source "$SCRIPT_DIR/lib/plugin.sh"

# i18n: locale 로드 (--lang 플래그보다 먼저 기본값 로드, 이후 재로드 가능)
load_locale "$SCRIPT_DIR"
refresh_template_dir

reset_cli_state
preprocess_subcommand "$@"
run_preparsed_mode_if_needed
parse_cli_args "${CLI_ARGS[@]}"
validate_cli_mode_combinations

if [ "$SYNC_MODE" = true ]; then
  SYNC_MANIFEST="${SYNC_MANIFEST:-$SCRIPT_DIR/projects.manifest}"
  if run_sync_manifest "$SYNC_MANIFEST"; then
    exit 0
  else
    exit 1
  fi
fi

prepare_target_context "${TARGET:-.}"

if [ "$UPDATE_MODE" = true ]; then
  SKIP_AI=true
fi

apply_user_hints
calculate_recommended_mcp_presets
apply_auto_mcp_presets

MCP_PRESET_LABEL="none"
if [ "${#MCP_PRESETS[@]}" -gt 0 ]; then
  MCP_PRESET_LABEL="$(IFS=,; echo "${MCP_PRESETS[*]}")"
fi

if [ "$DOCTOR_MODE" = true ]; then
  if run_doctor "$TARGET"; then
    exit 0
  else
    exit 1
  fi
fi

if [ "$DIFF_MODE" = true ]; then
  if run_diff_preview "$TARGET"; then
    exit 0
  else
    exit 1
  fi
fi

print_init_overview

ensure_jq_dependency
run_init_file_setup_steps

run_ai_autofill_step

# ============================================================
# 7단계: 완료 요약
# ============================================================
print_init_summary
