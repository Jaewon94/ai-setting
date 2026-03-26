---
name: document-security
description: 보안 관련 구현과 운영 규칙을 문서화
disable-model-invocation: true
---
다음 보안 주제를 문서화합니다: $ARGUMENTS

출력 위치:
- `docs/security/<slug>/`

최소 문서 구조:
1. `README.md`
- 어떤 위협/경계를 다루는지
- 적용 범위와 제외 범위

2. `decisions.md`
- 왜 이 보안 방식/정책을 택했는지
- 남아 있는 리스크와 수용한 제약

3. `implementation.md`
- 인증, 인가, 검증, 미들웨어, 저장 방식
- 실제 코드와 설정이 연결되는 지점

4. `operations.md`
- 키/인증서/정책 갱신
- 사고 대응과 점검 절차
- 로그/모니터링에서 봐야 할 항목

원칙:
- 막연한 보안 권고 대신 현재 구현/운영 기준으로 쓴다
- 민감 정보는 직접 적지 말고 관리 위치와 절차만 적는다
- 위험은 숨기지 말고 남은 리스크를 분리해 적는다
