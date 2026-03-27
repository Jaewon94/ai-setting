[한국어](README.ko.md) | English

# AI Setting

Bootstrap common project settings for Claude Code, Codex, Cursor, Gemini CLI, and GitHub Copilot.

This repo is for teams that want one repeatable way to start or realign project-local AI tooling without rebuilding the same `.claude`, `.codex`, `.cursor`, `.gemini`, and `.github` files every time.

For contributions and extension points, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Quick Start

```bash
# Default: Claude Code only
./bin/ai-setting /path/to/project

# Multiple tools
./bin/ai-setting --tools claude,cursor,codex /path/to/project

# All supported tools
./bin/ai-setting --all /path/to/project

# Add a tool later
./bin/ai-setting add-tool gemini /path/to/project

# Update shared assets for an existing project
./bin/ai-setting update /path/to/project

# Merge ai-setting hooks into an existing Claude settings file
./bin/ai-setting --merge /path/to/project

# Sync multiple projects
./bin/ai-setting sync ./projects.manifest
```

## What It Gives You

- Multi-tool bootstrap for Claude Code, Codex, Cursor, Gemini CLI, and GitHub Copilot
- Claude profiles: `standard`, `minimal`, `strict`, `team`
- Safety and maintenance commands: `doctor`, `dry-run`, `diff`, `backup-all`, `reapply`
- Project-local MCP presets for common setups
- AI-assisted template filling with Claude first, Codex fallback
- Sync flow for keeping multiple projects aligned
- Cross-platform bash-based hooks verified against macOS, Windows, and Linux behavior

## Core Flow

```text
init.sh
  -> copy/symlink shared settings
  -> generate project-local MCP config
  -> generate project docs/templates
  -> auto-fill docs with Claude Code
  -> fall back to Codex if needed
```

## Pick a Profile

| Profile | Use When |
|---------|----------|
| `standard` | Default team or solo usage |
| `minimal` | You want only essential hooks and fewer managed assets |
| `strict` | You want stronger safeguards, including main/master protection |
| `team` | You want strict mode plus PR template and webhook scaffolding |

## MCP Presets

Default is `core`.

| Preset | Includes |
|--------|----------|
| `core` | `sequential-thinking`, `serena`, `upstash-context-7-mcp` |
| `web` | `playwright` |
| `infra` | `docker` |
| `local` | `filesystem`, `fetch` |

Notes:
- `.mcp.json` is kept machine-parseable JSON without comments.
- `.mcp.notes.md` is generated next to it for manual values like API keys or absolute paths.
- `.codex/config.toml` can include inline comments for manual MCP edits.

## Package and Runtime Notes

```bash
npx @jaewon94/ai-setting --help
npx @jaewon94/ai-setting /path/to/project
brew install Jaewon94/ai-setting/ai-setting
ai-setting --help
```

- npm package: `@jaewon94/ai-setting`
- Homebrew tap: `Jaewon94/ai-setting`
- Windows requires `bash` to run the generated hooks and wrapper flow
- Recommended on Windows: Git Bash
- For `cmd.exe` or PowerShell, set:

```bash
npm config set script-shell "C:\Program Files\Git\bin\bash.exe"
```

## Documentation Map

Start here, then go deeper only as needed.

- [docs/usage.md](docs/usage.md): commands, options, update/sync flows, MCP usage, plugin usage
- [docs/reference.md](docs/reference.md): generated files, profiles, hook/agent/skill details, detection logic
- [docs/plans/execution-plan.ko.md](docs/plans/execution-plan.ko.md): current top-level execution order and documentation-first priorities
- [docs/deployment-checklist.md](docs/deployment-checklist.md): npm/release/Homebrew verification
- [docs/distribution/README.md](docs/distribution/README.md): npm/Homebrew distribution operations
- [docs/plugin-guide.md](docs/plugin-guide.md): plugin authoring and packaging
- [docs/roadmap.md](docs/roadmap.md): planned work and phase tracking
- [docs/issues.md](docs/issues.md): issue history and verification notes
- Field tests:
  - [docs/field-test-kobot.md](docs/field-test-kobot.md)
  - [docs/field-test-research-traceability.md](docs/field-test-research-traceability.md)
  - [docs/field-test-ai-autofill.md](docs/field-test-ai-autofill.md)
  - [docs/field-test-python-backend.md](docs/field-test-python-backend.md)

## Typical Next Checks After Init

- Run `./bin/ai-setting --doctor /path/to/project`
- Open generated `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and Copilot instructions
- Confirm the detected archetype and stack match the project
- If the project already had `.claude/settings.json`, prefer `--merge` before overwriting it
- If AI autofill was skipped, fill bracketed sections manually or rerun later with more project signals

## Verification Loop

Use a range-based verification loop during development, then run the full suite once at the end.

```bash
# Hooks / security policy changes
./tests/test_hooks.sh

# Profile / install-path / metadata changes
./tests/test_profiles.sh

# init / doctor / template / locale changes
./tests/test_basic.sh

# Final gate only
./tests/run_all.sh
```

- On Windows + Git Bash, `./tests/run_all.sh` can take significantly longer than the focused suites.
- For downstream projects that install and use `ai-setting`, prefer the same pattern: quick scoped checks first, final full verification once.

## Generated Assets at a Glance

- `.claude/` for Claude Code settings, hooks, agents, skills
- `.codex/config.toml` for Codex CLI config and MCP
- `.cursor/rules/*.mdc` for Cursor rules
- `.gemini/settings.json` and `GEMINI.md` for Gemini CLI
- `.github/copilot-instructions.md` and path-specific instructions for Copilot
- `CLAUDE.md`, `AGENTS.md`, `BEHAVIORAL_CORE.md`
- `docs/decisions.md`, `docs/research-notes.md`
- `.mcp.json`, `.mcp.notes.md`
