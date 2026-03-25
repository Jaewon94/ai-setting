# npm Distribution

## Scope

This document covers how `ai-setting` is published and verified on npm.

Package facts:

- package name: `@jaewon94/ai-setting`
- current CLI entry: `bin/ai-setting.js`
- current `package.json` version: `1.1.8`
- expected runtime entry from users: `npx @jaewon94/ai-setting ...`

## Source of Truth

- package metadata: [`package.json`](../../package.json)
- npm release workflow: [`.github/workflows/release.yml`](../../.github/workflows/release.yml)

## Publish Model

The release workflow is tag-driven.

1. Update `package.json` version.
2. Push the release commit to `main`.
3. Create and push a `v*` tag.
4. GitHub Actions publishes to npm if that exact package version does not already exist.
5. The same workflow creates a GitHub Release.

## Required Secrets

- `NPM_TOKEN`

Without `NPM_TOKEN`, `.github/workflows/release.yml` cannot publish.

## Local Verification

Run these before tagging:

```bash
./tests/run_all.sh
npm pack --dry-run
npx @jaewon94/ai-setting --help
```

Recommended extra check in a clean temp directory:

```bash
mkdir -p /tmp/ai-setting-smoke
cd /tmp/ai-setting-smoke
npx @jaewon94/ai-setting --help
```

## Known Caveats

- In this repo root, `npx @jaewon94/ai-setting --help` may behave differently from a clean directory because the local package context changes command resolution.
- `npm pack --dry-run` can fail with `EPERM` if the local npm cache has permission issues.
- In Codex sandbox runs, `~/.npm` permission failures can be false positives caused by sandbox restrictions.

## Release-Day Checklist

```bash
./tests/run_all.sh
npm pack --dry-run
git log --oneline -5
git tag v1.1.8
git push origin v1.1.8
```

After release:

```bash
npm view @jaewon94/ai-setting version --userconfig=/dev/null
npx @jaewon94/ai-setting --help
```

## Troubleshooting

### Version already exists

The release workflow already checks whether the package version exists. If publish is skipped, bump `package.json` and tag a new version.

### EPERM during pack or view

Check local npm cache ownership first. If the same command succeeds outside a restricted sandbox, treat it as an environment issue, not a package-layout issue.

### Wrong files in tarball

Re-run:

```bash
npm pack --dry-run
```

Then inspect `files`, `bin`, and runtime assets in [`package.json`](../../package.json).
