## Backend Agent Rules
- Separate request validation, business logic, and persistence, and treat API contracts as compatibility boundaries.
- Do not miss operational defaults such as auth, rate limiting, health checks, and migrations.
- When schemas or data flows change, verify tests, fixtures, and operational notes together.
- Design normal and failure paths together for retry-sensitive or idempotent work.
