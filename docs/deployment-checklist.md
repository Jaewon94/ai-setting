# Phase 10: 실제 배포 체크리스트

**기준일**: 2026-03-20  
**대상 버전**: `v1.0.0`  
**상태**: npm 배포 완료, release/brew 후속 진행 중

---

## 목적

이 문서는 ai-setting을 외부 사용자나 팀에 실제 배포할 때 필요한 순서와 점검 항목을 한 번에 확인하기 위한 체크리스트입니다.

배포 채널:

- npm (`npx @jaewon94/ai-setting ...`)
- GitHub 공개 저장소
- Homebrew tap
- GitHub Release workflow

---

## 현재 준비 상태

| 항목 | 상태 | 근거 |
|------|------|------|
| CLI 엔트리 | ✅ 준비됨 | `bin/ai-setting`, `package.json#bin` |
| npm 메타데이터 | ✅ 준비됨 | `package.json` |
| 테스트 스위트 | ✅ 준비됨 | `./tests/run_all.sh` |
| CI workflow | ✅ 준비됨 | `.github/workflows/ci.yml` |
| release workflow | ✅ 준비됨 | `.github/workflows/release.yml` |
| Homebrew formula 초안 | ✅ 준비됨 | `Formula/ai-setting.rb` |
| LICENSE / SECURITY / 이슈 템플릿 | ✅ 준비됨 | 루트 및 `.github/ISSUE_TEMPLATE/` |
| 공개 저장소 전환 | ✅ 완료 | GitHub public 확인 |
| npm publish | ✅ 완료 | `@jaewon94/ai-setting@1.0.0` publish 완료 |
| brew tap 등록 | ⏳ 미실행 | 별도 tap repo + GitHub 변수/secret 필요 |

---

## 배포 전 최종 점검

- [x] `./tests/run_all.sh` 통과 확인
- [x] `npm pack --dry-run` 결과 확인
- [x] 로컬 npm cache 권한 상태 확인 (`~/.npm`에 root-owned file이 없는지)
- [x] `package.json` 버전 확인
- [x] `README.md`의 빠른 시작/옵션/지원 도구 설명 최신 상태 확인
- [x] `docs/roadmap.md`, `docs/issues.md` 상태 최신화 확인
- [x] 최근 field test 문서 확인
  - `docs/field-test-kobot.md`
  - `docs/field-test-research-traceability.md`
  - `docs/field-test-ai-autofill.md`
  - `docs/field-test-python-backend.md`
- [x] release 대상 커밋이 `main`에 반영됐는지 확인

권장 검증 명령:

```bash
./tests/run_all.sh
npm pack --dry-run
git log --oneline -5
```

---

## 1. GitHub 공개 전환

목적:
- npm, Homebrew, 외부 문서 링크가 실제 사용자 기준으로 동작하게 만듦

실행 항목:

- [x] GitHub 저장소를 `public`으로 전환
- [ ] Issues / Discussions / Releases 정책 확인
- [x] 기본 브랜치가 `main`인지 확인
- [ ] repository description / topics 정리

확인 포인트:

- [x] `https://github.com/Jaewon94/ai-setting` 공개 접근 가능
- [x] README 렌더링 정상
- [x] `LICENSE`, `SECURITY.md`, issue templates 노출 확인

---

## 2. npm 배포

목적:
- 사용자가 `npx @jaewon94/ai-setting ...`로 바로 사용할 수 있게 함

실행 순서:

```bash
npm login
npm pack --dry-run
npm publish --access public
```

체크리스트:

- [x] npm 계정 로그인 완료
- [x] 패키지 이름 `@jaewon94/ai-setting` 확인
- [x] `npm pack --dry-run`에 불필요 파일이 포함되지 않는지 확인
- [x] 로컬 npm cache 권한 문제가 없는지 확인
- [x] `npm publish --access public` 성공

문제 대응 메모:

- `npm pack --dry-run`에서 `EPERM`과 함께 `~/.npm` cache 권한 오류가 나오면 패키지 구성 문제가 아니라 로컬 환경 문제일 수 있음
- 이 경우 npm cache 권한을 정리한 뒤 다시 `npm pack --dry-run`을 실행해야 함

배포 후 검증:

```bash
npx @jaewon94/ai-setting --help
```

확인 포인트:

- [ ] `npx @jaewon94/ai-setting --help` 정상 출력
- [ ] README / homepage / repository 링크 정상
- [x] 패키지 버전이 `1.0.0`으로 노출됨 (`npm view ... --userconfig=/dev/null`)

---

## 3. GitHub Release

목적:
- 릴리스 노트와 다운로드 지점을 명확히 제공

실행 순서:

```bash
git tag v1.0.0
git push origin v1.0.0
```

체크리스트:

- [x] 태그가 `package.json` 버전과 일치
- [x] GitHub repository secret `NPM_TOKEN` 준비
- [x] `.github/workflows/release.yml`이 동작할 조건 충족
- [ ] GitHub Release 페이지에 자동 릴리스 노트 생성 확인

확인 포인트:

- [ ] Release가 생성됨
- [ ] 릴리스 노트가 최신 기능 반영
- [ ] npm publish 단계가 의도대로 실행됨

---

## 4. Homebrew 배포

목적:
- macOS 사용자에게 `brew install` 경로 제공

사전 조건:

- [ ] 별도 tap 저장소 생성 (`homebrew-ai-setting` 등)
- [ ] repository variable `HOMEBREW_TAP_REPO` 설정
- [ ] repository secret `HOMEBREW_TAP_GH_TOKEN` 설정
- [ ] 공개 저장소 전환 완료
- [ ] 첫 release tarball URL 확정

실행 항목:

- [x] 자동 formula 생성 스크립트 준비 (`scripts/render-homebrew-formula.sh`)
- [x] Homebrew workflow 준비 (`.github/workflows/homebrew.yml`)
- [ ] tap 저장소에 formula 배치

검증 예시:

```bash
brew install <tap>/ai-setting
ai-setting --help
```

확인 포인트:

- [ ] brew install 성공
- [ ] 설치 후 `ai-setting --help` 정상 출력

---

## 5. 배포 후 확인

- [ ] `npx @jaewon94/ai-setting --help` 확인
- [ ] `brew install` 경로 확인
- [ ] GitHub README에 설치 방법 업데이트
- [ ] 필요 시 `docs/roadmap.md`에서 Phase 10 완료 처리
- [ ] 필요 시 `docs/issues.md` 또는 별도 release note에 배포 날짜 기록

---

## 권장 실행 순서

1. `./tests/run_all.sh`
2. `npm pack --dry-run`
3. npm cache 권한/패키지 이름/NPM_TOKEN 확인
4. GitHub 저장소 public 전환
5. `npm publish --access public`
6. `git tag v1.0.0 && git push origin v1.0.0`
7. Homebrew tap 정리 및 formula 반영
8. `docs/roadmap.md`의 Phase 10 상태 업데이트

---

## 보류 기준

아래 중 하나라도 해당하면 Phase 10은 보류해도 됩니다.

- 아직 외부 공개 계획이 없음
- 패키지 이름 충돌 가능성을 먼저 확인해야 함
- Homebrew tap 운영까지는 아직 필요 없음
- 실전 프로젝트 field test를 한두 개 더 보고 싶음

이 경우 현재 상태는 "npm 배포 완료, release/brew 후속만 남음"으로 유지하면 됩니다.
