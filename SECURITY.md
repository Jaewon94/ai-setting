# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in ai-setting, please report it responsibly.

**Do NOT create a public GitHub issue for security vulnerabilities.**

Instead, please email security concerns to the maintainers directly or use GitHub's private vulnerability reporting feature.

## Scope

ai-setting generates configuration files for AI coding tools. Security-relevant areas include:

- Hook scripts that execute shell commands
- MCP server configurations
- File permission handling
- Symlink operations

## Best Practices

When using ai-setting in your projects:

1. **jq 필수**: 보안 hook(protect-files, block-dangerous-commands)은 jq가 없으면 fail-closed로 동작합니다. `--doctor`에서 jq 미설치는 ERROR로 표시됩니다
2. Review generated hook scripts before enabling them
3. Use `--dry-run` to preview changes before applying
4. Use `--doctor` to verify your setup
5. Keep `settings.local.json` out of version control if it contains sensitive overrides
6. `--doctor`가 settings.local.json에서 과도한 permission을 감지하면 정리를 권장합니다
