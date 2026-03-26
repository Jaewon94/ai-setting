# Reference

## Tool Support

| Tool | Generated Files | Notes |
|------|-----------------|-------|
| Claude Code | `.claude/`, `CLAUDE.md` | Primary integration target |
| Codex CLI | `.codex/config.toml`, `.codex/config.notes.md`, `AGENTS.md` | AGENTS.md is auto-read from the directory hierarchy |
| Cursor | `.cursor/rules/*.mdc` | Common plus stack/archetype rules; `@file` behavior still depends on Cursor-side support |
| Gemini CLI | `.gemini/settings.json`, `.gemini/settings.notes.md`, `GEMINI.md` | Config file plus manual-adjustment notes and context file |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | Repo-wide guidance plus stack/archetype path-specific instructions |

## Generated Asset Categories

- `.claude/settings.json`
- `.claude/hooks/*`
- `.claude/agents/*`
- `.claude/skills/*`
- `.cursor/rules/*`
- `.gemini/settings.json`
- `.gemini/settings.notes.md`
- `.codex/config.toml`
- `.codex/config.notes.md`
- `.mcp.json`
- `.mcp.notes.md`
- `CLAUDE.md`
- `AGENTS.md`
- `GEMINI.md`
- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `docs/decisions.md`
- `docs/research-notes.md`

## Profiles

| Profile | Behavior |
|---------|----------|
| `standard` | Default managed hooks, agents, skills |
| `minimal` | Minimal hook set, no managed agents/skills copied |
| `strict` | `standard` plus direct git protection on main/master |
| `team` | `strict` plus PR template and webhook meta-config |

## Interpretation Modes

Before AI autofill, `init.sh` classifies the project into one of four modes.

| Mode | Meaning |
|------|---------|
| `blank-start` | Almost no project signals yet |
| `docs-first` | Docs are stronger than implementation evidence |
| `hybrid` | Docs and implementation signals both matter |
| `code-first` | Rich implementation/test signals dominate |

Signals include:
- docs: `README.md`, `docs/`, `spec/`, `prd/`
- implementation: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `src/`, `app/`, `backend/`, `frontend/`
- tests/ops: `tests/`, workflows, Docker files, `.env.example`

## Archetype and Stack Detection

Supported archetypes:
- `frontend-web`
- `backend-api`
- `cli-tool`
- `worker-batch`
- `data-automation`
- `library-sdk`
- `infra-iac`
- `general-app`

Detected stack examples:
- `Next.js`
- `Vite`
- `Node.js / TypeScript`
- `Python`
- `Go`
- `Rust`
- `Java / Kotlin`
- `Ruby`
- `PHP`

## Link and Copy Behavior

`--link`:
- symlinks selected shared assets file-by-file

`--link-dir`:
- symlinks hooks, agents, and skills as directories

Always local:
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

## Hooks

| Hook | Trigger | Role |
|------|---------|------|
| `protect-files.sh` | before edit | blocks sensitive file edits |
| `block-dangerous-commands.sh` | before bash | blocks destructive commands |
| `async-test.sh` | after edit/write | best-effort background test run |
| `compact-backup.sh` | stop / compact start | compact recovery snapshots |
| `session-context.sh` | stop / compact start | session context preservation |
| `protect-main-branch.sh` | git-sensitive flows | strict/team branch protection |
| `team-webhook-notify.sh` | stop | optional team webhook notification |

Related automatic behavior:
- Python formatting via `ruff`
- TS/JS formatting via `prettier`
- Notification hooks
- test reminder / session reminder flows

## Agents

| Agent | Role |
|-------|------|
| `security-reviewer` | security review |
| `architect-reviewer` | architecture review |
| `test-writer` | test generation |
| `research` | research using search/doc tools |

## Skills

| Skill | Role |
|-------|------|
| `deploy` | deploy checklist/workflow |
| `review` | review checklist |
| `fix-issue` | issue-to-fix workflow |
| `gap-check` | missing requirements detection |
| `cross-validate` | AI output vs actual state verification |

## MCP Configuration

Locations:
- `.codex/config.toml`
- `.mcp.json`
- `.mcp.notes.md`

Default presets:
- `core`
- optional `web`
- optional `infra`
- optional `local`

Manual values:
- JSON comments are avoided in `.mcp.json`
- Notes live in `.mcp.notes.md`
- Codex comments can live in TOML

## Protection Patterns

`protect-files.sh` blocks:
- sensitive env files
- lock files
- credential files
- certain database/key extensions
- generated/build/vendor/cache directories

`block-dangerous-commands.sh` blocks patterns like:
- `rm -rf`
- `sudo`
- `git push --force`
- `git reset --hard`
- destructive SQL
- raw device writes

## Async Test Behavior

Priority:
- `.ai-setting/test-command`
- `AI_SETTING_ASYNC_TEST_CMD`
- auto-detection

Auto-detection is monorepo-aware and searches for the nearest relevant project markers.

## Structure

High-level repo layout:

```text
ai-setting/
├── bin/
├── claude/
├── codex/
├── cursor/
├── gemini/
├── plugins/
├── templates/
├── lib/
├── tests/
└── docs/
```

Important implementation areas:
- `init.sh`: thin main entry and mode orchestration
- `lib/cli.sh`: CLI parsing, subcommand preprocessing, mode validation
- `lib/deps.sh`: jq dependency checks
- `lib/init-flow.sh`: step 1-5 execution, template copy, summary output
- `lib/ai-autofill.sh`: AI autofill and Claude/Codex fallback
- `lib/profile.sh`: tool/profile asset application
- `lib/mcp.sh`: MCP generation
- `lib/doctor.sh`: diagnostics and diff logic
- `lib/sync.sh`: manifest sync flow
