class AiSetting < Formula
  desc "Bootstrap Claude Code, Codex, Cursor, Gemini CLI, and Copilot project settings"
  homepage "https://github.com/Jaewon94/ai-setting"
  url "https://github.com/Jaewon94/ai-setting/archive/refs/tags/v1.1.8.tar.gz"
  sha256 "da1bee479d0cb3a7dbaf9537f86aa3887e86bcfa3145e9f0f9be0e13e9798788"
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
