---
name: document-infra
description: 인프라 구성을 운영 문서로 구조화해 정리
disable-model-invocation: true
---
다음 인프라 주제를 문서화합니다: $ARGUMENTS

출력 위치:
- `docs/infrastructure/<slug>/`

최소 문서 구조:
1. `README.md`
- 이 인프라가 무엇인지
- 어떤 서비스/시스템을 받치는지
- 네트워크/배치 관점에서 큰 그림

2. `decisions.md`
- 왜 이 구성 요소와 토폴로지를 택했는지
- 운영 제약과 대안

3. `configuration.md`
- 포트, 볼륨, 환경변수, 의존 서비스
- 실제 반영 위치와 설정 파일 경로

4. `operations.md`
- 배포/재시작/롤백/모니터링/장애 대응
- 운영 중 자주 확인할 명령과 체크포인트

원칙:
- 실제 compose, workflow, infra config와 맞는 내용만 기록
- 민감값은 적지 말고 위치/주입 방식만 설명
- 변경 빈도가 높은 설정은 운영 문서와 연결
