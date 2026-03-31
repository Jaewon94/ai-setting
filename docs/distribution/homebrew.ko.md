# Homebrew 배포

## 범위

이 문서는 `ai-setting`을 Homebrew tap으로 배포하고 운영하는 방법을 다룹니다.

채널 기준 정보:

- tap 저장소: `Jaewon94/homebrew-ai-setting`
- 설치 명령: `brew install Jaewon94/ai-setting/ai-setting`
- 이 저장소의 formula 원본: [`Formula/ai-setting.rb`](../../Formula/ai-setting.rb)
- formula 생성 스크립트: [`scripts/render-homebrew-formula.sh`](../../scripts/render-homebrew-formula.sh)

## 기준 파일

- Homebrew workflow: [`.github/workflows/homebrew.yml`](../../.github/workflows/homebrew.yml)
- tap formula 템플릿 원본: [`Formula/ai-setting.rb`](../../Formula/ai-setting.rb)
- release 체크리스트: [../deployment-checklist.md](../deployment-checklist.md)

## 반영 방식

Homebrew 경로는 tag 기반으로 자동 반영되고, 필요하면 수동 복구도 가능합니다.

1. `v*` 태그가 `.github/workflows/homebrew.yml`을 트리거한다.
2. workflow가 해당 태그의 GitHub tarball을 내려받는다.
3. tarball의 `sha256`을 계산한다.
4. 새 `Formula/ai-setting.rb`를 렌더링한다.
5. 그 formula를 `Jaewon94/homebrew-ai-setting`에 push 한다.

필요하면 `workflow_dispatch`로 수동 실행도 가능합니다.

## 필요한 GitHub 설정

Repository variable:

- `HOMEBREW_TAP_REPO=Jaewon94/homebrew-ai-setting`

Repository secret:

- `HOMEBREW_TAP_GH_TOKEN`

이 값들이 없으면 Homebrew workflow가 tap 저장소를 갱신할 수 없습니다.

## Formula 메모

formula는 저장소 전체를 `libexec` 아래에 설치한 뒤, `bin/ai-setting.js`를 `ai-setting` 이름으로 노출합니다.

아직 태그되지 않은 릴리스 후보 단계에서는 [`Formula/ai-setting.rb`](../../Formula/ai-setting.rb)가 마지막으로 배포된 태그를 계속 가리킬 수 있습니다. 새 release tarball 기준 formula 갱신은 Homebrew workflow가 담당합니다.

현재 install 로직:

```ruby
def install
  libexec.install Dir["*"]
  chmod 0555, libexec/"bin/ai-setting.js"
  bin.install_symlink libexec/"bin/ai-setting.js" => "ai-setting"
end
```

이 방식은 `/opt/homebrew/init.sh`를 잘못 찾던 shell wrapper 경로 문제를 피하기 위한 것입니다.

## 로컬 검증

권장 검증 명령:

```bash
brew uninstall ai-setting
brew install Jaewon94/ai-setting/ai-setting
ai-setting --help
brew test Jaewon94/ai-setting/ai-setting
```

2026-03-25 기준으로 설치와 `brew test` 모두 성공 확인했습니다.

## 수동 복구 절차

workflow가 tap을 잘못 갱신하거나 반영하지 못했을 때는:

1. release tarball의 `sha256`을 다시 계산한다.
2. [`scripts/render-homebrew-formula.sh`](../../scripts/render-homebrew-formula.sh)로 formula를 다시 생성한다.
3. 갱신된 formula를 `Jaewon94/homebrew-ai-setting`에 커밋/푸시한다.
4. 로컬에서 Homebrew 재설치 후 `ai-setting --help`를 다시 확인한다.

## 트러블슈팅

### 설치된 명령이 잘못된 파일을 가리킴

Homebrew formula가 shell wrapper `bin/ai-setting`을 직접 가리키면 안 됩니다. Homebrew layout에서는 wrapper가 repo root를 잘못 계산할 수 있습니다. 이 프로젝트는 `bin/ai-setting.js`를 `ai-setting` 이름으로 노출해야 합니다.

### formula가 잘못된 실행 파일 이름을 만듦

이 프로젝트에서는 `bin.install_symlink libexec/"bin/ai-setting.js" => "ai-setting"`를 유지하는 편이 안전합니다. 이전 `write_exec_script` 시도는 이 명령 이름에서 잘못된 결과 레이아웃을 만들었습니다.

### tap update workflow가 아무 것도 안 함

먼저 아래를 확인합니다.

- `HOMEBREW_TAP_REPO` variable 존재 여부
- `HOMEBREW_TAP_GH_TOKEN` secret 존재 여부
- 태그가 의도한 release 버전을 가리키는지
- 생성된 formula diff가 실제로 있는지
