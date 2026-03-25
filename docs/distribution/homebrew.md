# Homebrew Distribution

## Scope

This document covers how `ai-setting` is exposed through the Homebrew tap.

Channel facts:

- tap repo: `Jaewon94/homebrew-ai-setting`
- install command: `brew install Jaewon94/ai-setting/ai-setting`
- formula source in this repo: [`Formula/ai-setting.rb`](../../Formula/ai-setting.rb)
- formula generator: [`scripts/render-homebrew-formula.sh`](../../scripts/render-homebrew-formula.sh)

## Source of Truth

- Homebrew workflow: [`.github/workflows/homebrew.yml`](../../.github/workflows/homebrew.yml)
- tap formula template source: [`Formula/ai-setting.rb`](../../Formula/ai-setting.rb)
- release checklist: [../deployment-checklist.md](../deployment-checklist.md)

## Delivery Model

The Homebrew path is tag-driven, with a manual fallback.

1. A `v*` tag triggers `.github/workflows/homebrew.yml`.
2. The workflow downloads the GitHub release tarball for that tag.
3. It computes the tarball `sha256`.
4. It renders a new `Formula/ai-setting.rb`.
5. It pushes that formula into `Jaewon94/homebrew-ai-setting`.

If needed, the workflow can also run manually with `workflow_dispatch`.

## Required GitHub Configuration

Repository variable:

- `HOMEBREW_TAP_REPO=Jaewon94/homebrew-ai-setting`

Repository secret:

- `HOMEBREW_TAP_GH_TOKEN`

Without those values, the Homebrew workflow cannot update the tap repository.

## Formula Notes

The formula installs the repo into `libexec`, then exposes the Node wrapper from `bin/ai-setting.js` as `ai-setting`.

Current install logic:

```ruby
def install
  libexec.install Dir["*"]
  chmod 0555, libexec/"bin/ai-setting.js"
  bin.install_symlink libexec/"bin/ai-setting.js" => "ai-setting"
end
```

This avoids the broken shell-wrapper path that expected `/opt/homebrew/init.sh`.

## Local Verification

Recommended validation commands:

```bash
brew uninstall ai-setting
brew install Jaewon94/ai-setting/ai-setting
ai-setting --help
brew test Jaewon94/ai-setting/ai-setting
```

As of 2026-03-25, both install and `brew test` were verified successfully.

## Manual Recovery Flow

If the workflow does not update the tap correctly:

1. Recompute the release tarball `sha256`.
2. Regenerate the formula with [`scripts/render-homebrew-formula.sh`](../../scripts/render-homebrew-formula.sh).
3. Commit and push the updated formula into `Jaewon94/homebrew-ai-setting`.
4. Reinstall locally with Homebrew and re-run `ai-setting --help`.

## Troubleshooting

### Installed command points to the wrong file

Do not point Homebrew at the shell wrapper `bin/ai-setting`. Under Homebrew layout that wrapper can resolve the repo root incorrectly. The formula should expose `bin/ai-setting.js` as `ai-setting`.

### Formula creates the wrong executable name

Prefer `bin.install_symlink libexec/"bin/ai-setting.js" => "ai-setting"` for this project. Earlier `write_exec_script` attempts created the wrong output layout for this specific command name.

### Tap update workflow does nothing

Check these first:

- `HOMEBREW_TAP_REPO` variable exists
- `HOMEBREW_TAP_GH_TOKEN` secret exists
- the tag points to the intended release version
- the generated formula actually changed
