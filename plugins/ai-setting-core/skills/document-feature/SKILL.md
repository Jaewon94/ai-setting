---
name: document-feature
description: 기능 단위 문서를 구조화해 정리
disable-model-invocation: true
---
다음 기능을 문서화합니다: $ARGUMENTS

출력 위치:
- `docs/features/<slug>/`

최소 문서 구조:
1. `README.md`
- 이 기능이 무엇인지
- 어떤 사용자/상황에서 쓰는지
- 현재 범위와 비범위

2. `decisions.md`
- 왜 이런 구조/흐름을 택했는지
- 대안과 트레이드오프
- 관련 결정/제약

3. `architecture.md`
- 주요 흐름
- 관련 컴포넌트/모듈/경계
- 필요한 경우 시퀀스나 데이터 흐름

4. `guide.md`
- 구현/테스트/운영 시 확인할 것
- 주의할 에지 케이스
- 추후 변경 시 같이 봐야 할 파일/문서

원칙:
- README를 장문화하지 말고 주제별 폴더로 분리
- 실제 코드/문서와 맞지 않는 내용은 추정하지 말고 TODO로 남김
- 전역 문서(`docs/decisions.md`, `docs/research-notes.md`)와 역할이 겹치지 않게 작성
