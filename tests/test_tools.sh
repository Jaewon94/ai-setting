#!/bin/bash
# tests/test_tools.sh — --tools, --all, add-tool 검증
source "$(dirname "$0")/test_helper.sh"

suite "--tools claude,cursor"
t=$(make_tmpdir)
mkdir -p "$t/src" && echo '{"dependencies":{"typescript":"5"}}' > "$t/package.json"
"$INIT_SH" --skip-ai --tools claude,cursor "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/settings.json" "claude 설치됨"
assert_file_exists "$t/.cursor/rules/ai-setting.mdc" "cursor 설치됨"
assert_file_exists "$t/.cursor/rules/typescript.mdc" "TS rule 감지 설치"
assert_file_not_exists "$t/.gemini" "gemini 없음"
assert_file_not_exists "$t/.codex" "codex 없음"
assert_file_not_exists "$t/CODEX.md" "CODEX.md 없음"

suite "--tools claude,codex"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai --tools claude,codex "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/settings.json" "claude 설치됨"
assert_file_exists "$t/.codex/config.toml" "codex 설치됨"
assert_file_not_exists "$t/.cursor" "cursor 없음"

suite "add-tool cursor"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_not_exists "$t/.cursor" "add 전 cursor 없음"
"$INIT_SH" add-tool cursor "$t" >/dev/null 2>&1
assert_file_exists "$t/.cursor/rules/ai-setting.mdc" "add 후 cursor 있음"

suite "add-tool gemini"
"$INIT_SH" add-tool gemini "$t" >/dev/null 2>&1
assert_file_exists "$t/.gemini/settings.json" "add 후 gemini 있음"
assert_file_exists "$t/GEMINI.md" "add 후 GEMINI.md 있음"

suite "add-tool codex"
"$INIT_SH" add-tool codex "$t" >/dev/null 2>&1
assert_file_exists "$t/.codex/config.toml" "add 후 codex 있음"
assert_file_exists "$t/.codex/config.toml" "add 후 config.toml 있음"

suite "add-tool copilot"
mkdir -p "$t/src"
echo '{"dependencies":{"typescript":"5"}}' > "$t/package.json"
"$INIT_SH" add-tool copilot "$t" >/dev/null 2>&1
assert_file_exists "$t/.github/copilot-instructions.md" "add 후 copilot 있음"
assert_file_exists "$t/.github/instructions/typescript.instructions.md" "add 후 copilot TS instructions 있음"
assert_file_exists "$t/.github/instructions/testing.instructions.md" "add 후 copilot test instructions 있음"

print_summary
