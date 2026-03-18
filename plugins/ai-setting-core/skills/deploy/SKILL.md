---
name: deploy
description: Deploy project to production
disable-model-invocation: true
---
Deploy: $ARGUMENTS

## Pre-deploy Checklist
1. Detect the real backend test command from the repository first.
2. Detect the real frontend test command from the repository first, if a frontend exists.
3. Detect the real lint command from project scripts, Makefile, CI, or docs before running anything.
4. Check for uncommitted changes: `git status`
5. Ensure you are on the intended release branch for this project.

## Deploy Steps

### Backend
```bash
# Run the project's documented backend deploy command here.
# Prefer existing scripts, task runners, or CI/CD entrypoints over inventing a new command.
```

### Frontend
```bash
# Run the project's documented frontend deploy command here, if applicable.
```

### Database Migration (if needed)
```bash
# Run the documented migration command only if the change actually requires it.
```

## Post-deploy
1. Check the health endpoint or smoke test route defined by the project.
2. Check the main user-facing entrypoint if the project has a frontend.
3. Verify the latest changes are live.
4. Monitor logs and error tracking for a short period after deploy.
