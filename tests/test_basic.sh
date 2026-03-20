#!/bin/bash
# tests/test_basic.sh — 기본 init + doctor 테스트
source "$(dirname "$0")/test_helper.sh"

suite "기본 init (Claude Code만)"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/settings.json" ".claude/settings.json 존재"
assert_file_exists "$t/.claude/hooks/protect-files.sh" "protect-files.sh 존재"
assert_file_exists "$t/.mcp.json" ".mcp.json 존재"
assert_file_exists "$t/BEHAVIORAL_CORE.md" "BEHAVIORAL_CORE.md 존재"
assert_file_exists "$t/CLAUDE.md" "CLAUDE.md 존재"
assert_file_exists "$t/AGENTS.md" "AGENTS.md 존재"
assert_file_exists "$t/docs/decisions.md" "docs/decisions.md 존재"
assert_file_exists "$t/docs/research-notes.md" "docs/research-notes.md 존재"
assert_file_not_exists "$t/.cursor" "기본에서 .cursor 없음"
assert_file_not_exists "$t/.gemini" "기본에서 .gemini 없음"
assert_file_not_exists "$t/.codex" "기본에서 .codex 없음"
assert_file_not_exists "$t/GEMINI.md" "기본에서 GEMINI.md 없음"

suite "doctor (ERROR 0)"
output=$("$INIT_SH" --doctor "$t" 2>&1)
assert_output_contains "$output" "ERROR: 0" "doctor ERROR 0"

suite "doctor 문서 형식 검사"
t_doctor=$(make_tmpdir)
mkdir -p "$t_doctor/src"
echo '{"dependencies":{"typescript":"5"}}' > "$t_doctor/package.json"
"$INIT_SH" --skip-ai "$t_doctor" >/dev/null 2>&1
output=$("$INIT_SH" --doctor "$t_doctor" 2>&1)
assert_output_contains "$output" "docs/decisions.md에 템플릿 플레이스홀더가 남아 있음" "doctor decisions placeholder 검사"
assert_output_contains "$output" "docs/research-notes.md에 템플릿 플레이스홀더가 남아 있음" "doctor research placeholder 검사"
assert_output_contains "$output" "docs/decisions.md 확인일 형식 확인" "doctor decisions date 검사"
assert_output_contains "$output" "docs/research-notes.md 출처 링크 형식 확인" "doctor research source 검사"

suite "--all (전체 설치)"
t2=$(make_tmpdir)
"$INIT_SH" --skip-ai --all "$t2" >/dev/null 2>&1
assert_file_exists "$t2/.claude/settings.json" ".claude/settings.json"
assert_file_exists "$t2/.cursor/rules/ai-setting.mdc" ".cursor/rules/ai-setting.mdc"
assert_file_exists "$t2/.gemini/settings.json" ".gemini/settings.json"
assert_file_exists "$t2/.codex/config.toml" ".codex/config.toml"
assert_file_exists "$t2/BEHAVIORAL_CORE.md" "BEHAVIORAL_CORE.md"
assert_file_exists "$t2/GEMINI.md" "GEMINI.md"
assert_file_exists "$t2/.codex/config.toml" "codex config.toml"
assert_file_exists "$t2/.github/copilot-instructions.md" "copilot-instructions.md"

suite "help 출력"
output=$("$INIT_SH" --help 2>&1)
assert_output_contains "$output" "--tools" "help에 --tools 포함"
assert_output_contains "$output" "--all" "help에 --all 포함"
assert_output_contains "$output" "add-tool" "help에 add-tool 포함"

suite "dry-run"
t3=$(make_tmpdir)
output=$("$INIT_SH" --skip-ai --dry-run "$t3" 2>&1)
ec=$?
assert_exit_code 0 "$ec" "dry-run 정상 종료"
assert_output_contains "$output" "dry-run" "dry-run 출력 포함"

suite "멱등성 (2회 실행)"
t4=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t4" >/dev/null 2>&1
"$INIT_SH" --skip-ai "$t4" >/dev/null 2>&1
ec=$?
assert_exit_code 0 "$ec" "2회 실행 정상"
assert_file_exists "$t4/.claude/settings.json" "2회 실행 후 settings.json 존재"

suite "Codex fallback 호출 형식"
t5=$(make_tmpdir)
mkdir -p "$t5/src" "$t5/bin"
echo '{"name":"fallback-check","scripts":{"test":"echo ok"}}' > "$t5/package.json"
cat > "$t5/bin/codex" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" > "$CODEX_ARGS_LOG"
exit 0
EOF
chmod +x "$t5/bin/codex"
output=$(PATH="$t5/bin:/usr/bin:/bin:/usr/sbin:/sbin" CODEX_ARGS_LOG="$t5/codex-args.log" "$INIT_SH" --all "$t5" 2>&1)
assert_output_contains "$output" "Codex가 프로젝트 문서를 자동 생성했습니다" "codex fallback 성공 메시지"
assert_file_contains "$t5/codex-args.log" "exec" "codex exec 사용"
assert_file_contains "$t5/codex-args.log" "--skip-git-repo-check" "codex git 체크 우회"

print_summary
