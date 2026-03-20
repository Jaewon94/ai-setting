#!/bin/bash
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
  echo "usage: $0 <version> <sha256> [output_path] [repo]" >&2
  exit 1
fi

version="$1"
sha256_value="$2"
output_path="${3:-Formula/ai-setting.rb}"
repo="${4:-Jaewon94/ai-setting}"

cat > "$output_path" <<EOF
class AiSetting < Formula
  desc "Bootstrap Claude Code, Codex, Cursor, Gemini CLI, and Copilot project settings"
  homepage "https://github.com/${repo}"
  url "https://github.com/${repo}/archive/refs/tags/${version}.tar.gz"
  sha256 "${sha256_value}"
  license "MIT"

  depends_on "jq" => :recommended

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/ai-setting"
  end

  test do
    tmpdir = testpath/"test-project"
    tmpdir.mkpath
    system bin/"ai-setting", "--skip-ai", "--dry-run", tmpdir
  end
end
EOF
