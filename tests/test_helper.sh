#!/bin/bash
# tests/test_helper.sh — 간단한 테스트 프레임워크

TEST_PASS=0
TEST_FAIL=0
TEST_TOTAL=0
CURRENT_SUITE=""

# 프로젝트 루트
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INIT_SH="$REPO_ROOT/init.sh"

suite() {
  CURRENT_SUITE="$1"
  echo ""
  echo "━━━ $1 ━━━"
}

assert_file_exists() {
  local path="$1"
  local label="${2:-$path}"
  TEST_TOTAL=$((TEST_TOTAL + 1))
  if [ -e "$path" ]; then
    TEST_PASS=$((TEST_PASS + 1))
    echo "  ✅ $label"
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  ❌ $label — 파일 없음"
  fi
}

assert_file_not_exists() {
  local path="$1"
  local label="${2:-$path 없어야 함}"
  TEST_TOTAL=$((TEST_TOTAL + 1))
  if [ ! -e "$path" ]; then
    TEST_PASS=$((TEST_PASS + 1))
    echo "  ✅ $label"
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  ❌ $label — 파일이 존재함"
  fi
}

assert_file_contains() {
  local path="$1"
  local pattern="$2"
  local label="${3:-$path contains '$pattern'}"
  TEST_TOTAL=$((TEST_TOTAL + 1))
  if [ -f "$path" ] && grep -q -- "$pattern" "$path" 2>/dev/null; then
    TEST_PASS=$((TEST_PASS + 1))
    echo "  ✅ $label"
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  ❌ $label"
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local label="${3:-exit code $expected}"
  TEST_TOTAL=$((TEST_TOTAL + 1))
  if [ "$actual" -eq "$expected" ]; then
    TEST_PASS=$((TEST_PASS + 1))
    echo "  ✅ $label"
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  ❌ $label (got $actual)"
  fi
}

assert_symlink() {
  local path="$1"
  local label="${2:-$path is symlink}"
  TEST_TOTAL=$((TEST_TOTAL + 1))
  if [ -L "$path" ]; then
    TEST_PASS=$((TEST_PASS + 1))
    echo "  ✅ $label"
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  ❌ $label — 심링크 아님"
  fi
}

assert_output_contains() {
  local output="$1"
  local pattern="$2"
  local label="${3:-output contains '$pattern'}"
  TEST_TOTAL=$((TEST_TOTAL + 1))
  if printf '%s\n' "$output" | grep -qF -- "$pattern" 2>/dev/null; then
    TEST_PASS=$((TEST_PASS + 1))
    echo "  ✅ $label"
  else
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  ❌ $label"
  fi
}

make_tmpdir() {
  mktemp -d
}

print_summary() {
  echo ""
  echo "━━━ Test Summary ━━━"
  echo "  PASS: $TEST_PASS"
  echo "  FAIL: $TEST_FAIL"
  echo "  TOTAL: $TEST_TOTAL"
  if [ "$TEST_FAIL" -gt 0 ]; then
    return 1
  fi
  return 0
}
