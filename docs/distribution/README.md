# Distribution Docs

Operational notes for shipping `ai-setting` through external distribution channels.

Use these docs when you need to:

- publish a new npm version
- update or troubleshoot the Homebrew tap
- verify release-channel behavior after tagging

Documents:

- [npm.md](npm.md): package metadata, publish flow, verification, caveats
- [homebrew.md](homebrew.md): tap repo setup, formula generation, verification, troubleshooting
- [../deployment-checklist.md](../deployment-checklist.md): release-day checklist across GitHub, npm, and Homebrew

Suggested order:

1. Read [../deployment-checklist.md](../deployment-checklist.md) for the most recently verified release checklist.
2. Use [npm.md](npm.md) for npm-specific execution details.
3. Use [homebrew.md](homebrew.md) for tap maintenance and formula verification.

Verification policy:
- use the smallest relevant test suite first
- run `./tests/run_all.sh` once as the final release gate
