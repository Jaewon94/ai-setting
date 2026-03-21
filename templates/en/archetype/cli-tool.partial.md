## CLI Rules
- All commands must support --help with clear usage instructions
- Use exit codes meaningfully (0=success, 1=general error, 2=usage error)
- Properly separate stdin/stdout/stderr (results to stdout, progress/errors to stderr)
- Long-running operations must show progress indicators (progress bar, spinner, etc.)
- Configuration priority: CLI arguments > environment variables > config files
- Pipe-friendly: separate human-readable output from machine-readable output (--json, etc.)
- Testing: CLI argument parsing tests + key command integration tests
