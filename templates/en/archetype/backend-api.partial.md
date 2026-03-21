## API Rules
- All endpoints must perform input validation at the entry point (Pydantic, zod, joi, etc.)
- Response format must maintain a consistent structure (unified success/error envelope)
- DB migrations must always use migration tools (Alembic, Prisma, TypeORM, etc.)
- Watch out for N+1 queries -- use eager loading or dataloader patterns with ORMs
- Authentication/authorization is handled in middleware; do not mix into business logic
- Security middleware is applied by default: rate limiting, CORS, helmet, etc.
- Health check endpoint is required (/health or /api/health)
- Testing: API integration tests + DB migration verification
