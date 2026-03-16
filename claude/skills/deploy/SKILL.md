---
name: deploy
description: Deploy project to production
disable-model-invocation: true
---
Deploy: $ARGUMENTS

## Pre-deploy Checklist
1. Run all backend tests: `{{TEST_BACKEND_CMD}}`
2. Run all frontend tests: `{{TEST_FRONTEND_CMD}}`
3. Run linters: `{{LINT_CMD}}`
4. Check for uncommitted changes: `git status`
5. Ensure on main branch or release branch

## Deploy Steps

### Backend
```bash
{{DEPLOY_BACKEND_CMD}}
```

### Frontend
```bash
{{DEPLOY_FRONTEND_CMD}}
```

### Database Migration (if needed)
```bash
{{MIGRATE_CMD}}
```

## Post-deploy
1. Check health endpoint: `curl {{HEALTH_URL}}`
2. Check frontend: open {{FRONTEND_URL}}
3. Verify latest changes are live
4. Monitor error tracking for new errors (5 minutes)
