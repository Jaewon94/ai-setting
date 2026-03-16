#!/bin/bash
# init.sh — 새 프로젝트에 AI 도구 설정을 자동 적용
# 사용법: /path/to/ai-setting/init.sh [프로젝트 경로]
#
# 1단계: 공통 설정 파일 복사 (hooks, agents, skills, codex)
# 2단계: CLAUDE.md / AGENTS.md 템플릿 복사
# 3단계: AI로 템플릿의 [대괄호] 부분 자동 채우기
#         Claude Code → Codex → 수동 안내 (fallback 체인)

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --skip-ai 옵션: AI 자동 채우기 건너뛰기
SKIP_AI=false
for arg in "$@"; do
  if [ "$arg" = "--skip-ai" ]; then
    SKIP_AI=true
  fi
done

# ai-setting 디렉토리 (이 스크립트가 있는 곳)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 대상 프로젝트 디렉토리 (--skip-ai가 아닌 첫 번째 인자)
TARGET=""
for arg in "$@"; do
  if [ "$arg" != "--skip-ai" ]; then
    TARGET="$arg"
    break
  fi
done
TARGET="${TARGET:-.}"
TARGET="$(cd "$TARGET" && pwd)"

echo -e "${CYAN}━━━ AI Setting Init ━━━${NC}"
echo -e "소스: ${SCRIPT_DIR}"
echo -e "대상: ${TARGET}"
echo ""

# jq 의존성 체크 (hooks가 jq로 JSON 파싱)
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}⚠ jq가 설치되어 있지 않습니다.${NC}"
  echo -e "  hooks(protect-files, block-dangerous-commands)가 정상 동작하려면 jq가 필요합니다."
  echo -e "  설치: brew install jq (macOS) / sudo apt install jq (Linux)"
  echo ""
fi

# ============================================================
# 1단계: Claude Code 설정 복사
# ============================================================
echo -e "${GREEN}[1/5]${NC} Claude Code 설정 복사 (.claude/)"

if [ -d "$TARGET/.claude" ]; then
  echo -e "${YELLOW}  ⚠ .claude/ 이미 존재 — 덮어쓰기합니다${NC}"
fi

mkdir -p "$TARGET/.claude/hooks"
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/skills/deploy"
mkdir -p "$TARGET/.claude/skills/review"
mkdir -p "$TARGET/.claude/skills/fix-issue"
mkdir -p "$TARGET/.claude/skills/gap-check"
mkdir -p "$TARGET/.claude/skills/cross-validate"

cp "$SCRIPT_DIR/claude/settings.json" "$TARGET/.claude/settings.json"
cp "$SCRIPT_DIR/claude/hooks/protect-files.sh" "$TARGET/.claude/hooks/protect-files.sh"
cp "$SCRIPT_DIR/claude/hooks/block-dangerous-commands.sh" "$TARGET/.claude/hooks/block-dangerous-commands.sh"
chmod +x "$TARGET/.claude/hooks/"*.sh

cp "$SCRIPT_DIR/claude/agents/security-reviewer.md" "$TARGET/.claude/agents/"
cp "$SCRIPT_DIR/claude/agents/architect-reviewer.md" "$TARGET/.claude/agents/"
cp "$SCRIPT_DIR/claude/agents/test-writer.md" "$TARGET/.claude/agents/"
cp "$SCRIPT_DIR/claude/agents/research.md" "$TARGET/.claude/agents/"

cp "$SCRIPT_DIR/claude/skills/deploy/SKILL.md" "$TARGET/.claude/skills/deploy/"
cp "$SCRIPT_DIR/claude/skills/review/SKILL.md" "$TARGET/.claude/skills/review/"
cp "$SCRIPT_DIR/claude/skills/fix-issue/SKILL.md" "$TARGET/.claude/skills/fix-issue/"
cp "$SCRIPT_DIR/claude/skills/gap-check/SKILL.md" "$TARGET/.claude/skills/gap-check/"
cp "$SCRIPT_DIR/claude/skills/cross-validate/SKILL.md" "$TARGET/.claude/skills/cross-validate/"

echo "  ✅ settings.json, hooks 2개, agents 4개, skills 5개"

# ============================================================
# 2단계: Codex 설정 복사
# ============================================================
echo -e "${GREEN}[2/5]${NC} Codex CLI 설정 복사 (.codex/)"

mkdir -p "$TARGET/.codex"
cp "$SCRIPT_DIR/codex/config.toml" "$TARGET/.codex/config.toml"

echo "  ✅ config.toml"

# ============================================================
# 3단계: CLAUDE.md / AGENTS.md 템플릿 복사
# ============================================================
echo -e "${GREEN}[3/5]${NC} 템플릿 복사"

TEMPLATES_COPIED=false

if [ ! -f "$TARGET/CLAUDE.md" ]; then
  cp "$SCRIPT_DIR/templates/CLAUDE.md.template" "$TARGET/CLAUDE.md"
  echo "  ✅ CLAUDE.md 생성됨"
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}⚠ CLAUDE.md 이미 존재 — 건너뜀${NC}"
fi

if [ ! -f "$TARGET/AGENTS.md" ]; then
  cp "$SCRIPT_DIR/templates/AGENTS.md.template" "$TARGET/AGENTS.md"
  echo "  ✅ AGENTS.md 생성됨"
  TEMPLATES_COPIED=true
else
  echo -e "  ${YELLOW}⚠ AGENTS.md 이미 존재 — 건너뜀${NC}"
fi

mkdir -p "$TARGET/docs"
if [ ! -f "$TARGET/docs/decisions.md" ]; then
  cp "$SCRIPT_DIR/templates/decisions.md.template" "$TARGET/docs/decisions.md"
  echo "  ✅ docs/decisions.md 생성됨"
else
  echo -e "  ${YELLOW}⚠ docs/decisions.md 이미 존재 — 건너뜀${NC}"
fi

# ============================================================
# 4단계: AI로 템플릿 자동 채우기 (Claude Code → Codex → 수동)
# ============================================================
echo -e "${GREEN}[4/5]${NC} AI로 CLAUDE.md / AGENTS.md 자동 생성"

AI_PROMPT="이 프로젝트의 디렉토리 구조, 파일들, package.json/pyproject.toml 등을 분석해서 CLAUDE.md와 AGENTS.md의 [대괄호] 부분을 이 프로젝트에 맞게 전부 채워줘. 대괄호를 실제 내용으로 교체하고, 프로젝트에 해당하지 않는 섹션은 제거해. 기존 템플릿의 공통 규칙(Coding Rules, Forbidden 등)은 유지하되 프로젝트 스택에 맞게 보강해."

if [ "$SKIP_AI" = true ]; then
  echo -e "  ${YELLOW}--skip-ai 옵션으로 건너뜀${NC}"
elif [ "$TEMPLATES_COPIED" = false ]; then
  echo -e "  ${YELLOW}새 템플릿이 없음 (이미 존재) — 건너뜀${NC}"
else
  AI_SUCCESS=false

  # 시도 1: Claude Code
  if command -v claude &> /dev/null; then
    echo "  🔄 Claude Code로 프로젝트 분석 중..."
    if cd "$TARGET" && claude -p "$AI_PROMPT" --allowedTools Write,Edit,Read,Glob,Grep 2>/dev/null; then
      AI_SUCCESS=true
      echo "  ✅ Claude Code가 CLAUDE.md / AGENTS.md를 자동 생성했습니다"
    else
      echo -e "  ${YELLOW}  Claude Code 실행 실패 — Codex로 시도합니다${NC}"
    fi
  else
    echo -e "  ${YELLOW}  Claude Code 미설치 — Codex로 시도합니다${NC}"
  fi

  # 시도 2: Codex (fallback)
  if [ "$AI_SUCCESS" = false ]; then
    if command -v codex &> /dev/null; then
      echo "  🔄 Codex로 프로젝트 분석 중..."
      if (cd "$TARGET" && codex -q "$AI_PROMPT") 2>/dev/null; then
        AI_SUCCESS=true
        echo "  ✅ Codex가 CLAUDE.md / AGENTS.md를 자동 생성했습니다"
      else
        echo -e "  ${YELLOW}  Codex 실행 실패${NC}"
      fi
    else
      echo -e "  ${YELLOW}  Codex 미설치${NC}"
    fi
  fi

  # 시도 3: 수동 안내 (최종 fallback)
  if [ "$AI_SUCCESS" = false ]; then
    echo ""
    echo -e "  ${RED}⚠ AI 자동 생성 실패${NC}"
    echo -e "  Claude Code와 Codex를 모두 사용할 수 없습니다."
    echo ""
    echo -e "  ${CYAN}수동으로 채우는 방법:${NC}"
    echo "    1. CLAUDE.md와 AGENTS.md를 열어서 [대괄호] 부분을 직접 채우세요"
    echo "    2. 또는 Claude Code / Codex 설치 후 프로젝트 디렉토리에서:"
    echo "       claude \"CLAUDE.md와 AGENTS.md의 [대괄호] 부분을 채워줘\""
    echo ""
  fi
fi

# ============================================================
# 5단계: 완료 요약
# ============================================================
echo ""
echo -e "${GREEN}[5/5]${NC} 완료!"
echo ""
echo -e "${CYAN}━━━ 적용된 설정 ━━━${NC}"
echo ""
echo "  바로 사용 가능:"
echo "    .claude/settings.json     — hooks 6개 (포맷터, 파일보호, 명령차단, 알림, 테스트체크, 리마인더)"
echo "    .claude/hooks/            — 파일 보호 + 위험 명령 차단"
echo "    .claude/agents/           — 보안 리뷰, 설계 검증, 테스트 작성, 리서치"
echo "    .claude/skills/           — 배포, 리뷰, 이슈수정, Gap체크, 교차검증"
echo "    .codex/config.toml        — Codex CLI 설정"
echo ""

if [ "$TEMPLATES_COPIED" = true ]; then
  echo "  프로젝트 맞춤 설정:"
  echo "    CLAUDE.md                 — 프로젝트 빌드/실행/도메인 설정"
  echo "    AGENTS.md                 — 아키텍처/스택/코딩 규칙"
  echo "    docs/decisions.md         — 기술 의사결정 기록"
fi
echo ""
