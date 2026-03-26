#!/bin/bash
# tests/test_profiles.sh — 프로필별 파일 생성 검증
source "$(dirname "$0")/test_helper.sh"

suite "standard profile"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai --all --profile standard "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/hooks/protect-files.sh" "protect-files.sh"
assert_file_exists "$t/.claude/hooks/block-dangerous-commands.sh" "block-dangerous-commands.sh"
assert_file_exists "$t/.claude/hooks/async-test.sh" "async-test.sh"
assert_file_exists "$t/.claude/agents/security-reviewer.md" "agents 존재"
assert_file_exists "$t/.claude/skills/deploy/SKILL.md" "skills 존재"
assert_file_not_exists "$t/.claude/hooks/protect-main-branch.sh" "branch 보호 없음"

suite "minimal profile"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai --all --profile minimal "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/hooks/protect-files.sh" "protect-files.sh"
assert_file_not_exists "$t/.claude/hooks/block-dangerous-commands.sh" "block-commands 없음"
assert_file_not_exists "$t/.claude/agents/security-reviewer.md" "agents 없음"
assert_file_not_exists "$t/.claude/skills/deploy/SKILL.md" "skills 없음"
assert_file_contains "$t/.codex/config.toml" 'model_reasoning_effort = "low"' "minimal codex low reasoning"

suite "strict profile"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai --all --profile strict "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/hooks/protect-main-branch.sh" "branch 보호 있음"
assert_file_exists "$t/.claude/hooks/block-dangerous-commands.sh" "block-commands 있음"
assert_file_contains "$t/.codex/config.toml" 'approval_policy = { granular =' "codex granular 정책"
assert_file_contains "$t/.codex/config.toml" 'skill_approval = true' "codex skill approval 노출"

suite "team profile"
t=$(make_tmpdir)
"$INIT_SH" --skip-ai --all --profile team "$t" >/dev/null 2>&1
assert_file_exists "$t/.claude/hooks/protect-main-branch.sh" "branch 보호"
assert_file_exists "$t/.claude/hooks/team-webhook-notify.sh" "webhook hook"
assert_file_exists "$t/.github/pull_request_template.md" "PR 템플릿"
assert_file_exists "$t/.ai-setting/team-webhook.json" "webhook 설정"
assert_file_contains "$t/.codex/config.toml" 'approval_policy = { granular =' "codex granular 정책"
assert_file_contains "$t/.codex/config.toml" 'request_permissions = true' "codex request permissions 노출"

print_summary
