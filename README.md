[한국어](README.ko.md) | English

# AI Setting - Common AI Tool Configuration for New Projects

> Apply Claude Code, Codex, Cursor, Gemini CLI, and GitHub Copilot settings to a new project in one go.
> Extracted from StoryForge, TaskRelay + community best practices.

For contributions and extensions, please refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## Quick Start

```bash
# Default: apply only Claude Code settings (cleanest)
./bin/ai-setting /path/to/my-new-project

# Use Claude Code + Cursor together
./bin/ai-setting --tools claude,cursor /path/to/my-new-project

# Install all 5 tools
./bin/ai-setting --all /path/to/my-new-project

# Add tools later (to an existing project)
./bin/ai-setting add-tool cursor /path/to/my-project
./bin/ai-setting add-tool gemini /path/to/my-project
./bin/ai-setting add-tool codex /path/to/my-project
./bin/ai-setting add-tool copilot /path/to/my-project

# Start lightweight with Claude minimal profile
./bin/ai-setting --profile minimal /path/to/my-new-project

# Strengthen safeguards with strict profile
./bin/ai-setting --profile strict /path/to/my-new-project

# Include MCP for web projects
./bin/ai-setting --mcp-preset web /path/to/my-new-project

# Quickly update only shared assets/MCP for an existing project
./bin/ai-setting update /path/to/my-new-project

# Sync multiple projects at once using a manifest
./bin/ai-setting sync ./projects.manifest
```

Output:
```
[1/7] Copying Claude Code settings (.claude/)
  ⚠ .claude/ already exists — backing up before overwrite
  📦 Backup: /path/to/project/.claude.backup.20260317120000
  ✅ standard profile applied (1 settings, 5 hooks, 4 agents, 5 skills)
[2/7] Copying Cursor / Gemini / Copilot settings
  ✅ Cursor rule applied (.cursor/rules/ai-setting.mdc)
  ✅ Gemini settings applied (.gemini/settings.json)
[3/7] Copying Codex CLI settings (.codex/)
  ⚠ .codex/config.toml already exists — backing up before overwrite
  📦 Backup: /path/to/project/.codex/config.toml.backup.20260317120000
  ✅ config.toml
[4/7] Generating project-local MCP preset
  ⚠ .mcp.json already exists — backing up before overwrite
  📦 Backup: /path/to/project/.mcp.json.backup.20260317120000
  ✅ Codex MCP preset applied (core)
  ✅ Claude MCP config generated (.mcp.json)
[5/7] Copying templates
  ✅ BEHAVIORAL_CORE.md generated
  ✅ CLAUDE.md generated
  ✅ AGENTS.md generated
  ✅ docs/research-notes.md generated
  ✅ GEMINI.md generated
  ✅ .github/copilot-instructions.md generated
[6/7] Auto-generating project docs with AI
  mode: hybrid (both docs and implementation signals present — best interpreted together)
  archetype: frontend-web (web frontend signals detected)
  stack: Next.js (TypeScript/JavaScript) [next.config.ts]
  signals: docs=[README.md,docs] | impl=[package.json,src] | tests=[tests] | ops=[Dockerfile,.env.example]
  🔄 Analyzing project with Claude Code...
  ✅ Claude Code auto-generated project docs
[7/7] Done!
```

### How It Works

```
init.sh runs
  │
  ├─ Steps 1–5: Common settings + multi-tool files + project-local MCP + template copy (instant)
  │
  └─ Step 6: AI analyzes the project and auto-fills project docs
       │
       ├─ If Claude Code is available → attempts processing within 20s by default
       ├─ On timeout/failure → falls back to Codex
       └─ If neither is available → prints manual guidance message
```

### Key Features Implemented So Far

- Multi-tool support: Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot
- Profile system: `standard`, `minimal`, `strict`, `team`
- Safety tools: `doctor`, `dry-run`, `diff`, `backup-all`, `reapply`
- Synchronization: `--link`, `--link-dir`, `update`, `sync`, `--sync-conflict`, `settings.local.json`, `--merge`
- Monorepo-aware formatter hook: runs based on nearest `package.json` / `pyproject.toml` / `requirements*.txt`
- Auto-generated Copilot path-specific instructions
- `BEHAVIORAL_CORE.md` shared behavioral core
- Source tracing via `docs/research-notes.md` + `docs/decisions.md`
- Stabilized AI autofill: latest Codex CLI invocation, Codex fallback after Claude timeout
- Verification status: all PASS in `./tests/run_all.sh` (including 38 test_hooks.sh cases)

Field test documents:
- `docs/field-test-kobot.md`
- `docs/field-test-research-traceability.md`
- `docs/field-test-ai-autofill.md`
- `docs/field-test-python-backend.md`

### Local CLI Wrapper

`bin/ai-setting` is a thin wrapper around `init.sh` at the repo root. This allows consistent invocation as `./bin/ai-setting ...` within the repo, and preserves the same command name when extending to distribution channels like npm/brew later.

[package.json](package.json) is published to npm.
- v1.0.1, MIT License
- npm package name: `@jaewon94/ai-setting`
- `bin.ai-setting` CLI entry
- `npm run pack:check` for package metadata dry-run validation
- `npm run plugin:validate` for Claude Code plugin / marketplace validation
- Auto npm publish + GitHub Release via GitHub Actions on `v*` tag push
- Pre-deployment checklist: `docs/deployment-checklist.md`

Usage after npm install:

```bash
npx @jaewon94/ai-setting --help
npx @jaewon94/ai-setting /path/to/my-new-project
```

> **Windows note**: bash is required (hooks are bash scripts).
> - **Run in Git Bash terminal** (recommended)
> - To use from cmd.exe/PowerShell: `npm config set script-shell "C:\Program Files\Git\bin\bash.exe"`

### Deployment Automation

- `main` push: CI only
- `v*` tag push: npm publish check/skip + GitHub Release creation
- `v*` tag push or manual trigger: Homebrew tap formula auto-update

To use Homebrew automation, the following GitHub repo settings are required:

- repository variable `HOMEBREW_TAP_REPO`
  e.g.: `Jaewon94/homebrew-ai-setting`
- repository secret `HOMEBREW_TAP_GH_TOKEN`
  description: GitHub token with push access to the tap repo

Formula generation is managed by [render-homebrew-formula.sh](scripts/render-homebrew-formula.sh).

### Claude Code Plugin Marketplace

This repo provides Claude Code plugins in addition to the `init.sh`-based bootstrap.

Included plugins:

| Plugin | Description |
|--------|-------------|
| `ai-setting-core` | Core hooks, agents, skills, keyless MCP defaults |
| `ai-setting-strict` | main/master branch protection hook (for strict/team) |
| `ai-setting-team` | Slack/Discord webhook notification hook (for team) |

Plugin CLI:

```bash
# List available plugins
./bin/ai-setting plugin list

# Install a plugin (copies hook/agent/skill to target project + merges settings.json)
./bin/ai-setting plugin install ai-setting-strict /path/to/project

# Check for plugin updates
./bin/ai-setting plugin check-update /path/to/project

# Uninstall a plugin
./bin/ai-setting plugin uninstall ai-setting-strict /path/to/project

# Upgrade a plugin (uninstall + reinstall)
./bin/ai-setting plugin upgrade ai-setting-strict /path/to/project
```

Claude Code native marketplace:

```bash
# Validate marketplace / plugin schema
npm run plugin:validate

# Add local marketplace to Claude Code
claude plugin marketplace add ./

# Install core plugin at project scope
claude plugin install ai-setting-core@jaewon-ai-setting --scope project
```

### Options

```bash
# Default: install Claude Code only (includes core MCP)
/path/to/ai-setting/init.sh /path/to/my-new-project

# Install a specific tool combination
/path/to/ai-setting/init.sh --tools claude,cursor /path/to/my-new-project

# Install all 5 tools
/path/to/ai-setting/init.sh --all /path/to/my-new-project

# Add a tool to an existing project
/path/to/ai-setting/init.sh add-tool cursor /path/to/my-new-project

# Apply Claude minimal profile
/path/to/ai-setting/init.sh --profile minimal /path/to/my-new-project

# Apply strict or team profile
/path/to/ai-setting/init.sh --profile strict /path/to/my-new-project
/path/to/ai-setting/init.sh --profile team /path/to/my-new-project

# Symlink shared configuration assets
/path/to/ai-setting/init.sh --link /path/to/my-new-project

# Preserve existing .claude/settings.json and only merge ai-setting hooks
/path/to/ai-setting/init.sh --merge /path/to/my-project

# Symlink entire hooks/agents/skills directories
/path/to/ai-setting/init.sh --link-dir /path/to/my-new-project

# Update only shared assets / MCP without AI autofill
/path/to/ai-setting/init.sh update /path/to/my-new-project

# Sync multiple projects in update mode via manifest
/path/to/ai-setting/init.sh sync ./projects.manifest

# Sync multiple projects using init flow
/path/to/ai-setting/init.sh sync --sync-mode init ./projects.manifest

# Protect local modifications during sync (conflict detection → skip)
/path/to/ai-setting/init.sh sync --sync-conflict skip ./projects.manifest

# Web project: core + web
/path/to/ai-setting/init.sh --mcp-preset web /path/to/my-new-project

# Docker project: core + infra
/path/to/ai-setting/init.sh --mcp-preset infra /path/to/my-new-project

# Web + Docker project: core + web + infra
/path/to/ai-setting/init.sh --mcp-preset web,infra /path/to/my-new-project

# Skip AI autofill (copy + rule-based substitution only)
/path/to/ai-setting/init.sh --skip-ai /path/to/my-new-project

# Skip project-local MCP generation
/path/to/ai-setting/init.sh --no-mcp /path/to/my-new-project

# Preview planned actions without making changes
/path/to/ai-setting/init.sh --dry-run /path/to/my-new-project

# Preview managed file diffs without making changes
/path/to/ai-setting/init.sh --diff /path/to/my-new-project

# Snapshot backup all managed files before applying
/path/to/ai-setting/init.sh --backup-all /path/to/my-new-project

# Regenerate CLAUDE.md / AGENTS.md from fresh templates
/path/to/ai-setting/init.sh --reapply /path/to/my-new-project

# Auto-apply recommended MCP preset based on detected archetype
/path/to/ai-setting/init.sh --auto-mcp /path/to/my-new-project

# Start an empty project with intent hints
/path/to/ai-setting/init.sh --project-name my-api --archetype backend-api --stack Python /path/to/my-new-project

# Diagnose current project state
/path/to/ai-setting/init.sh --doctor /path/to/my-new-project
```

### Claude Profiles

The default is `standard`. Four profiles are currently supported: `standard`, `minimal`, `strict`, and `team`.

| Profile | Includes |
|---------|----------|
| `standard` | File protection, dangerous command blocking, auto-format, notifications, stop check, 4 agents, 5 skills |
| `minimal` | File protection and auto-format only. Managed agents/skills are not copied |
| `strict` | `standard` + hook blocking direct git operations on main/master |
| `team` | `strict` + `.github/pull_request_template.md`, `.ai-setting/team-webhook.json` generation |

When switching profiles:
- Existing `.claude/` is backed up first
- Only ai-setting managed agents/skills/hooks are cleaned up and re-copied based on the selected profile
- Other `.claude` files created by the user are left untouched

### Link Mode

With `--link`, shared configuration assets are symlinked to the ai-setting repo originals instead of being copied.

With `--link-dir`, the `.claude/hooks`, `.claude/agents`, and `.claude/skills` directories are symlinked as a whole. Since they are linked at the directory level rather than individual files, new hooks/agents/skills added to ai-setting are automatically reflected.

Symlink targets (`--link`):
- `.claude/settings.json`
- `.claude/hooks/*` (individual files)
- `.claude/agents/*` (individual files)
- `.claude/skills/*` (individual files)
- `.cursor/rules/ai-setting.mdc`
- `.gemini/settings.json`

Symlink targets (`--link-dir`):
- `.claude/settings.json` (file)
- `.claude/hooks/` (entire directory)
- `.claude/agents/` (entire directory)
- `.claude/skills/` (entire directory)
- `.cursor/rules/ai-setting.mdc`
- `.gemini/settings.json`

Always kept as local files:
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
- `.github/copilot-instructions.md`, `.github/pull_request_template.md`
- `.codex/config.toml`
- `.mcp.json`
- `docs/decisions.md`

Rationale for this split:
- The above files vary per project or require additional generation/modification during init
- Conversely, hooks, agents, skills, and tool settings benefit more from staying in sync with the originals

### Update Mode

`init.sh update /path/to/project` is an explicit update mode for safely bringing an existing project to the latest settings.

Behavior:
- Updates shared assets (`.claude`, `.cursor`, `.gemini`)
- Updates `.codex/config.toml`, `.mcp.json`
- Keeps existing `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and Copilot docs as-is
- Does not run AI autofill

Recommended when:
- You pulled the ai-setting repo and want to re-align an existing project's settings
- You want to update only common rules/hooks/agents without touching project-specific docs
- Used with `--link` mode to align both link and local settings together

Difference from plugin approach:
- `update` re-aligns project files created by `init.sh`
- Plugin marketplace is a separate distribution channel for installing hooks/skills/agents/MCP within Claude Code
- For project doc templates and multi-tool files, `init.sh` is still needed

### Sync Mode

`init.sh sync [options] [manifest path]` is a batch synchronization mode for aligning multiple projects at once.

Default behavior:
- `sync` applies `update` or `init` flow to each project listed in the manifest, in order
- Default sync mode is `update`
- `--sync-mode init` applies the regular init flow to each project sequentially
- Options `--link`, `--profile`, `--auto-mcp`, `--mcp-preset`, `--no-mcp`, `--dry-run`, `--backup-all`, `--reapply` can be passed along

Manifest format:
- One project path per line
- Append `key=value` options after the path for per-project settings (overrides global options)
- Blank lines and `#` comments are ignored
- Relative paths are resolved relative to the manifest file location

Manifest example:

```text
# projects.manifest
../storyforge
../taskrelay  profile=strict  mcp-preset=core,web
../internal-tool  profile=minimal  archetype=cli-tool
```

Supported options: `profile=`, `mcp-preset=`, `archetype=`, `stack=`

Conflict detection:
- During sync/update, if locally modified managed files are detected, a conflict is flagged.
- `--sync-conflict=backup` (default): back up then overwrite
- `--sync-conflict=skip`: skip the project
- `--sync-conflict=overwrite`: overwrite directly

Per-project overrides:
- Place JSON in `.claude/settings.local.json` to deep merge into `settings.json` during update/init (requires jq).
- In symlink mode, if an override exists, settings.json switches to copy mode.
- `--merge` preserves custom values in existing `.claude/settings.json` and only adds ai-setting hooks (requires jq).
- The default formatter hook finds the nearest `package.json`, `pyproject.toml`, or `requirements*.txt` relative to the edited file to set the working directory. Supports `frontend/`, `backend/` split structures natively.

Getting started:
- Copy `templates/projects.manifest.template` to `projects.manifest` and fill in your paths

Recommended when:
- You updated the ai-setting repo and want to apply common assets to multiple projects at once
- You want to manage team/personal project setups in a single file
- You want to preview all planned actions with `--dry-run` before applying

### Multi-Tool Support

A default run also generates files for the following tools:

| Tool | Generated Files | @file Reference | Notes |
|------|----------------|-----------------|-------|
| Cursor | `.cursor/rules/ai-setting.mdc` | ⏳ Not working (Cursor fix pending) | always-apply rule, globs-based path rules work |
| Gemini CLI | `.gemini/settings.json`, `GEMINI.md` | ✅ Works | Import via `@./path/to/file.md` syntax |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | ❌ Not supported | Standalone files, `applyTo` path-specific instructions work |
| Codex CLI | `.codex/config.toml`, `AGENTS.md` | — (auto-read) | AGENTS.md auto-discovered/read from directory hierarchy |
| Claude Code | `CLAUDE.md`, `.claude/` | ✅ Works | `@path/to/file` syntax, up to 5 levels of recursion |

## Post-Setup Verification

The descriptions below are based on the default `standard` profile. If you used `--profile minimal`, only hooks remain and managed agents/skills are not copied.

### Ready to Use (No Modification Needed)
- `.claude/settings.json` — includes hooks, formatter, notifications
- `BEHAVIORAL_CORE.md` — shared behavioral principles core across tools
- `.claude/hooks/*` — file protection + dangerous command blocking + async test + session context + compact backup
- `.claude/agents/*` — security review, architecture review, test writing, research
- `.claude/skills/*` — deploy, code review, fix issue, gap check, cross-validate
- `docs/research-notes.md` — official docs/external research evidence and summaries
- `.claude/hooks/protect-main-branch.sh` — blocks direct git operations on main/master in strict/team
- `.ai-setting/team-webhook.json` — webhook meta-config template for team profile
- `.cursor/rules/ai-setting.mdc` — Cursor project-wide rule
- `.gemini/settings.json` / `GEMINI.md` — Gemini CLI context
- `.github/copilot-instructions.md` — GitHub Copilot repo instructions
- `.github/instructions/*.instructions.md` — Copilot path-specific instructions
- `.codex/config.toml` — Codex CLI default settings + project-local MCP
- `.mcp.json` — Claude Code project-local MCP
- `.mcp.notes.md` — guidance for manual MCP values such as API keys and paths

### Project-Local MCP Presets

The default is `core`. You can add `web` or `infra` as needed.

| Preset | Included Servers | Purpose |
|--------|-----------------|---------|
| `core` | `sequential-thinking`, `serena`, `upstash-context-7-mcp` | Common default for most projects |
| `web` | `playwright` | Frontend/browser automation |
| `infra` | `docker` | Container/local infrastructure tasks |

Excluded from defaults:
- `brave-search` — requires API key
- `filesystem` — pending path scope design review

Auto-recommendation criteria:
- `frontend-web` → `core + web`
- `infra-iac` → `core + infra`
- `backend-api`, `worker-batch`, `data-automation` + ops signals (Docker/compose, etc.) → `core + infra`

The default still applies only `core`; recommended presets are auto-applied only when `--auto-mcp` is used.

When an MCP needs manual values:
- `.mcp.json` stays comment-free because JSON comments are invalid.
- `.mcp.notes.md` is generated alongside it with guidance like where to put API keys or absolute paths.
- `.codex/config.toml` can safely include inline comments for the same purpose.

### Verify AI-Generated Files
Check that `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.github/copilot-instructions.md` are properly filled for your project.
If AI generation failed or was skipped with `--skip-ai`, fill in the `[bracketed]` sections manually or run:
```
claude "Fill in the [bracketed] parts of the project docs"
```

Notes:
- If Claude Code hangs without responding, it falls back to Codex after `20s` by default.
- Codex fallback currently uses `codex exec --skip-git-repo-check`.
- Even if both paths fail, templates and `docs/research-notes.md`, `docs/decisions.md` remain for manual correction.

### Automatic Project Interpretation Mode Detection

`init.sh` classifies the project state into one of 4 modes before AI autofill.

| Mode | Criteria | Behavior |
|------|----------|----------|
| `blank-start` | Almost no docs/implementation/test signals | Safely generates only templates and settings; skips AI autofill |
| `docs-first` | Sufficient doc signals, few implementation signals | Uses docs as primary evidence; leaves unimplemented items as TODO/assumptions |
| `hybrid` | Both doc and implementation signals present | Examines code/config first; uses docs for intent supplementation |
| `code-first` | Rich code/config/test signals | Interprets from actual implementation state; surfaces discrepancies with docs |

Detection signal examples:
- Docs: `README.md`, `docs/`, `spec/`, `prd/`, `requirements/`
- Implementation: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `src/`, `app/`, `backend/`, `frontend/`
- Tests/Ops: `tests/`, `.github/workflows/`, `Dockerfile`, `compose.yaml`, `.env.example`

Running on an empty folder first:
- Detected as `blank-start`
- `.claude`, `.codex`, `.mcp.json`, templates are generated
- `CLAUDE.md`, `AGENTS.md` are left as-is without over-inference; AI autofill is skipped
- Re-run after signals like `README.md`, `package.json`, `pyproject.toml`, `src/` appear

You can still provide intent hints in blank-start:
- `--project-name my-api`
- `--archetype backend-api`
- `--stack Python`

With these hints, it's treated as `guided blank-start`, producing hint-based drafts while leaving unverifiable parts as TODO/assumptions.

### Automatic Project Type and Stack Detection

Separately from interpretation mode, `init.sh` also detects the project archetype and primary stack, passing them to the AI prompt.

Supported archetypes:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app` (safe fallback for ambiguous cases)

Stack detection examples:
- `Next.js (TypeScript/JavaScript)`
- `Vite (TypeScript/JavaScript)`
- `Node.js / TypeScript`
- `Python`, `Go`, `Rust`, `Java / Kotlin`, `Ruby`, `PHP`

User hint options:
- `--project-name NAME`
- `--archetype TYPE`
- `--stack NAME`

Supported `--archetype` values:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app`

### Per-Project Customization

**Add patterns to protect-files.sh** (if needed):
```bash
# Protect DB migrations
"alembic/versions/"

# Protect Docker/config files
"compose.yaml"
"pyproject.toml"

# Protect data directories
"data/"
```

**Add project-specific agents/skills** (if needed):
```
.claude/agents/card-content-generator.md   ← StoryForge example
.claude/agents/spec-writer.md              ← TaskRelay example
.claude/skills/db-schema/SKILL.md          ← Domain skill
.claude/skills/phase-check.md              ← Workflow skill
```

Overwrite policy on repeated runs:
- If `.claude/` already exists, the entire directory is backed up to `.claude.backup.TIMESTAMP`
- If `.cursor/rules/ai-setting.mdc` already exists, backed up to `.backup.TIMESTAMP`
- If `.gemini/settings.json` already exists, backed up to `.backup.TIMESTAMP`
- If `.codex/config.toml` already exists, backed up to `.codex/config.toml.backup.TIMESTAMP`
- If `.mcp.json` already exists, backed up to `.mcp.json.backup.TIMESTAMP`
- Switching to `--profile minimal` cleans up ai-setting managed agents/skills, leaving only minimal settings
- `--profile strict` or `--profile team` applies the branch protection hook
- `--link` re-symlinks shared assets

### Doctor Mode

Run `init.sh --doctor /path/to/project` to diagnose the current state.

Diagnostic checks:
- Required binaries: `jq` (ERROR if missing — security hooks won't work), `npx`, `uvx`, `claude`, `codex`, `gemini`
- AI autofill readiness: execution capability and fallback chain status based on `claude --version`, `codex exec --help`
- Core files: `.claude/settings.json`, profile-specific hooks, `.cursor/rules/ai-setting.mdc`, `.gemini/settings.json`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md` (team), `.codex/config.toml`, `.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `docs/decisions.md`, `docs/research-notes.md`
- In team profile, `.ai-setting/team-webhook.json` is also checked
- `.mcp.json` JSON validity
- If `.claude/settings.local.json` exists: JSON validity + excessive permission warnings
- Remaining template/skill placeholders
- Whether shared asset mode is `copy` or `symlink`
- Whether an async test command is specified or auto-detectable
- Compact backup hook presence

Notes:
- In `blank-start` mode, remaining template/skill placeholders are treated as normal
- In `blank-start` mode, a note is shown that AI autofill is skipped by default when project evidence is scarce
- `minimal` profile treats absence of `block-dangerous-commands`, `async-test`, and managed skills as normal
- `minimal` profile treats inactive `session-context` and `compact-backup` as normal
- `strict/team` profile: error if `protect-main-branch.sh` is missing
- Exit code `1` if errors exist, `0` otherwise

### Dry-Run Mode

Run `init.sh --dry-run /path/to/project` to preview planned actions without making changes.

Behavior:
- Prints files and directories scheduled for creation/overwrite/backup
- Does not run AI autofill
- No actual files are modified after exit

### Diff Mode

Run `init.sh --diff /path/to/project` to see unified diffs between the current state and what init would produce.

Behavior:
- Compares against `.claude`, `.codex/config.toml`, `.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `docs/decisions.md`, `docs/research-notes.md`
- Also includes `.cursor/rules/ai-setting.mdc`, `.gemini/settings.json`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md`
- Does not modify actual files
- Does not include AI autofill results

Notes:
- `--doctor`, `--dry-run`, and `--diff` cannot be used simultaneously
- `sync` command cannot be used with `--doctor` or `--diff`

### Backup-All Mode

Run `init.sh --backup-all /path/to/project` to create a snapshot backup of all managed files before applying.

Behavior:
- Backs up `.claude`, `.codex/config.toml`, `.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `docs/decisions.md`, `docs/research-notes.md` to `.ai-setting.backup.TIMESTAMP/` under the target project
- Also backs up `.cursor/rules/ai-setting.mdc`, `.gemini/settings.json`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md`
- During subsequent overwrite steps, individual `.backup.*` files are not redundantly created; a snapshot inclusion notice is printed instead
- When used with `--dry-run`, only prints the planned snapshot creation

Notes:
- `--backup-all` cannot be used with `--doctor` or `--diff`

### Reapply Mode

Run `init.sh --reapply /path/to/project` to regenerate project doc templates from fresh templates and re-run AI autofill.

Behavior:
- Existing `CLAUDE.md`, `AGENTS.md` are backed up and regenerated from new templates
- Existing `GEMINI.md`, `.github/copilot-instructions.md`, `.github/pull_request_template.md` (team) are also backed up and regenerated
- AI autofill step runs again afterward
- `.claude`, `.codex`, `.mcp.json` are re-applied with latest settings as usual
- `docs/decisions.md` is preserved as a user record file
- `docs/research-notes.md` and `docs/decisions.md` are encouraged to cross-reference via `R-xxx` / `D-xxx` format

Recommended combinations:
- For safety: `--backup-all --reapply`
- For preview only: `--dry-run --reapply`

Notes:
- `--reapply` cannot be used with `--doctor` or `--diff`

---

## Structure

```
ai-setting/
├── .claude-plugin/
│   └── marketplace.json                  # Claude Code plugin marketplace catalog
├── bin/
│   └── ai-setting                         # Local CLI wrapper (runs `init.sh`)
├── init.sh                               # 🚀 Initialization script
├── package.json                          # npm package (@jaewon94/ai-setting)
├── claude/
│   ├── settings.json                      # standard profile template
│   ├── settings.minimal.json              # minimal profile template
│   ├── settings.strict.json               # strict profile template
│   ├── settings.team.json                 # team profile template
│   ├── hooks/
│   │   ├── protect-files.sh               # Block sensitive file edits (20 patterns)
│   │   ├── block-dangerous-commands.sh    # Block dangerous commands (14 patterns)
│   │   ├── async-test.sh                  # Background test after edits
│   │   ├── compact-backup.sh              # Snapshot backup for compact recovery
│   │   ├── protect-main-branch.sh         # Block direct git ops on main/master
│   │   ├── session-context.sh             # Context snapshot for compact preparation
│   │   └── team-webhook-notify.sh         # Team profile webhook notification
│   ├── agents/
│   │   ├── security-reviewer.md           # Security review (read-only, opus)
│   │   ├── architect-reviewer.md          # Architecture review (read-only, opus)
│   │   ├── test-writer.md                 # Test writing (sonnet)
│   │   └── research.md                    # Technical research (search tools)
│   └── skills/
│       ├── deploy/SKILL.md                # Deployment checklist
│       ├── review/SKILL.md                # Code review checklist
│       ├── fix-issue/SKILL.md             # Issue fix workflow
│       ├── gap-check/SKILL.md             # Missing requirements detection
│       └── cross-validate/SKILL.md        # AI output cross-validation
├── cursor/
│   └── rules/
│       ├── ai-setting.mdc                 # always-apply (common rules, @AGENTS.md @CLAUDE.md)
│       ├── typescript.mdc                 # glob: **/*.ts,**/*.tsx — TS coding rules
│       ├── python.mdc                     # glob: **/*.py — Python coding rules
│       └── testing.mdc                    # glob: **/*.test.*,**/*.spec.* — Testing rules
├── gemini/
│   └── settings.json                      # Gemini CLI workspace settings
├── codex/
│   ├── config.toml                        # standard profile (default)
│   ├── config.minimal.toml                # minimal profile (auto-edit)
│   ├── config.strict.toml                 # strict profile (suggest)
│   └── config.team.toml                   # team profile (suggest)
├── plugins/
│   ├── ai-setting-core/                  # Core plugin (hooks, agents, skills, MCP)
│   │   ├── .claude-plugin/plugin.json
│   │   ├── hooks/hooks.json
│   │   ├── scripts/, agents/, skills/
│   │   └── .mcp.json
│   ├── ai-setting-strict/               # Strict plugin (branch protection)
│   │   ├── .claude-plugin/plugin.json
│   │   ├── hooks/hooks.json
│   │   └── scripts/protect-main-branch.sh
│   └── ai-setting-team/                 # Team plugin (webhook notification)
│       ├── .claude-plugin/plugin.json
│       ├── hooks/hooks.json
│       └── scripts/team-webhook-notify.sh
├── templates/
│   ├── CLAUDE.md.template                 # Fill in the [brackets]
│   ├── AGENTS.md.template                 # Fill in the [brackets]
│   ├── GEMINI.md.template                 # Gemini CLI context template
│   ├── copilot-instructions.md.template   # Copilot repo instructions template
│   ├── projects.manifest.template         # Multi-project sync manifest example
│   ├── pull_request_template.md.template  # Team profile PR template
│   ├── team-webhook.json.template         # Team profile webhook meta-config template
│   └── decisions.md.template              # Technical decision records
├── lib/
│   ├── common.sh                          # Colors, timestamps, common utilities
│   ├── validate.sh                        # Input validation, usage, profile/archetype validation
│   ├── fileops.sh                         # File/directory creation, copy, symlink
│   ├── assets.sh                          # Shared asset installation (symlink/copy)
│   ├── backup.sh                          # Snapshot backup, existing path backup
│   ├── config-detect.sh                   # Existing config detection (profile, asset mode, test strategy)
│   ├── doctor.sh                          # Doctor diagnostics, diff preview
│   ├── detect.sh                          # Project mode/archetype/stack detection
│   ├── mcp.sh                             # MCP preset management and config generation
│   ├── profile.sh                         # Claude/Cursor/Gemini/Codex/Copilot asset copy, add-tool
│   ├── sync.sh                            # Manifest parsing, conflict detection, sync execution
│   └── plugin.sh                          # Plugin list/install/uninstall/check-update/upgrade
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                        # CI pipeline (lint, smoke, profile, sync tests)
│   │   ├── release.yml                   # Auto release (npm publish + GitHub Release)
│   │   └── homebrew.yml                  # Homebrew tap formula auto-update
│   └── ISSUE_TEMPLATE/                   # Bug report, feature request templates
├── Formula/
│   └── ai-setting.rb                     # Homebrew formula
├── LICENSE                               # MIT
├── SECURITY.md                           # Security policy
├── .npmignore                            # npm publish exclusions
├── .gitignore                            # OS/IDE/runtime exclusion patterns
├── .gitattributes                        # Shell script LF enforcement, diff settings
├── tests/
│   ├── run_all.sh                        # Run all tests
│   ├── test_helper.sh                    # Test framework
│   ├── test_basic.sh                     # Basic functionality tests
│   ├── test_profiles.sh                  # Profile tests
│   ├── test_tools.sh                     # Tool selection tests
│   ├── test_detect.sh                    # Archetype/stack detection tests
│   ├── test_sync.sh                      # Sync/plugin tests
│   └── test_hooks.sh                     # Hook security/cross-platform tests
└── README.md
```

---

## Included Configuration Details

### Hooks — Auto-Execution

| Hook | Trigger | Role |
|------|---------|------|
| **protect-files.sh** | Before file edit | Blocks editing .env, lock files, .git, auth keys, build artifacts |
| **block-dangerous-commands.sh** | Before Bash execution | Blocks rm -rf, sudo, force push, DROP TABLE, etc. |
| **async-test.sh** | PostToolUse(Edit/Write) | Runs async tests best-effort after code file edits |
| **compact-backup.sh** | Stop / SessionStart(compact) | Maintains latest/history snapshots for compact session recovery |
| **session-context.sh** | Stop / SessionStart(compact) | Updates and restores project context snapshots for compact preparation |
| **team-webhook-notify.sh** | Stop(team) | Optionally sends completion notifications to Slack/Discord webhooks |
| **auto-format** | After file edit | Python→ruff, TS/JS→prettier auto-format |
| **test-check** | On task completion | Checks whether tests were run after code changes |
| **notification** | When input is needed | Cross-platform desktop notifications (macOS/Windows/Linux) |
| **session-reminder** | On compact | Reminder to read CLAUDE.md/AGENTS.md |

### Agents — Sub-Agents

| Agent | Model | Permissions | Role |
|-------|-------|-------------|------|
| **security-reviewer** | opus | Read + Bash | Security vulnerabilities (injection, auth, secrets, AI API, file upload) |
| **architect-reviewer** | opus | Read-only | Design quality (separation of concerns, dependencies, God classes, naming) |
| **test-writer** | sonnet | Write-enabled | Test generation (pytest, Vitest, happy/edge/error paths) |
| **research** | — | Search tools | Technical research (official docs → web search → GitHub examples) |

### Skills — Slash Commands

| Skill | Role |
|-------|------|
| **/deploy** | Pre-deploy check → deploy → post-deploy verification |
| **/review** | Security / Backend / Frontend / General checklists |
| **/fix-issue** | gh issue → failing tests → fix → lint → PR |
| **/gap-check** | Missing requirements detection (Implicit Requirements + What If analysis) |
| **/cross-validate** | AI-generated docs/code vs actual state cross-verification |

### Project-Local MCP

| Location | Role |
|----------|------|
| `.codex/config.toml` | Codex CLI `mcp_servers.*` configuration |
| `.mcp.json` | Claude Code project-scoped MCP configuration |

Default presets:
- `core` → `sequential-thinking`, `serena`, `upstash-context-7-mcp`
- Optional `web` → `playwright`
- Optional `infra` → `docker`

### Claude Code Plugins

| Plugin | Contents |
|--------|----------|
| `ai-setting-core` | 5 hooks, 4 agents, 5 skills, core MCP |
| `ai-setting-strict` | main/master branch protection hook |
| `ai-setting-team` | Slack/Discord webhook notification hook |

Notes:
- Plugins are a Claude Code-exclusive distribution channel, so Cursor/Gemini/Copilot/Codex files are not included.
- Plugin skills don't have AI-filled placeholders like init-based projects; they provide generic guidance text instead.
- Installing/uninstalling via `ai-setting plugin install/uninstall` CLI is recorded in `.ai-setting/installed-plugins.json`.

### Protection Patterns (protect-files.sh)

Three-way matching to prevent false positives:

| Match Type | Patterns | Description |
|------------|----------|-------------|
| **Directory** (path contains) | `.git/`, `node_modules/`, `__pycache__/`, `.venv/`, `dist/`, `build/`, `.next/` | Blocked if path contains these |
| **Filename** (basename match) | `.env`, `.env.local`, `.env.production`, `.env.development`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `uv.lock`, `credentials.json` | Blocked only on exact filename match |
| **Extension** (basename suffix) | `*.sqlite`, `*.sqlite3`, `*.pem`, `*.key` | Blocked if file ends with these extensions |

### Dangerous Command Blocking (block-dangerous-commands.sh)

```
rm -rf /    rm -rf ~    rm -rf .    sudo
git push --force/--f    git reset --hard
DROP TABLE    DROP DATABASE    TRUNCATE TABLE
chmod 777    mkfs    > /dev/sda    fork bomb
```

### Async Test Hook (async-test.sh)

- Active only in `standard`, `strict`, and `team` profiles.
- Priority: `.ai-setting/test-command` → `AI_SETTING_ASYNC_TEST_CMD` → auto-detection (Python/Go/Rust + monorepo subdirectory scanning).
- Status file at `.claude/context/async-test-status.md`, logs at `.claude/context/async-test.log`.
- If a test is already running, the existing job is kept without duplicate execution.
- For JavaScript/TypeScript projects, test runner options vary widely, so specifying `.ai-setting/test-command` is recommended initially.

Example:

```bash
mkdir -p .ai-setting
printf '%s\n' 'pnpm test -- --runInBand' > .ai-setting/test-command
```

### Team Webhook Notifications (team-webhook-notify.sh)

- An optional hook active only in `team` profile.
- Recommended approach: keep the actual URL in environment variables and only store meta-config in `.ai-setting/team-webhook.json`.
- Default is `enabled: false`, so nothing is sent immediately after generation.
- Status file at `.claude/context/team-webhook-status.md`.

Example:

```bash
export AI_SETTING_TEAM_WEBHOOK_URL='https://hooks.slack.com/services/...'

cat > .ai-setting/team-webhook.json <<'JSON'
{
  "enabled": true,
  "url_env": "AI_SETTING_TEAM_WEBHOOK_URL",
  "channel": "#ai-alerts",
  "username": "Claude Code",
  "mention": "",
  "events": ["stop"]
}
JSON
```

### Compact Backup (compact-backup.sh)

- Active only in `standard`, `strict`, and `team` profiles.
- Updates `.claude/context/compact-latest.md` on each Stop and maintains timestamped history under `.claude/context/compact-history/`.
- When compact occurs at SessionStart, `session-context.sh` prioritizes restoring the latest compact backup.
- Snapshots include session context, async test status, team webhook status, and git status summary.

---

## CLAUDE.md Template — Included Common Sections (17)

| Section | Content |
|---------|---------|
| Project Rules | @AGENTS.md reference |
| Build & Run | [Project-specific commands] |
| Library-First Principle | Check libraries before implementing, verify with official docs |
| Dependency Management | Prefer stdlib, pin versions, check security vulnerabilities |
| Research Principle | Official doc verification required when adopting new tech |
| Preflight Principle | Analyze → plan → confirm → execute |
| Educational Progress Principle | Structural boundary comments, "why"-focused, no code-repeating comments |
| AI Integration | Must go through abstract interfaces |
| Error Handling Rules | Catch only specific exceptions, structlog, transient/permanent distinction |
| Environment Variable Rules | pydantic-settings, .env only, .env.example documentation |
| Safeguards | Retry limits, cost guardrails, rollback strategies |
| Cross-Validation Principle | AI output vs actual code/state cross-check required |
| Gap Detection Principle | Missing requirements detection, What If analysis, scope limits |
| Code-Doc Sync | Update related docs when code changes |
| Terminology Disambiguation | Explicitly distinguish when same term has multiple contexts |
| Decision Records | Record choices + reasons + alternatives in decisions.md |
| Domain Knowledge | [Project-specific doc references] |

## AGENTS.md Template — Included Common Rules

**General Principles** (11):
TDD, library-first, separation of concerns, SOLID/DRY/KISS/YAGNI, Fail Fast, immutability, secure defaults, structured logging, educational comments, modular design, Preflight

**Forbidden** (10):
God classes, business logic placement, reinventing the wheel, manual DDL, libraries without official docs, any type, except:pass, direct AI API calls, hardcoded secrets, comment noise

---

## Sources and Verification

- **StoryForge** (.claude/ config source) + **TaskRelay** (.claude/ config source)
- **Claude Code official docs** — hooks spec, permissions syntax, agents/skills format
- **Codex CLI official docs** — config.toml field validation
- **Community** — Trail of Bits config, Awesome Claude Code, Claude Code Hooks Mastery
