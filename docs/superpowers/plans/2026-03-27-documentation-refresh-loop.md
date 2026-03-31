# Documentation Refresh Loop

## Goal

Refresh project documentation against current implementation state before any new feature work.

## Source Of Truth

- CLI behavior: `./bin/ai-setting --help`
- Current implementation: `init.sh`, `lib/*.sh`, generated templates, plugin assets
- Verification status: `./tests/run_all.sh`
- Release metadata: `package.json`, distribution docs, deployment checklist

## Scope

- `README.md`
- `README.ko.md`
- `docs/usage.md`
- `docs/usage.ko.md`
- `docs/reference.md`
- `docs/reference.ko.md`
- `docs/roadmap.md`
- `docs/issues.md`
- `docs/distribution/*`
- `docs/deployment-checklist.md`
- `docs/field-test-*.md`
- `docs/plans/*.md`

## Loop

1. Compare one document group against the current source of truth.
2. Record concrete mismatches only.
3. Update the affected documents.
4. Re-run verification:
   - `./bin/ai-setting --help`
   - `./tests/run_all.sh`
   - targeted doc spot checks with `rg` / `sed`
5. Repeat until no factual mismatch remains in the current scope.

## Current Pass

### Pass 1

- Fix stale status numbers in `docs/roadmap.md`
- Add missing `--merge` documentation in `docs/usage.md`
- Add missing `--merge` documentation in `docs/usage.ko.md`

### Pass 2

- Reconcile Phase 8/9 roadmap state with current implementation and tests
- Sync execution/sub-plan documents with delivered document skills, metadata manifests, and protect-files policy
- Add tool support summary tables to `README.md` and `README.ko.md`

### Pass 3

- Sync MCP preset documentation with shipped `git`, `chrome`, and `next` presets
- Update roadmap Phase 11 notes to separate shipped presets from remaining candidates
- Re-run help/test verification after documentation refresh

## Exit Criteria

- No documented behavior contradicts current CLI help or test results
- Status/count claims are backed by fresh repository inspection
- Any remaining uncertainty is explicitly labeled as a future plan, not current behavior
