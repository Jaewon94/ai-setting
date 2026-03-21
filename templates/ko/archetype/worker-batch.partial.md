## Worker/Batch 규칙
- 모든 작업은 멱등성을 보장한다 (같은 입력이면 재실행해도 같은 결과)
- 실패한 작업은 재시도 가능하도록 설계 (dead letter queue, retry 정책)
- 장시간 작업은 heartbeat/checkpoint를 남겨 진행 상태 추적 가능하게
- 리소스 정리: 임시 파일, DB 커넥션, 외부 세션은 반드시 finally/defer로 정리
- 동시성 제어: 같은 리소스에 대한 중복 실행 방지 (lock, unique constraint 등)
- 로깅: 작업 ID, 시작/종료 시간, 처리 건수를 구조화된 로그로 남긴다
- 테스트: 단일 작업 단위 테스트 + 실패/재시도 시나리오 테스트
