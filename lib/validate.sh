#!/bin/bash
# lib/validate.sh — 입력 검증 및 사용법 출력

usage() {
  cat <<EOF
사용법:
  $USAGE_NAME [옵션] [프로젝트 경로]
  $USAGE_NAME update [옵션] [프로젝트 경로]
  $USAGE_NAME sync [옵션] [manifest 경로]
  $USAGE_NAME plugin {list|install|uninstall|check-update|upgrade} [name] [target]

옵션:
  --profile PROFILE        Claude Code 프로필 지정 (standard|minimal|strict|team)
  --link                   공유 가능한 설정 자산을 복사 대신 심링크로 연결
  --link-dir               hooks/agents/skills 디렉토리를 통째로 심링크
  --update                 AI 자동 채우기 없이 공유 자산/MCP를 최신 상태로 갱신
  --sync-mode MODE         sync 명령에서 각 프로젝트에 적용할 방식 (update|init)
  --sync-conflict STRATEGY sync 시 충돌 해결 전략 (overwrite|skip|backup, 기본: backup)
  --doctor                 현재 프로젝트 설정 상태 진단
  --dry-run                실제 변경 없이 예정 작업만 출력
  --diff                   실제 변경 없이 관리 대상 파일 diff 출력
  --backup-all             적용 전 관리 대상 전체 스냅샷 백업
  --reapply                CLAUDE.md/AGENTS.md를 다시 생성하고 AI 채우기 재실행
  --auto-mcp               감지된 archetype 기반 추천 MCP preset 자동 적용
  --project-name NAME      프로젝트 이름 힌트 제공
  --archetype TYPE         프로젝트 archetype 힌트 제공
  --stack NAME             주 스택 힌트 제공
  --skip-ai                AI 자동 채우기 건너뛰기
  --mcp-preset PRESETS     프로젝트 로컬 MCP preset 지정 (예: core,web)
  --no-mcp                 프로젝트 로컬 MCP 생성 건너뛰기
  -h, --help               도움말 출력

플러그인:
  plugin list [target]               설치 가능/설치됨 플러그인 목록
  plugin install <name> [target]     플러그인 설치
  plugin uninstall <name> [target]   플러그인 제거
  plugin check-update [target]       설치된 플러그인 업데이트 확인
  plugin upgrade <name> [target]     플러그인 업그레이드

MCP preset:
  core   sequential-thinking, serena, upstash-context-7-mcp
  web    playwright (core와 함께 사용 권장)
  infra  docker (core와 함께 사용 권장)

Archetype:
  frontend-web | backend-api | cli-tool | worker-batch
  data-automation | library-sdk | infra-iac | general-app

sync manifest 형식:
  - 한 줄에 프로젝트 경로 하나씩 작성
  - 경로 뒤에 key=value 옵션 추가 가능 (profile=, mcp-preset=, archetype=, stack=)
  - 빈 줄과 '#'으로 시작하는 주석은 무시
  - 상대 경로는 manifest 파일 기준으로 해석
EOF
}

validate_profile() {
  local profile="$1"

  case "$profile" in
    standard|minimal|strict|team)
      ;;
    *)
      echo -e "${RED}오류: 알 수 없는 profile '$profile'${NC}" >&2
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
      echo -e "${RED}오류: 알 수 없는 sync mode '$sync_mode'${NC}" >&2
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
      echo -e "${RED}오류: 알 수 없는 archetype '$archetype'${NC}" >&2
      usage
      exit 1
      ;;
  esac
}
