---
name: review
description: Code review checklist
disable-model-invocation: true
---
Review the code changes: $ARGUMENTS

## Checklist

### Security
- [ ] No hardcoded secrets or API keys
- [ ] SQL injection prevention (parameterized queries via ORM)
- [ ] XSS prevention (framework auto-escaping, no raw HTML injection)
- [ ] Auth checks on all protected endpoints
- [ ] AI API keys not exposed to frontend

### Backend
- [ ] Type hints / type annotations on all functions
- [ ] Request/response validation schemas (Pydantic, zod, etc.)
- [ ] Async operations where appropriate (no sync calls in async context)
- [ ] Proper error handling with meaningful messages
- [ ] AI calls go through abstract interface (not direct API calls)

### Frontend
- [ ] No `any` types (TypeScript)
- [ ] Proper loading/error/empty states
- [ ] Responsive design
- [ ] Animations via designated library (not raw CSS for interactive elements)

### General
- [ ] Tests written for new functionality
- [ ] No unnecessary console.log / print statements
- [ ] Follows existing patterns in codebase

Use a subagent to review each area in parallel if the changeset is large.
