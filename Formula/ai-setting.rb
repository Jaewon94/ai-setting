class AiSetting < Formula
  desc "Bootstrap Claude Code, Codex, Cursor, Gemini CLI, and Copilot project settings"
  homepage "https://github.com/Jaewon94/ai-setting"
  url "https://github.com/Jaewon94/ai-setting/archive/refs/tags/v1.0.0.tar.gz"
  # sha256 will be filled after the first release
  # sha256 ""
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
