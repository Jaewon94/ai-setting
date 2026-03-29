# Distribution 문서

`ai-setting`을 외부 배포 채널로 운영할 때 참고하는 문서 모음입니다.

이 문서는 아래 상황에서 사용합니다.

- npm 버전을 새로 publish할 때
- Homebrew tap을 갱신하거나 문제를 추적할 때
- tag 이후 배포 채널 검증을 다시 할 때

문서:

- [npm.ko.md](npm.ko.md): 패키지 메타데이터, publish 흐름, 검증, 주의사항
- [homebrew.ko.md](homebrew.ko.md): tap 저장소 설정, formula 생성, 검증, 트러블슈팅
- [../deployment-checklist.md](../deployment-checklist.md): GitHub, npm, Homebrew 전체 체크리스트

권장 순서:

1. 먼저 [../deployment-checklist.md](../deployment-checklist.md)로 현재 릴리스 체크 항목을 본다.
2. npm 작업은 [npm.ko.md](npm.ko.md)를 본다.
3. Homebrew 작업은 [homebrew.ko.md](homebrew.ko.md)를 본다.

검증 원칙:
- 먼저 변경 범위에 맞는 가장 작은 테스트 스위트를 실행
- `./tests/run_all.sh`는 최종 릴리스 게이트에서 1회만 실행
