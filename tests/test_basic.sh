#!/bin/bash
# tests/test_basic.sh — 기본 init + doctor 테스트
source "$(dirname "$0")/test_helper.sh"

suite "기본 init (Claude Code만)"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/settings.json" ".claude/settings.json 존재"
assert_file_exists "$t/.claude/hooks/protect-files.sh" "protect-files.sh 존재"
assert_file_exists "$t/.mcp.json" ".mcp.json 존재"
assert_file_exists "$t/.mcp.notes.md" ".mcp.notes.md 존재"
assert_file_exists "$t/.ai-setting/protect-files.json" ".ai-setting/protect-files.json 존재"
assert_file_exists "$t/.ai-setting/protect-files.notes.md" ".ai-setting/protect-files.notes.md 존재"
assert_file_exists "$t/BEHAVIORAL_CORE.md" "BEHAVIORAL_CORE.md 존재"
assert_file_exists "$t/CLAUDE.md" "CLAUDE.md 존재"
assert_file_exists "$t/AGENTS.md" "AGENTS.md 존재"
assert_file_contains "$t/CLAUDE.md" "도구 역할 분담" "CLAUDE 도구 역할 섹션 존재"
assert_file_contains "$t/CLAUDE.md" "프로필 운영 기준" "CLAUDE 프로필 운영 섹션 존재"
assert_file_exists "$t/docs/decisions.md" "docs/decisions.md 존재"
assert_file_exists "$t/docs/research-notes.md" "docs/research-notes.md 존재"
assert_file_not_exists "$t/.cursor" "기본에서 .cursor 없음"
assert_file_not_exists "$t/.gemini" "기본에서 .gemini 없음"
assert_file_not_exists "$t/.codex" "기본에서 .codex 없음"
assert_file_not_exists "$t/GEMINI.md" "기본에서 GEMINI.md 없음"

suite "doctor (ERROR 0)"
output=$("$INIT_SH" --doctor "$t" 2>&1)
assert_output_contains "$output" "ERROR: 0" "doctor ERROR 0"
assert_output_contains "$output" "AI 자동 채우기" "doctor autofill readiness 표시"

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

suite "doctor blank-start autofill 안내"
t_blank=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t_blank" >/dev/null 2>&1
output=$("$INIT_SH" --doctor "$t_blank" 2>&1)
assert_output_contains "$output" "프로젝트 근거가 거의 없어 AI 자동 채우기는 기본적으로 건너뜀" "doctor blank-start autofill 안내"

suite "--all (전체 설치)"
t2=$(make_tmpdir)
"$INIT_SH" --skip-ai --all "$t2" >/dev/null 2>&1
assert_file_exists "$t2/.claude/settings.json" ".claude/settings.json"
assert_file_exists "$t2/.cursor/rules/ai-setting.mdc" ".cursor/rules/ai-setting.mdc"
assert_file_exists "$t2/.gemini/settings.json" ".gemini/settings.json"
assert_file_exists "$t2/.gemini/settings.notes.md" ".gemini/settings.notes.md"
assert_file_exists "$t2/.codex/config.toml" ".codex/config.toml"
assert_file_exists "$t2/.codex/config.notes.md" ".codex/config.notes.md"
assert_file_exists "$t2/.mcp.notes.md" ".mcp.notes.md"
assert_file_exists "$t2/.ai-setting/protect-files.json" ".ai-setting/protect-files.json"
assert_file_exists "$t2/.ai-setting/protect-files.notes.md" ".ai-setting/protect-files.notes.md"
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

suite "Claude timeout 후 Codex fallback"
t6=$(make_tmpdir)
mkdir -p "$t6/src" "$t6/bin"
echo '{"name":"claude-timeout-check","scripts":{"test":"echo ok"}}' > "$t6/package.json"
cat > "$t6/bin/claude" <<'EOF'
#!/bin/sh
sleep 2
exit 0
EOF
cat > "$t6/bin/codex" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" > "$CODEX_ARGS_LOG"
exit 0
EOF
chmod +x "$t6/bin/claude" "$t6/bin/codex"
output=$(PATH="$t6/bin:/usr/bin:/bin:/usr/sbin:/sbin" AI_SETTING_CLAUDE_TIMEOUT_SEC=1 CODEX_ARGS_LOG="$t6/codex-args.log" "$INIT_SH" --all "$t6" 2>&1)
assert_output_contains "$output" "Claude Code timeout (1s) — Codex로 시도합니다" "claude timeout 메시지"
assert_output_contains "$output" "Codex가 프로젝트 문서를 자동 생성했습니다" "timeout 후 codex fallback 성공"
assert_file_contains "$t6/codex-args.log" "exec" "timeout 후 codex 실행"

suite "Homebrew formula 렌더러"
t7=$(make_tmpdir)
"$REPO_ROOT/scripts/render-homebrew-formula.sh" "v1.0.0" "deadbeef" "$t7/ai-setting.rb" "Jaewon94/ai-setting"
assert_file_contains "$t7/ai-setting.rb" 'url "https://github.com/Jaewon94/ai-setting/archive/refs/tags/v1.0.0.tar.gz"' "formula url 렌더링"
assert_file_contains "$t7/ai-setting.rb" 'sha256 "deadbeef"' "formula sha256 렌더링"

suite "MCP notes guide"
t8=$(make_tmpdir)
"$INIT_SH" --skip-ai --tools claude,codex --mcp-preset core,local "$t8" >/dev/null 2>&1
assert_file_contains "$t8/.mcp.notes.md" "YOUR_API_KEY_HERE" "API 키 placeholder 안내"
assert_file_contains "$t8/.mcp.notes.md" "/absolute/path/to/project" "경로 placeholder 안내"
assert_file_contains "$t8/.mcp.notes.md" "Current value" "현재 filesystem 경로 안내"
assert_file_contains "$t8/.codex/config.toml" "Replace" "Codex MCP 주석 안내"

suite "Gemini notes guide"
t9=$(make_tmpdir)
"$INIT_SH" --skip-ai --tools claude,gemini "$t9" >/dev/null 2>&1
assert_file_exists "$t9/.gemini/settings.notes.md" "gemini settings notes 생성"
assert_file_contains "$t9/.gemini/settings.json" '"discoveryMaxDirs": 200' "gemini discoveryMaxDirs 설정"
assert_file_contains "$t9/.gemini/settings.json" '"loadMemoryFromIncludeDirectories": false' "gemini memory load 기본값"
assert_file_contains "$t9/.gemini/settings.json" '"enableRecursiveFileSearch": true' "gemini recursive file search 설정"
assert_file_contains "$t9/.gemini/settings.notes.md" 'allowedDirectories' "gemini allowedDirectories 안내"
assert_file_contains "$t9/GEMINI.md" "Gemini Workflow" "gemini workflow 섹션 생성"

suite "Codex notes guide"
t10=$(make_tmpdir)
"$INIT_SH" --skip-ai --tools claude,codex "$t10" >/dev/null 2>&1
assert_file_exists "$t10/.codex/config.notes.md" "codex config notes 생성"
assert_file_contains "$t10/.codex/config.toml" 'model = "gpt-5.1-codex-mini"' "codex 최신 모델 기본값"
assert_file_contains "$t10/.codex/config.notes.md" 'approval_policy' "codex approval 정책 안내"
assert_file_contains "$t10/.codex/config.notes.md" 'workspace-write' "codex sandbox 안내"

print_summary
