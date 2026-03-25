---
name: fix-issue
description: Analyze and fix a GitHub issue with tests
disable-model-invocation: true
---
Analyze and fix the GitHub issue: $ARGUMENTS.

1. Use `gh issue view $ARGUMENTS` to get issue details
2. Understand the problem — search codebase for relevant files
3. Write a failing test that reproduces the issue
4. Implement the fix
5. Run the relevant existing test command for the touched area. Detect it from project scripts, CI, or docs before running anything.
6. Run the relevant lint or format command if the repository defines one.
7. Create a descriptive commit that matches the repository's own commit conventions
8. Push and create a PR: `gh pr create --fill`
