#!/bin/bash
# lib/deps.sh — dependency checks and optional installers

detect_jq_available() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "$HOME/jq.exe" ]; then
    return 0
  fi
  if [ -f "/usr/local/bin/jq" ]; then
    return 0
  fi
  return 1
}

prompt_jq_install() {
  if [ ! -t 0 ] || [ "$DRY_RUN" = true ]; then
    return 1
  fi

  printf "$MSG_INIT_JQ_PROMPT"
  read -r answer </dev/tty 2>/dev/null || answer="n"
  case "$answer" in
    [yY]*) return 0 ;;
    *) return 1 ;;
  esac
}

try_install_jq() {
  case "$(uname -s)" in
    Darwin*)
      echo -e "$MSG_INIT_JQ_INSTALLING_BREW"
      if command -v brew >/dev/null 2>&1; then
        brew install jq 2>/dev/null
      else
        echo -e "${RED}$MSG_INIT_JQ_NO_BREW${NC}"
        return 1
      fi
      ;;
    Linux*)
      echo -e "$MSG_INIT_JQ_INSTALLING_APT"
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y jq 2>/dev/null
      elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y jq 2>/dev/null
      else
        echo -e "${RED}$MSG_INIT_JQ_NO_PKG${NC}"
        return 1
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo -e "$MSG_INIT_JQ_INSTALLING_WIN"
      if curl -sL -o "$HOME/jq.exe" "https://github.com/jqlang/jq/releases/latest/download/jq-windows-amd64.exe" 2>/dev/null; then
        chmod +x "$HOME/jq.exe" 2>/dev/null || true
      else
        echo -e "${RED}$MSG_INIT_JQ_DOWNLOAD_FAIL${NC}"
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac

  detect_jq_available
}

ensure_jq_dependency() {
  if detect_jq_available; then
    JQ_AVAILABLE=true
    return 0
  fi

  JQ_AVAILABLE=false
  echo -e "${YELLOW}${MSG_INIT_JQ_WARN}${NC}"
  echo -e "$MSG_INIT_JQ_DETAIL"

  if prompt_jq_install; then
    if try_install_jq; then
      JQ_AVAILABLE=true
      echo -e "${GREEN}$MSG_INIT_JQ_INSTALLED${NC}"
    fi
  else
    echo -e "$MSG_INIT_JQ_INSTALL"
  fi

  echo ""
}
