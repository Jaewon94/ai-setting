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

suite "archetype partial 삽입 — backend-api"
t=$(make_tmpdir)
mkdir -p "$t/app"
echo '[project]' > "$t/pyproject.toml"
echo 'from fastapi import FastAPI' > "$t/app/main.py"
echo '# API' > "$t/README.md"
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_contains "$t/CLAUDE.md" "API 규칙" "backend-api partial 삽입됨"

suite "archetype partial 미삽입 — blank-start"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_exists "$t/CLAUDE.md" "CLAUDE.md 존재"
# general-app에는 partial이 없으므로 삽입 안 됨

print_summary
