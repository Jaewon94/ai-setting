# Usage Guide

## Main Commands

```bash
./bin/ai-setting [options] /path/to/project
./bin/ai-setting update [options] /path/to/project
./bin/ai-setting sync [options] ./projects.manifest
./bin/ai-setting add-tool <tool> /path/to/project
./bin/ai-setting plugin {list|install|uninstall|check-update|upgrade} [name] [target]
```

## Common Examples

```bash
# Claude Code only
./bin/ai-setting /path/to/project

# Specific tool set
./bin/ai-setting --tools claude,cursor /path/to/project

# All supported tools
./bin/ai-setting --all /path/to/project

# Minimal Claude profile
./bin/ai-setting --profile minimal /path/to/project

# Strict safeguards
./bin/ai-setting --profile strict /path/to/project

# Skip AI autofill
./bin/ai-setting --skip-ai /path/to/project

# Enable recommended MCP automatically
./bin/ai-setting --auto-mcp /path/to/project

# Add a tool later
./bin/ai-setting add-tool codex /path/to/project
```

## Profiles

| Profile | Includes |
|---------|----------|
| `standard` | Default hooks, agents, skills |
| `minimal` | Essential hooks only, fewer managed assets |
| `strict` | `standard` + main/master protection |
| `team` | `strict` + PR template + webhook scaffold |

When switching profiles:
- Existing `.claude/` is backed up first
- ai-setting managed assets are re-aligned to the chosen profile
- User-created files outside the managed set are kept

## MCP Usage

### Presets

| Preset | Servers |
|--------|---------|
| `core` | `sequential-thinking`, `serena`, `upstash-context-7-mcp` |
| `web` | `playwright` |
| `infra` | `docker` |
| `git` | `mcp-server-git` |
| `chrome` | `chrome-devtools-mcp` |
| `next` | `next-devtools-mcp` |
| `local` | `filesystem`, `fetch` |

### Examples

```bash
# Add web automation
./bin/ai-setting --mcp-preset web /path/to/project

# Add infrastructure helpers
./bin/ai-setting --mcp-preset infra /path/to/project

# Add repository inspection helpers explicitly
./bin/ai-setting --mcp-preset git /path/to/project

# Add browser debugging helpers
./bin/ai-setting --mcp-preset web,chrome /path/to/project

# Add Next.js diagnostics explicitly
./bin/ai-setting --mcp-preset web,next /path/to/project

# Combine presets
./bin/ai-setting --mcp-preset web,infra /path/to/project

# Let ai-setting choose based on detected archetype/stack
./bin/ai-setting --auto-mcp /path/to/project

# Skip project-local MCP generation
./bin/ai-setting --no-mcp /path/to/project
```

### Manual MCP Values

- `.mcp.json` contains the runnable JSON config
- `.mcp.notes.md` explains manual values such as API keys or absolute paths
- `.codex/config.toml` may include inline comments for manual MCP editing
- `git` is opt-in, requires `uvx`, and defaults to the project-root repository path
- `chrome` is opt-in and requires Chrome or Chrome for Testing plus Node.js 20.19+
- `next` is recommended automatically when a Next.js stack is detected
- `.ai-setting/protect-files.json` overrides file-protection rules per project
- `.ai-setting/protect-files.notes.md` explains how to write those overrides
- built-in hard-block entries cannot be downgraded to `allow` by project override

## Update Mode

```bash
./bin/ai-setting update /path/to/project
```

Behavior:
- Updates shared settings and MCP config
- Keeps project-specific docs like `CLAUDE.md` and `AGENTS.md` as-is
- Does not run AI autofill

## Sync Mode

```bash
./bin/ai-setting sync ./projects.manifest
./bin/ai-setting sync --sync-mode init ./projects.manifest
./bin/ai-setting sync --sync-conflict skip ./projects.manifest
```

Manifest example:

```text
# projects.manifest
../storyforge
../taskrelay profile=strict mcp-preset=core,web
../internal-tool profile=minimal archetype=cli-tool
```

Supported per-project options:
- `profile=`
- `mcp-preset=`
- `archetype=`
- `stack=`

Conflict handling:
- `backup` (default): back up and overwrite
- `skip`: skip the project
- `overwrite`: overwrite directly

## Link Modes

```bash
./bin/ai-setting --link /path/to/project
./bin/ai-setting --link-dir /path/to/project
```

- `--link`: symlink selected shared assets file-by-file
- `--link-dir`: symlink `.claude/hooks`, `.claude/agents`, `.claude/skills` as directories

Still kept as local files:
- `CLAUDE.md`
- `AGENTS.md`
- `GEMINI.md`
- `.github/copilot-instructions.md`
- `.github/pull_request_template.md`
- `.codex/config.toml`
- `.mcp.json`
- `.mcp.notes.md`
- `docs/decisions.md`
- `docs/research-notes.md`

## Merge Mode

```bash
./bin/ai-setting --merge /path/to/project
```

- Preserves existing user settings in `.claude/settings.json` while merging in ai-setting managed hooks.
- Replaces hooks already managed by ai-setting using the `_source` marker and avoids duplicate registration for the same matcher.
- Prefers keeping existing custom keys and notification settings intact.

## Project Interpretation Hints

```bash
./bin/ai-setting \
  --project-name my-api \
  --archetype backend-api \
  --stack Python \
  /path/to/project
```

Supported archetypes:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app`

## Maintenance Commands

## Recommended Verification Flow

Use the smallest relevant suite first.

```bash
# Hooks, override policy, metadata assertions
./tests/test_hooks.sh

# Profile-specific generated assets
./tests/test_profiles.sh

# init, doctor, locale, template output
./tests/test_basic.sh
```

Run the full suite only once as the final gate:

```bash
./tests/run_all.sh
```

Notes:
- This repo's bash-heavy integration tests can be slow on Windows + Git Bash.
- Downstream projects using installed `ai-setting` should follow the same pattern: fast scoped verification first, full verification last.

### Doctor

```bash
./bin/ai-setting --doctor /path/to/project
```

Checks:
- required binaries
- hook readiness
- MCP JSON validity
- remaining placeholders
- copy vs symlink mode
- async test command presence

### Dry Run

```bash
./bin/ai-setting --dry-run /path/to/project
```

Shows planned changes without writing files.

### Diff

```bash
./bin/ai-setting --diff /path/to/project
```

Shows diffs for managed files without applying them.

### Backup All

```bash
./bin/ai-setting --backup-all /path/to/project
```

Creates a snapshot backup of managed files before applying changes.

### Reapply

```bash
./bin/ai-setting --reapply /path/to/project
```

Regenerates project docs from fresh templates and reruns AI autofill.

Recommended pair:

```bash
./bin/ai-setting --backup-all --reapply /path/to/project
```

## Plugin Commands

Examples:

```bash
./bin/ai-setting plugin list
./bin/ai-setting plugin install ai-setting-strict /path/to/project
./bin/ai-setting plugin check-update /path/to/project
./bin/ai-setting plugin uninstall ai-setting-strict /path/to/project
./bin/ai-setting plugin upgrade ai-setting-strict /path/to/project
```

## Platform Notes

- macOS, Windows, and Linux are all first-class targets
- Generated hooks are bash-based
- Windows users should prefer Git Bash
- For `cmd.exe` or PowerShell use:

```bash
npm config set script-shell "C:\Program Files\Git\bin\bash.exe"
```
