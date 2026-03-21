#!/bin/bash
# lib/detect.sh — 프로젝트 컨텍스트 모드, 스택, archetype 감지

set_project_mode_guidance() {
  case "$PROJECT_CONTEXT_MODE" in
    blank-start)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
blank-start 모드 지침:
- 프로젝트 근거가 거의 없으므로 확인 가능한 사실만 남겨.
- 스택, 실행 명령, 도메인 규칙은 추정해서 채우지 마.
- 자동 채우기보다 안전한 초기화가 우선이며, 실제 문서나 코드가 생긴 뒤 재실행을 전제로 안내해.
EOF
)
      ;;
    docs-first)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
docs-first 모드 지침:
- README, docs, spec, prd, requirements를 1차 근거로 사용해.
- 아직 구현되지 않은 내용은 TODO, 예정, 가정으로 명확히 표시해.
- 검증 가능한 코드/설정이 없는 내용은 단정하지 마.
EOF
)
      ;;
    hybrid)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
hybrid 모드 지침:
- 실제 코드, 설정, 테스트를 먼저 확인하고 문서는 설계 의도와 누락 보완용으로 사용해.
- 문서와 구현이 다르면 구현을 우선하되, 중요한 차이는 짧게 기록해.
- 문서와 구현을 섞어 쓰더라도 확인하지 못한 내용은 추정으로 표시해.
EOF
)
      ;;
    code-first)
      PROJECT_MODE_GUIDANCE=$(cat <<'EOF'
code-first 모드 지침:
- 실제 디렉토리 구조, 실행 명령, 테스트, 설정 파일을 1차 근거로 사용해.
- 문서가 코드와 다르면 코드를 우선하고, 충돌 내용은 짧게 드러내.
- 오래된 문서 표현을 그대로 옮기지 말고 현재 구현 상태에 맞게 다시 써.
EOF
)
      ;;
  esac
}

detect_project_stack() {
  local base="$1"
  local next_markers=("next.config.js" "next.config.mjs" "next.config.ts")
  local vite_markers=("vite.config.js" "vite.config.mjs" "vite.config.ts")

  if [ "$(count_existing_paths "$base" "${next_markers[@]}")" -ge 1 ]; then
    PROJECT_STACK="Next.js (TypeScript/JavaScript)"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "${next_markers[@]}")"
  elif [ "$(count_existing_paths "$base" "${vite_markers[@]}")" -ge 1 ]; then
    PROJECT_STACK="Vite (TypeScript/JavaScript)"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "${vite_markers[@]}")"
  elif [ -e "$base/package.json" ]; then
    if [ -e "$base/tsconfig.json" ]; then
      PROJECT_STACK="Node.js / TypeScript"
      PROJECT_STACK_SIGNALS="package.json, tsconfig.json"
    else
      PROJECT_STACK="Node.js / JavaScript"
      PROJECT_STACK_SIGNALS="package.json"
    fi
  elif [ -e "$base/pyproject.toml" ] || [ -e "$base/requirements.txt" ]; then
    PROJECT_STACK="Python"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "pyproject.toml" "requirements.txt")"
  elif [ -e "$base/go.mod" ]; then
    PROJECT_STACK="Go"
    PROJECT_STACK_SIGNALS="go.mod"
  elif [ -e "$base/Cargo.toml" ]; then
    PROJECT_STACK="Rust"
    PROJECT_STACK_SIGNALS="Cargo.toml"
  elif [ -e "$base/pom.xml" ] || [ -e "$base/build.gradle" ] || [ -e "$base/build.gradle.kts" ]; then
    PROJECT_STACK="Java / Kotlin"
    PROJECT_STACK_SIGNALS="$(join_existing_paths "$base" "pom.xml" "build.gradle" "build.gradle.kts")"
  elif [ -e "$base/Gemfile" ]; then
    PROJECT_STACK="Ruby"
    PROJECT_STACK_SIGNALS="Gemfile"
  elif [ -e "$base/composer.json" ]; then
    PROJECT_STACK="PHP"
    PROJECT_STACK_SIGNALS="composer.json"
  else
    PROJECT_STACK="$MSG_DETECT_STACK_UNKNOWN"
    PROJECT_STACK_SIGNALS="$MSG_DETECT_SIGNALS_NONE"
  fi
}

set_project_archetype_guidance() {
  case "$PROJECT_ARCHETYPE" in
    frontend-web)
      PROJECT_ARCHETYPE_GUIDANCE="프론트엔드 중심 프로젝트로 보고 브라우저 실행, 프론트 테스트, 번들링/개발 서버 명령을 우선 채워."
      ;;
    backend-api)
      PROJECT_ARCHETYPE_GUIDANCE="백엔드/API 중심 프로젝트로 보고 서버 실행, API 테스트, 마이그레이션/런타임 설정을 우선 채워."
      ;;
    cli-tool)
      PROJECT_ARCHETYPE_GUIDANCE="CLI 도구로 보고 설치/실행 예시, 엔트리포인트, 인자 처리와 관련된 명령/설명을 우선 채워."
      ;;
    worker-batch)
      PROJECT_ARCHETYPE_GUIDANCE="워커/배치 프로젝트로 보고 큐 소비, 스케줄러, 잡 실행 및 재시도 전략 관련 내용을 우선 반영해."
      ;;
    data-automation)
      PROJECT_ARCHETYPE_GUIDANCE="데이터/자동화 프로젝트로 보고 파이프라인 실행, 스크립트 진입점, 데이터 의존성과 재현성 관련 내용을 우선 반영해."
      ;;
    library-sdk)
      PROJECT_ARCHETYPE_GUIDANCE="라이브러리/SDK로 보고 공개 API, 사용 예시, 배포/버전 관리, 호환성 검증에 초점을 맞춰."
      ;;
    infra-iac)
      PROJECT_ARCHETYPE_GUIDANCE="인프라/IaC 프로젝트로 보고 plan/apply, 검증, 환경 분리, 배포 안전장치 관련 내용을 우선 반영해."
      ;;
    *)
      PROJECT_ARCHETYPE_GUIDANCE="일반 애플리케이션으로 보고 실제 코드 구조와 실행 명령을 우선 정리해."
      ;;
  esac
}

apply_user_hints() {
  HAS_USER_GUIDANCE=false

  PROJECT_NAME="${TARGET_BASENAME}"
  PROJECT_NAME_SOURCE="target directory"

  if [ -n "$USER_PROJECT_NAME_HINT" ]; then
    PROJECT_NAME="$USER_PROJECT_NAME_HINT"
    PROJECT_NAME_SOURCE="user hint"
    HAS_USER_GUIDANCE=true
  fi

  if [ -n "$USER_STACK_HINT" ]; then
    PROJECT_STACK="$USER_STACK_HINT"
    PROJECT_STACK_SIGNALS="user hint"
    HAS_USER_GUIDANCE=true
  fi

  if [ -n "$USER_ARCHETYPE_HINT" ]; then
    validate_archetype_hint "$USER_ARCHETYPE_HINT"
    PROJECT_ARCHETYPE="$USER_ARCHETYPE_HINT"
    PROJECT_ARCHETYPE_SIGNALS="user hint"
    PROJECT_ARCHETYPE_REASON="사용자 힌트로 지정됨"
    set_project_archetype_guidance
    HAS_USER_GUIDANCE=true
  fi
}

detect_project_archetype() {
  local base="$1"
  local frontend_markers=(
    "next.config.js"
    "next.config.mjs"
    "next.config.ts"
    "vite.config.js"
    "vite.config.mjs"
    "vite.config.ts"
    "src/app"
    "src/pages"
    "frontend/src"
  )
  local backend_markers=(
    "app/main.py"
    "manage.py"
    "main.go"
    "backend"
    "backend/app"
    "backend/src"
    "src/api"
    "app/api"
  )
  local cli_markers=("cmd" "bin" "cli" "cli.py" "cli.ts")
  local worker_markers=("worker" "workers" "jobs" "queue" "scheduler" "celery.py")
  local data_markers=("notebooks" "pipelines" "airflow" "dbt_project.yml" "scripts")
  local infra_markers=(
    "terraform"
    "ansible"
    "helm"
    "infra"
    "k8s"
    "docker-compose.yml"
    "docker-compose.yaml"
    "compose.yaml"
    "compose.yml"
    ".github/workflows"
  )
  local frontend_count
  local backend_count
  local cli_count
  local worker_count
  local data_count
  local infra_count

  frontend_count="$(count_existing_paths "$base" "${frontend_markers[@]}")"
  backend_count="$(count_existing_paths "$base" "${backend_markers[@]}")"
  cli_count="$(count_existing_paths "$base" "${cli_markers[@]}")"
  worker_count="$(count_existing_paths "$base" "${worker_markers[@]}")"
  data_count="$(count_existing_paths "$base" "${data_markers[@]}")"
  infra_count="$(count_existing_paths "$base" "${infra_markers[@]}")"

  if [ "$infra_count" -ge 2 ] && \
     [ "$frontend_count" -eq 0 ] && \
     [ "$backend_count" -eq 0 ] && \
     [ "$cli_count" -eq 0 ] && \
     [ "$worker_count" -eq 0 ] && \
     [ "$data_count" -eq 0 ]; then
    PROJECT_ARCHETYPE="infra-iac"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${infra_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="인프라/IaC 신호가 다수이고 앱 코드 신호가 거의 없음"
  elif [ "$frontend_count" -ge 2 ] || { [ "$frontend_count" -ge 1 ] && [ -e "$base/package.json" ]; }; then
    PROJECT_ARCHETYPE="frontend-web"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${frontend_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="웹 프론트엔드 구성 신호가 확인됨"
  elif [ "$worker_count" -ge 2 ] || { [ "$worker_count" -ge 1 ] && [ "$backend_count" -ge 1 ]; }; then
    PROJECT_ARCHETYPE="worker-batch"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${worker_markers[@]}" "${backend_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="워커/큐/잡 관련 신호가 백엔드 구조와 함께 확인됨"
  elif [ "$cli_count" -ge 1 ] && [ "$frontend_count" -eq 0 ]; then
    PROJECT_ARCHETYPE="cli-tool"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${cli_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="CLI 엔트리포인트 또는 실행용 디렉토리 신호가 확인됨"
  elif [ "$data_count" -ge 2 ] || { [ "$data_count" -ge 1 ] && [ "$PROJECT_STACK" = "Python" ]; }; then
    PROJECT_ARCHETYPE="data-automation"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${data_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="데이터 파이프라인/자동화 스크립트 관련 신호가 확인됨"
  elif [ -e "$base/examples" ] && [ -e "$base/src" ] && [ "$frontend_count" -eq 0 ] && [ "$backend_count" -eq 0 ] && [ "$cli_count" -eq 0 ] && [ "$worker_count" -eq 0 ] && [ "$data_count" -eq 0 ]; then
    PROJECT_ARCHETYPE="library-sdk"
    PROJECT_ARCHETYPE_SIGNALS="src, examples"
    PROJECT_ARCHETYPE_REASON="실행 앱보다 공개 API/예제 중심 구조로 보임"
  elif [ "$backend_count" -ge 1 ] || { [ "$PROJECT_CONTEXT_MODE" = "code-first" ] && [ "$PROJECT_STACK" != "$MSG_DETECT_STACK_UNKNOWN" ] && [ "$frontend_count" -eq 0 ]; }; then
    PROJECT_ARCHETYPE="backend-api"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${backend_markers[@]}")"
    if [ "$PROJECT_ARCHETYPE_SIGNALS" = "없음" ]; then
      PROJECT_ARCHETYPE_SIGNALS="$PROJECT_STACK_SIGNALS"
    fi
    PROJECT_ARCHETYPE_REASON="서버/API 실행 구조 또는 백엔드 중심 스택 신호가 확인됨"
  elif [ "$infra_count" -ge 1 ] && [ "$IMPLEMENTATION_SIGNAL_COUNT" -le 2 ]; then
    PROJECT_ARCHETYPE="infra-iac"
    PROJECT_ARCHETYPE_SIGNALS="$(join_existing_paths "$base" "${infra_markers[@]}")"
    PROJECT_ARCHETYPE_REASON="인프라 관련 구성은 있으나 애플리케이션 신호는 제한적임"
  else
    PROJECT_ARCHETYPE="general-app"
    PROJECT_ARCHETYPE_SIGNALS="없음"
    PROJECT_ARCHETYPE_REASON="지배적인 프로젝트 유형 신호가 부족해 일반 애플리케이션으로 처리"
  fi

  set_project_archetype_guidance
}

detect_project_context_mode() {
  local base="$1"
  local blank_start_markers=(
    "README.md"
    "spec"
    "specs"
    "prd"
    "requirements"
    "docs/architecture.md"
    "docs/requirements.md"
    "docs/product.md"
    "docs/specs"
    "docs/prd.md"
    "package.json"
    "pyproject.toml"
    "go.mod"
    "Cargo.toml"
    "pom.xml"
    "build.gradle"
    "build.gradle.kts"
    "requirements.txt"
    "Gemfile"
    "composer.json"
    "src"
    "app"
    "backend"
    "frontend"
    "server"
    "client"
    "cmd"
    "bin"
    "lib"
    "internal"
    "tests"
    "test"
    "__tests__"
    ".github/workflows"
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.yaml"
    "compose.yaml"
    "compose.yml"
    ".env.example"
    "deploy"
    "infra"
    "terraform"
    "ansible"
    "helm"
  )
  local doc_markers=(
    "README.md"
    "docs"
    "spec"
    "specs"
    "prd"
    "requirements"
    "docs/architecture.md"
    "docs/requirements.md"
    "docs/product.md"
  )
  local manifest_markers=(
    "package.json"
    "pyproject.toml"
    "go.mod"
    "Cargo.toml"
    "pom.xml"
    "build.gradle"
    "build.gradle.kts"
    "requirements.txt"
    "Gemfile"
    "composer.json"
  )
  local code_dir_markers=(
    "src"
    "app"
    "backend"
    "frontend"
    "server"
    "client"
    "cmd"
    "bin"
    "lib"
    "internal"
  )
  local test_markers=(
    "tests"
    "test"
    "__tests__"
    ".github/workflows"
  )
  local ops_markers=(
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.yaml"
    "compose.yaml"
    "compose.yml"
    ".env.example"
    ".github/workflows"
    "deploy"
    "infra"
    "terraform"
    "ansible"
    "helm"
  )
  local manifest_count
  local code_dir_count
  local blank_start_signal_count

  blank_start_signal_count="$(count_existing_paths "$base" "${blank_start_markers[@]}")"

  DOC_SIGNAL_COUNT="$(count_existing_paths "$base" "${doc_markers[@]}")"
  PROJECT_DOC_SIGNALS="$(join_existing_paths "$base" "${doc_markers[@]}")"

  manifest_count="$(count_existing_paths "$base" "${manifest_markers[@]}")"
  code_dir_count="$(count_existing_paths "$base" "${code_dir_markers[@]}")"
  IMPLEMENTATION_SIGNAL_COUNT=$((manifest_count + code_dir_count))
  PROJECT_IMPLEMENTATION_SIGNALS="$(join_existing_paths "$base" "${manifest_markers[@]}" "${code_dir_markers[@]}")"

  TEST_SIGNAL_COUNT="$(count_existing_paths "$base" "${test_markers[@]}")"
  PROJECT_TEST_SIGNALS="$(join_existing_paths "$base" "${test_markers[@]}")"

  OPS_SIGNAL_COUNT="$(count_existing_paths "$base" "${ops_markers[@]}")"
  PROJECT_OPS_SIGNALS="$(join_existing_paths "$base" "${ops_markers[@]}")"

  if [ "$blank_start_signal_count" -eq 0 ]; then
    PROJECT_CONTEXT_MODE="blank-start"
    PROJECT_CONTEXT_REASON="프로젝트 폴더에 의미 있는 문서/구현 신호가 거의 없음"
  elif [ "$IMPLEMENTATION_SIGNAL_COUNT" -le 1 ] && [ "$DOC_SIGNAL_COUNT" -ge 2 ]; then
    PROJECT_CONTEXT_MODE="docs-first"
    PROJECT_CONTEXT_REASON="문서 신호가 충분하고 실행 가능한 구현 신호가 적음"
  elif [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 4 ] || \
       { [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 3 ] && { [ "$TEST_SIGNAL_COUNT" -ge 1 ] || [ "$OPS_SIGNAL_COUNT" -ge 1 ]; }; } || \
       { [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 2 ] && [ "$DOC_SIGNAL_COUNT" -eq 0 ]; }; then
    PROJECT_CONTEXT_MODE="code-first"
    PROJECT_CONTEXT_REASON="코드/설정/테스트 신호가 풍부해 실제 구현을 우선 해석하는 편이 안전함"
  elif [ "$DOC_SIGNAL_COUNT" -ge 1 ] && [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 1 ]; then
    PROJECT_CONTEXT_MODE="hybrid"
    PROJECT_CONTEXT_REASON="문서와 구현 신호가 모두 있어 함께 해석하는 편이 적합함"
  elif [ "$IMPLEMENTATION_SIGNAL_COUNT" -ge 1 ]; then
    PROJECT_CONTEXT_MODE="code-first"
    PROJECT_CONTEXT_REASON="문서보다 구현 신호가 상대적으로 많음"
  else
    PROJECT_CONTEXT_MODE="docs-first"
    PROJECT_CONTEXT_REASON="확실한 구현 신호가 부족하므로 확인 가능한 사실만 채우는 편이 안전함"
  fi

  set_project_mode_guidance
}
