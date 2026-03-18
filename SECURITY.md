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

1. Review generated hook scripts before enabling them
2. Use `--dry-run` to preview changes before applying
3. Use `--doctor` to verify your setup
4. Keep `settings.local.json` out of version control if it contains sensitive overrides
