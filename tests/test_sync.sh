#!/bin/bash
# tests/test_sync.sh — sync, link, conflict, settings.local.json 검증
source "$(dirname "$0")/test_helper.sh"

suite "link 모드"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai --link "$t" >/dev/null 2>&1
assert_symlink "$t/.claude/settings.json" "settings.json 심링크"
assert_symlink "$t/.claude/hooks/protect-files.sh" "hook 심링크"

suite "link-dir 모드"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai --link-dir "$t" >/dev/null 2>&1
assert_symlink "$t/.claude/hooks" "hooks 디렉토리 심링크"

suite "update 모드"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
"$INIT_SH" update "$t" >/dev/null 2>&1
ec=$?
assert_exit_code 0 "$ec" "update 정상 종료"

suite "settings.local.json merge"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
echo '{"customKey":"testValue"}' > "$t/.claude/settings.local.json"
"$INIT_SH" update "$t" >/dev/null 2>&1
assert_file_contains "$t/.claude/settings.json" "testValue" "merge 결과 반영"

suite "--merge keeps existing settings"
t=$(make_tmpdir)
mkdir -p "$t/.claude"
cat > "$t/.claude/settings.json" <<'EOF'
{
  "customKey": "keep-me",
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo custom-notify"
          }
        ]
      }
    ]
  }
}
EOF
"$INIT_SH" --skip-ai --merge "$t" >/dev/null 2>&1
assert_file_contains "$t/.claude/settings.json" "keep-me" "기존 custom key 유지"
assert_file_contains "$t/.claude/settings.json" "custom-notify" "기존 notification 유지"
assert_file_contains "$t/.claude/settings.json" "protect-files.sh" "ai-setting hook merge됨"

suite "format-on-write monorepo frontend"
t=$(make_tmpdir)
mkdir -p "$t/frontend/src" "$t/bin"
echo '{}' > "$t/frontend/package.json"
cat > "$t/bin/npx" <<EOF
#!/bin/bash
echo "\$(pwd)|\$*" >> "$t/format.log"
EOF
chmod +x "$t/bin/npx"
printf '%s' '{"tool_input":{"file_path":"frontend/src/app.ts"}}' | \
  env PATH="$t/bin:$PATH" CLAUDE_PROJECT_DIR="$t" \
  "$REPO_ROOT/claude/hooks/format-on-write.sh" >/dev/null 2>&1
assert_file_contains "$t/format.log" "$t/frontend|prettier --write src/app.ts" "frontend 하위 package.json 기준 prettier 실행"

suite "format-on-write backend requirements"
t=$(make_tmpdir)
mkdir -p "$t/backend/app" "$t/bin"
echo 'fastapi==0.1.0' > "$t/backend/requirements.txt"
cat > "$t/bin/ruff" <<EOF
#!/bin/bash
echo "\$(pwd)|\$*" >> "$t/format.log"
EOF
chmod +x "$t/bin/ruff"
printf '%s' '{"tool_input":{"file_path":"backend/app/main.py"}}' | \
  env PATH="$t/bin:$PATH" CLAUDE_PROJECT_DIR="$t" \
  "$REPO_ROOT/claude/hooks/format-on-write.sh" >/dev/null 2>&1
assert_file_contains "$t/format.log" "$t/backend|format app/main.py" "backend requirements.txt 기준 ruff format 실행"
assert_file_contains "$t/format.log" "$t/backend|check --fix app/main.py" "backend requirements.txt 기준 ruff check 실행"

suite "sync manifest"
p1=$(make_tmpdir) && p2=$(make_tmpdir)
manifest=$(mktemp)
echo "$p1" > "$manifest"
echo "$p2" >> "$manifest"
"$INIT_SH" sync --skip-ai "$manifest" >/dev/null 2>&1
assert_file_exists "$p1/.claude/settings.json" "proj1 설치됨"
assert_file_exists "$p2/.claude/settings.json" "proj2 설치됨"

suite "sync manifest per-project options"
p3=$(make_tmpdir)
manifest2=$(mktemp)
echo "$p3 profile=strict" > "$manifest2"
"$INIT_SH" sync --skip-ai --all "$manifest2" >/dev/null 2>&1
assert_file_exists "$p3/.claude/hooks/protect-main-branch.sh" "strict 적용됨"

suite "sync conflict skip"
p4=$(make_tmpdir)
"$INIT_SH" --skip-ai "$p4" >/dev/null 2>&1
echo "modified" >> "$p4/.claude/hooks/protect-files.sh"
manifest3=$(mktemp)
echo "$p4" > "$manifest3"
output=$("$INIT_SH" sync --skip-ai --sync-conflict skip "$manifest3" 2>&1)
assert_output_contains "$output" "충돌 감지" "충돌 감지됨"
assert_output_contains "$output" "건너뜁니다" "skip 적용됨"

suite "plugin lifecycle"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai "$t" >/dev/null 2>&1
"$INIT_SH" plugin install ai-setting-strict "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/hooks/protect-main-branch.sh" "plugin install 됨"
assert_file_exists "$t/.ai-setting/installed-plugins.json" "설치 기록"
"$INIT_SH" plugin uninstall ai-setting-strict "$t" >/dev/null 2>&1
assert_file_not_exists "$t/.claude/hooks/protect-main-branch.sh" "plugin uninstall 됨"

print_summary
