## Backend Agent Rules
- 요청 검증, 비즈니스 로직, 저장소 접근을 분리하고 API 계약을 호환성 경계로 취급한다.
- 인증/인가, rate limiting, health check, migration 같은 운영 기본값을 빠뜨리지 않는다.
- 데이터 흐름이나 스키마가 바뀌면 테스트, fixture, 운영 메모까지 같이 확인한다.
- 실패/재시도/멱등성이 중요한 작업은 정상 경로와 에러 경로를 함께 설계한다.
