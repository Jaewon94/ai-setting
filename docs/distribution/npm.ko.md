# npm 배포

## 범위

이 문서는 `ai-setting`을 npm에 배포하고 검증하는 방법을 다룹니다.

패키지 기준 정보:

- 패키지 이름: `@jaewon94/ai-setting`
- 현재 CLI 엔트리: `bin/ai-setting.js`
- 현재 `package.json` 버전: `1.1.8`
- 사용자 실행 형태: `npx @jaewon94/ai-setting ...`

## 기준 파일

- 패키지 메타데이터: [`package.json`](../../package.json)
- npm release workflow: [`.github/workflows/release.yml`](../../.github/workflows/release.yml)

## 배포 방식

release workflow는 tag 기반으로 동작합니다.

1. `package.json` 버전을 올린다.
2. release 커밋을 `main`에 반영한다.
3. `v*` 태그를 생성해서 push 한다.
4. GitHub Actions가 동일 버전이 npm에 없을 때만 publish 한다.
5. 같은 workflow가 GitHub Release도 만든다.

## 필요한 Secret

- `NPM_TOKEN`

`NPM_TOKEN`이 없으면 `.github/workflows/release.yml`이 publish 할 수 없습니다.

## 로컬 검증

태그 전 검증은 2단계로 나눕니다.

1. 변경 범위에 맞는 빠른 스위트만 먼저 실행
2. 마지막 게이트로 `./tests/run_all.sh`를 1회 실행

권장 빠른 검증:

```bash
./tests/test_hooks.sh
./tests/test_profiles.sh
./tests/test_basic.sh   # init/doctor/문구/템플릿 변경 시
```

최종 릴리스 검증:

```bash
./tests/run_all.sh
npm pack --dry-run
npx @jaewon94/ai-setting --help
```

가능하면 clean temp directory에서도 한 번 더 확인합니다.

```bash
mkdir -p /tmp/ai-setting-smoke
cd /tmp/ai-setting-smoke
npx @jaewon94/ai-setting --help
```

## 알려진 주의사항

- 저장소 루트에서는 로컬 패키지 컨텍스트 때문에 `npx @jaewon94/ai-setting --help` 동작이 clean directory와 다를 수 있습니다.
- `npm pack --dry-run`의 `EPERM`은 로컬 npm cache 권한 문제일 수 있습니다.
- Codex 샌드박스에서는 `~/.npm` 쓰기 제한 때문에 같은 `EPERM`이 오탐처럼 보일 수 있습니다.

## 배포 당일 기본 순서

```bash
./tests/test_hooks.sh
./tests/test_profiles.sh
./tests/test_basic.sh
./tests/run_all.sh
npm pack --dry-run
git log --oneline -5
git tag v1.1.8
git push origin v1.1.8
```

Windows + Git Bash에서는 `./tests/run_all.sh`가 오래 걸릴 수 있으므로, 작은 수정마다 반복 실행하지 말고 마지막 확인용으로만 사용합니다.

배포 후에는:

```bash
npm view @jaewon94/ai-setting version --userconfig=/dev/null
npx @jaewon94/ai-setting --help
```

## 트러블슈팅

### 버전이 이미 존재함

release workflow는 이미 존재하는 npm 버전을 건너뜁니다. publish가 skip 되면 `package.json` 버전을 올리고 새 태그를 다시 발행해야 합니다.

### pack 또는 view에서 EPERM 발생

먼저 로컬 npm cache 소유권과 권한을 확인합니다. 샌드박스 밖에서는 통과한다면 패키지 구성 문제가 아니라 환경 문제로 봅니다.

### tarball에 잘못된 파일이 포함됨

아래를 다시 실행합니다.

```bash
npm pack --dry-run
```

그 다음 [`package.json`](../../package.json)의 `files`, `bin`, 런타임 자산 구성을 확인합니다.
