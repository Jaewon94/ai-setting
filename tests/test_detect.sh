#!/bin/bash
# tests/test_detect.sh — archetype/stack 감지 검증
source "$(dirname "$0")/test_helper.sh"

suite "blank-start 감지"
t=$(make_tmpdir)
output=$("$INIT_SH" --skip-ai --dry-run "$t" 2>&1)
assert_output_contains "$output" "blank-start" "빈 디렉토리 → blank-start"

suite "frontend-web (Next.js) 감지"
t=$(make_tmpdir)
mkdir -p "$t/src/app"
echo '{"dependencies":{"next":"14.0.0"}}' > "$t/package.json"
touch "$t/next.config.ts"
output=$("$INIT_SH" --skip-ai --dry-run "$t" 2>&1)
assert_output_contains "$output" "frontend-web" "Next.js → frontend-web"
assert_output_contains "$output" "Next.js" "스택 Next.js 감지"

suite "backend-api (Python) 감지"
t=$(make_tmpdir)
mkdir -p "$t/app"
echo '[project]' > "$t/pyproject.toml"
echo 'from fastapi import FastAPI' > "$t/app/main.py"
echo '# API' > "$t/README.md"
output=$("$INIT_SH" --skip-ai --dry-run "$t" 2>&1)
assert_output_contains "$output" "Python" "Python 스택 감지"

suite "cli-tool (Go) 감지"
t=$(make_tmpdir)
mkdir -p "$t/cmd"
echo 'module example.com/cli' > "$t/go.mod"
echo '# CLI' > "$t/README.md"
output=$("$INIT_SH" --skip-ai --dry-run "$t" 2>&1)
assert_output_contains "$output" "Go" "Go 스택 감지"

suite "사용자 힌트 우선"
t=$(make_tmpdir)
output=$("$INIT_SH" --skip-ai --dry-run --archetype backend-api --stack Python "$t" 2>&1)
assert_output_contains "$output" "backend-api" "archetype 힌트 적용"
assert_output_contains "$output" "Python" "stack 힌트 적용"

suite "auto-mcp (frontend-web → core,web)"
t=$(make_tmpdir)
mkdir -p "$t/src/app"
echo '{"dependencies":{"next":"14.0.0"}}' > "$t/package.json"
output=$("$INIT_SH" --skip-ai --auto-mcp --dry-run "$t" 2>&1)
assert_output_contains "$output" "core,web" "auto-mcp → core,web"

suite "archetype partial 삽입 — frontend-web"
t=$(make_tmpdir)
mkdir -p "$t/src/app"
echo '{"dependencies":{"next":"14"}}' > "$t/package.json"
touch "$t/next.config.ts"
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_contains "$t/CLAUDE.md" "Frontend 규칙" "frontend-web partial 삽입됨"
assert_file_contains "$t/AGENTS.md" "Frontend Agent Rules" "frontend-web AGENTS partial 삽입됨"

suite "archetype partial 삽입 — backend-api"
t=$(make_tmpdir)
mkdir -p "$t/app"
echo '[project]' > "$t/pyproject.toml"
echo 'from fastapi import FastAPI' > "$t/app/main.py"
echo '# API' > "$t/README.md"
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_contains "$t/CLAUDE.md" "API 규칙" "backend-api partial 삽입됨"
assert_file_contains "$t/AGENTS.md" "Backend Agent Rules" "backend-api AGENTS partial 삽입됨"

suite "cursor rules — frontend-web"
t=$(make_tmpdir)
mkdir -p "$t/src/app"
echo '{"dependencies":{"next":"14"}}' > "$t/package.json"
touch "$t/next.config.ts"
"$INIT_SH" --skip-ai --tools claude,cursor "$t" >/dev/null 2>&1
assert_file_exists "$t/.cursor/rules/ai-setting.mdc" "frontend 공통 rule 생성"
assert_file_exists "$t/.cursor/rules/typescript.mdc" "frontend TS rule 생성"
assert_file_exists "$t/.cursor/rules/frontend.mdc" "frontend archetype rule 생성"
assert_file_exists "$t/.cursor/rules/testing.mdc" "frontend testing rule 생성"
assert_file_not_exists "$t/.cursor/rules/backend.mdc" "frontend에 backend rule 없음"

suite "cursor rules — backend-api"
t=$(make_tmpdir)
mkdir -p "$t/app"
echo '[project]' > "$t/pyproject.toml"
echo 'from fastapi import FastAPI' > "$t/app/main.py"
echo '# API' > "$t/README.md"
"$INIT_SH" --skip-ai --tools claude,cursor "$t" >/dev/null 2>&1
assert_file_exists "$t/.cursor/rules/ai-setting.mdc" "backend 공통 rule 생성"
assert_file_exists "$t/.cursor/rules/python.mdc" "backend Python rule 생성"
assert_file_exists "$t/.cursor/rules/backend.mdc" "backend archetype rule 생성"
assert_file_exists "$t/.cursor/rules/testing.mdc" "backend testing rule 생성"
assert_file_not_exists "$t/.cursor/rules/frontend.mdc" "backend에 frontend rule 없음"

suite "cursor rules — docs-first"
t=$(make_tmpdir)
mkdir -p "$t/docs"
echo '# Project' > "$t/README.md"
echo '# PRD' > "$t/docs/prd.md"
"$INIT_SH" --skip-ai --tools claude,cursor "$t" >/dev/null 2>&1
assert_file_exists "$t/.cursor/rules/ai-setting.mdc" "docs-first 공통 rule 생성"
assert_file_exists "$t/.cursor/rules/docs.mdc" "docs-first docs rule 생성"
assert_file_not_exists "$t/.cursor/rules/frontend.mdc" "docs-first에 frontend rule 없음"
assert_file_not_exists "$t/.cursor/rules/backend.mdc" "docs-first에 backend rule 없음"

suite "cursor rules — cli-tool"
t=$(make_tmpdir)
mkdir -p "$t/cmd"
echo 'module example.com/cli' > "$t/go.mod"
echo '# CLI' > "$t/README.md"
"$INIT_SH" --skip-ai --tools claude,cursor "$t" >/dev/null 2>&1
assert_file_exists "$t/.cursor/rules/ai-setting.mdc" "cli 공통 rule 생성"
assert_file_exists "$t/.cursor/rules/cli-library.mdc" "cli/library rule 생성"
assert_file_exists "$t/.cursor/rules/testing.mdc" "cli testing rule 생성"
assert_file_not_exists "$t/.cursor/rules/backend.mdc" "cli에 backend rule 없음"

suite "copilot instructions — frontend-web"
t=$(make_tmpdir)
mkdir -p "$t/src/app"
echo '{"dependencies":{"next":"14"}}' > "$t/package.json"
touch "$t/next.config.ts"
"$INIT_SH" --skip-ai --tools claude,copilot "$t" >/dev/null 2>&1
assert_file_exists "$t/.github/copilot-instructions.md" "frontend copilot 공통 instructions 생성"
assert_file_exists "$t/.github/instructions/typescript.instructions.md" "frontend copilot TS instructions 생성"
assert_file_exists "$t/.github/instructions/frontend.instructions.md" "frontend copilot archetype instructions 생성"
assert_file_exists "$t/.github/instructions/testing.instructions.md" "frontend copilot testing instructions 생성"
assert_file_not_exists "$t/.github/instructions/backend.instructions.md" "frontend에 backend copilot instructions 없음"

suite "copilot instructions — backend-api"
t=$(make_tmpdir)
mkdir -p "$t/app"
echo '[project]' > "$t/pyproject.toml"
echo 'from fastapi import FastAPI' > "$t/app/main.py"
echo '# API' > "$t/README.md"
"$INIT_SH" --skip-ai --tools claude,copilot "$t" >/dev/null 2>&1
assert_file_exists "$t/.github/copilot-instructions.md" "backend copilot 공통 instructions 생성"
assert_file_exists "$t/.github/instructions/python.instructions.md" "backend copilot Python instructions 생성"
assert_file_exists "$t/.github/instructions/backend.instructions.md" "backend copilot archetype instructions 생성"
assert_file_exists "$t/.github/instructions/testing.instructions.md" "backend copilot testing instructions 생성"
assert_file_not_exists "$t/.github/instructions/frontend.instructions.md" "backend에 frontend copilot instructions 없음"

suite "copilot instructions — docs-first"
t=$(make_tmpdir)
mkdir -p "$t/docs"
echo '# Project' > "$t/README.md"
echo '# PRD' > "$t/docs/prd.md"
"$INIT_SH" --skip-ai --tools claude,copilot "$t" >/dev/null 2>&1
assert_file_exists "$t/.github/copilot-instructions.md" "docs-first copilot 공통 instructions 생성"
assert_file_exists "$t/.github/instructions/docs.instructions.md" "docs-first copilot docs instructions 생성"
assert_file_not_exists "$t/.github/instructions/frontend.instructions.md" "docs-first에 frontend copilot instructions 없음"
assert_file_not_exists "$t/.github/instructions/backend.instructions.md" "docs-first에 backend copilot instructions 없음"

suite "archetype partial 미삽입 — blank-start"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_exists "$t/CLAUDE.md" "CLAUDE.md 존재"
# general-app에는 partial이 없으므로 삽입 안 됨

print_summary
