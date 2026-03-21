## API 규칙
- 모든 엔드포인트는 입력 검증을 진입점에서 수행 (Pydantic, zod, joi 등)
- 응답 형식은 일관된 구조를 유지 (성공/에러 envelope 통일)
- DB 마이그레이션은 반드시 마이그레이션 도구 사용 (Alembic, Prisma, TypeORM 등)
- N+1 쿼리를 경계한다 — ORM 사용 시 eager loading 또는 dataloader 패턴
- 인증/인가는 미들웨어에서 처리, 비즈니스 로직에 섞지 않는다
- Rate limiting, CORS, 헬멧 등 보안 미들웨어는 기본 적용
- health check 엔드포인트 필수 (/health 또는 /api/health)
- 테스트: API 통합 테스트 + DB 마이그레이션 검증
