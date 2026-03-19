#!/bin/bash
# tests/run_all.sh — 전체 테스트 실행
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ai-setting test suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

run_suite() {
  local script="$1"
  local name
  name="$(basename "$script" .sh)"

  echo ""
  echo "▶ $name"
  output=$(bash "$script" 2>&1)
  echo "$output"

  local pass fail
  pass=$(echo "$output" | grep "PASS:" | awk '{print $2}')
  fail=$(echo "$output" | grep "FAIL:" | awk '{print $2}')

  TOTAL_PASS=$((TOTAL_PASS + ${pass:-0}))
  TOTAL_FAIL=$((TOTAL_FAIL + ${fail:-0}))

  if [ "${fail:-0}" -gt 0 ]; then
    FAILED_SUITES+=("$name")
  fi
}

# 구문 검사
echo ""
echo "▶ syntax check"
if bash -n "$SCRIPT_DIR/../init.sh" "$SCRIPT_DIR"/../lib/*.sh; then
  echo "  ✅ 전체 구문 검사 통과"
  TOTAL_PASS=$((TOTAL_PASS + 1))
else
  echo "  ❌ 구문 오류 발견"
  TOTAL_FAIL=$((TOTAL_FAIL + 1))
  FAILED_SUITES+=("syntax")
fi

run_suite "$SCRIPT_DIR/test_basic.sh"
run_suite "$SCRIPT_DIR/test_profiles.sh"
run_suite "$SCRIPT_DIR/test_tools.sh"
run_suite "$SCRIPT_DIR/test_detect.sh"
run_suite "$SCRIPT_DIR/test_sync.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Final Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PASS: $TOTAL_PASS"
echo "  FAIL: $TOTAL_FAIL"
echo "  TOTAL: $((TOTAL_PASS + TOTAL_FAIL))"

if [ "${#FAILED_SUITES[@]}" -gt 0 ]; then
  echo ""
  echo "  Failed: ${FAILED_SUITES[*]}"
  exit 1
fi

echo ""
echo "  All tests passed!"
exit 0
