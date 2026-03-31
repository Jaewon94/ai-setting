# Reference

## Tool Support

| Tool | Generated Files | Notes |
|------|-----------------|-------|
| Claude Code | `.claude/`, `CLAUDE.md` | Primary integration target with profile and tool-role guidance |
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
- `.ai-setting/protect-files.json`
- `.ai-setting/protect-files.notes.md`
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

Archetype-specific composition:
- `CLAUDE.md` gets an archetype partial automatically
- `AGENTS.md` also gets archetype-specific agent-rules partials automatically

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
| `format-on-write.sh` | after edit/write | runs formatter selection based on the nearest project markers |
| `async-test.sh` | after edit/write | best-effort background test run |
| `compact-backup.sh` | stop / compact start | compact recovery snapshots |
| `session-context.sh` | stop / compact start | session context preservation |
| `protect-main-branch.sh` | git-sensitive flows | strict/team branch protection |
| `team-webhook-notify.sh` | stop | optional team webhook notification |

Related automatic behavior:
- Python formatting via `ruff`
- TS/JS formatting via `prettier`
- Notification hooks
- session context / compact recovery flows

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
| `document-feature` | structure feature-level documentation |
| `document-infra` | structure infrastructure and operations docs |
| `document-security` | structure security implementation and operations docs |

Operational metadata:
- `.claude/skills/metadata.json`
  - `category`
  - `explicit_only`
  - `profile_scope`
  - `required_tools`
  - `required_mcp`
  - `risk_level`

## Hook Metadata

- `.claude/hooks/metadata.json`
  - `event`
  - `matcher`
  - `type`
  - `blocking_or_async`
  - `profile_scope`
  - `risk_level`
  - `requires_network_or_secret`

## MCP Configuration

Locations:
- `.codex/config.toml`
- `.mcp.json`
- `.mcp.notes.md`
- `.ai-setting/protect-files.json`
- `.ai-setting/protect-files.notes.md`

Default presets:
- `core`
- optional `web`
- optional `infra`
- optional `git`
- optional `chrome`
- auto-recommended `next` for detected Next.js stacks
- optional `local`

Manual values:
- JSON comments are avoided in `.mcp.json`
- Notes live in `.mcp.notes.md`
- Codex comments can live in TOML

## Protection Patterns

`protect-files.sh` policy:
- immediate block:
  - credential files
  - certain database/key extensions
  - generated/build/cache directories
- confirm-before-accept:
  - `.env*`
  - lock files
  - `docker-compose*.yml`
  - `.github/workflows/*`
- project override:
  - `.ai-setting/protect-files.json` can adjust `allow` / `confirm` / `block`
  - built-in hard-block entries cannot be downgraded by override

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
