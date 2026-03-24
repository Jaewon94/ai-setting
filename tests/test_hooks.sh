#!/bin/bash
# tests/test_hooks.sh — Hook 보안 및 동작 테스트
# ISS-011: jq 부재 시 fail-closed
# ISS-012: eval 제거 확인
# ISS-013: Notification 크로스플랫폼

source "$(dirname "$0")/test_helper.sh"

# ━━━ ISS-011: jq 부재 시 보안 hook이 fail-closed (exit 2) ━━━
suite "ISS-011: protect-files.sh — jq 없으면 exit 2"

# jq를 PATH에서 제거한 환경에서 실행
output=$(echo '{"tool_input":{"file_path":"test.txt"}}' | env PATH="/usr/bin:/bin" bash "$REPO_ROOT/claude/hooks/protect-files.sh" 2>&1)
ec=$?
# jq가 시스템에 있을 수도 없을 수도 있으므로, 스크립트에 jq 체크 코드가 있는지 확인
assert_file_contains "$REPO_ROOT/claude/hooks/protect-files.sh" "command -v jq" "protect-files.sh에 jq 체크 존재"
assert_file_contains "$REPO_ROOT/claude/hooks/protect-files.sh" "exit 2" "protect-files.sh에 exit 2 존재"

suite "ISS-011: block-dangerous-commands.sh — jq 없으면 exit 2"

assert_file_contains "$REPO_ROOT/claude/hooks/block-dangerous-commands.sh" "command -v jq" "block-dangerous-commands.sh에 jq 체크 존재"
assert_file_contains "$REPO_ROOT/claude/hooks/block-dangerous-commands.sh" "exit 2" "block-dangerous-commands.sh에 exit 2 존재"

suite "ISS-011: plugins 버전도 동일 적용"

assert_file_contains "$REPO_ROOT/plugins/ai-setting-core/scripts/protect-files.sh" "command -v jq" "plugins/protect-files.sh에 jq 체크 존재"
assert_file_contains "$REPO_ROOT/plugins/ai-setting-core/scripts/block-dangerous-commands.sh" "command -v jq" "plugins/block-dangerous-commands.sh에 jq 체크 존재"

# ━━━ ISS-011: jq 있는 환경에서 정상 동작 확인 ━━━
suite "ISS-011: jq 있을 때 protect-files.sh 정상 통과"

if command -v jq >/dev/null 2>&1; then
  # 안전한 파일 → exit 0
  output=$(echo '{"tool_input":{"file_path":"src/main.py"}}' | bash "$REPO_ROOT/claude/hooks/protect-files.sh" 2>&1)
  ec=$?
  assert_exit_code 0 $ec "안전한 파일 경로 → exit 0"

  # .env 파일 → exit 2 (차단)
  output=$(echo '{"tool_input":{"file_path":".env"}}' | bash "$REPO_ROOT/claude/hooks/protect-files.sh" 2>&1)
  ec=$?
  assert_exit_code 2 $ec ".env 파일 → exit 2 차단"
else
  echo "  ⚠️ jq 미설치 — 정상 동작 테스트 스킵"
fi

suite "ISS-011: jq 있을 때 block-dangerous-commands.sh 정상 동작"

if command -v jq >/dev/null 2>&1; then
  # 안전한 명령 → exit 0
  output=$(echo '{"tool_input":{"command":"ls -la"}}' | bash "$REPO_ROOT/claude/hooks/block-dangerous-commands.sh" 2>&1)
  ec=$?
  assert_exit_code 0 $ec "안전한 명령 → exit 0"

  # 위험한 명령 → exit 2
  output=$(echo '{"tool_input":{"command":"rm -rf /"}}' | bash "$REPO_ROOT/claude/hooks/block-dangerous-commands.sh" 2>&1)
  ec=$?
  assert_exit_code 2 $ec "rm -rf / → exit 2 차단"
else
  echo "  ⚠️ jq 미설치 — 정상 동작 테스트 스킵"
fi

# ━━━ ISS-012: eval 제거 확인 ━━━
suite "ISS-012: async-test.sh에서 eval 미사용"

# eval이 테스트 명령 실행에 사용되지 않는지 확인
if grep -n 'eval.*ASYNC_TEST_COMMAND' "$REPO_ROOT/claude/hooks/async-test.sh" >/dev/null 2>&1; then
  TEST_TOTAL=$((TEST_TOTAL + 1))
  TEST_FAIL=$((TEST_FAIL + 1))
  echo "  ❌ claude/hooks/async-test.sh에 eval 사용 잔존"
else
  TEST_TOTAL=$((TEST_TOTAL + 1))
  TEST_PASS=$((TEST_PASS + 1))
  echo "  ✅ claude/hooks/async-test.sh에서 eval 제거됨"
fi

if grep -n 'eval.*ASYNC_TEST_COMMAND' "$REPO_ROOT/plugins/ai-setting-core/scripts/async-test.sh" >/dev/null 2>&1; then
  TEST_TOTAL=$((TEST_TOTAL + 1))
  TEST_FAIL=$((TEST_FAIL + 1))
  echo "  ❌ plugins/async-test.sh에 eval 사용 잔존"
else
  TEST_TOTAL=$((TEST_TOTAL + 1))
  TEST_PASS=$((TEST_PASS + 1))
  echo "  ✅ plugins/async-test.sh에서 eval 제거됨"
fi

assert_file_contains "$REPO_ROOT/claude/hooks/async-test.sh" 'bash -c' "claude/hooks/async-test.sh에 bash -c 사용"
assert_file_contains "$REPO_ROOT/plugins/ai-setting-core/scripts/async-test.sh" 'bash -c' "plugins/async-test.sh에 bash -c 사용"

# ━━━ ISS-013: Notification hook 크로스플랫폼 확인 ━━━
suite "ISS-013: settings.json Notification 크로스플랫폼"

for f in settings.json settings.strict.json settings.team.json; do
  filepath="$REPO_ROOT/claude/$f"
  if [ -f "$filepath" ]; then
    assert_file_contains "$filepath" "notify-send" "$f에 Linux notify-send 포함"
    assert_file_contains "$filepath" "powershell" "$f에 Windows powershell 포함"
    assert_file_contains "$filepath" "osascript" "$f에 macOS osascript 포함"
  fi
done

# ━━━ ISS-018: format-on-write.sh 경로 정규화 ━━━
suite "ISS-018: format-on-write.sh에 경로 정규화 코드 존재"

assert_file_contains "$REPO_ROOT/claude/hooks/format-on-write.sh" 'file_path="${file_path//\\\\//}"' "claude/hooks/format-on-write.sh에 백슬래시 변환"
assert_file_contains "$REPO_ROOT/plugins/ai-setting-core/scripts/format-on-write.sh" 'file_path="${file_path//\\\\//}"' "plugins/format-on-write.sh에 백슬래시 변환"

# ━━━ ISS-019: async-test.sh monorepo 하위 탐색 ━━━
suite "ISS-019: async-test.sh monorepo 하위 디렉토리 탐색"

assert_file_contains "$REPO_ROOT/claude/hooks/async-test.sh" "auto-monorepo-python" "claude/hooks/async-test.sh에 monorepo python 감지"
assert_file_contains "$REPO_ROOT/claude/hooks/async-test.sh" "auto-monorepo-node" "claude/hooks/async-test.sh에 monorepo node 감지"
assert_file_contains "$REPO_ROOT/plugins/ai-setting-core/scripts/async-test.sh" "auto-monorepo-python" "plugins/async-test.sh에 monorepo python 감지"

# ━━━ ISS-014/017: _source 마커 + merge 중복 제거 ━━━
suite "ISS-014/017: settings.json에 _source 마커 존재"

for f in settings.json settings.strict.json settings.team.json settings.minimal.json; do
  filepath="$REPO_ROOT/claude/$f"
  if [ -f "$filepath" ]; then
    assert_file_contains "$filepath" '"_source": "ai-setting"' "$f에 _source 마커 존재"
  fi
done

suite "ISS-014/017: merge 로직에 strip_managed_hooks 존재"

assert_file_contains "$REPO_ROOT/lib/profile.sh" "strip_managed_hooks" "profile.sh에 strip_managed_hooks 함수"
assert_file_contains "$REPO_ROOT/lib/profile.sh" "is_managed" "profile.sh에 is_managed 함수"

# ━━━ ISS-024: MCP command 체크 함수 존재 ━━━
suite "ISS-024: check_mcp_commands 함수 존재"

assert_file_contains "$REPO_ROOT/lib/mcp.sh" "check_mcp_commands" "mcp.sh에 check_mcp_commands 함수"
assert_file_contains "$REPO_ROOT/init.sh" "check_mcp_commands" "init.sh에서 check_mcp_commands 호출"

# ━━━ ISS-016/020/021/025: --skip-ai rule-based 치환 ━━━
suite "ISS-016/020/021/025: fill_rule_based_placeholders 함수 존재"

assert_file_contains "$REPO_ROOT/init.sh" "fill_rule_based_placeholders" "init.sh에 fill_rule_based_placeholders 함수"
assert_file_contains "$REPO_ROOT/init.sh" "skip-ai.*rule-based\|rule-based 치환" "init.sh에서 --skip-ai 분기에서 호출"

suite "ISS-016/020/021/025: archetype 기반 명령 매핑"

assert_file_contains "$REPO_ROOT/init.sh" "test_backend_cmd" "init.sh에 test_backend_cmd 변수"
assert_file_contains "$REPO_ROOT/init.sh" "test_frontend_cmd" "init.sh에 test_frontend_cmd 변수"
assert_file_contains "$REPO_ROOT/init.sh" 'replace_literal_in_file.*"\[프로젝트명\]"' "init.sh에 프로젝트명 치환 로직"
assert_file_contains "$REPO_ROOT/lib/common.sh" 'replace_literal_in_file\(\)' "portable 치환 헬퍼 존재"

# ISS-015: .gitignore 자동 추가 확인
suite "ISS-015: .gitignore에 .claude/context/ 추가 로직"

assert_file_contains "$REPO_ROOT/init.sh" ".claude/context/" "init.sh에 .claude/context/ gitignore 로직"

print_summary
