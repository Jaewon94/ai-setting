class AiSetting < Formula
  desc "Bootstrap Claude Code, Codex, Cursor, Gemini CLI, and Copilot project settings"
  homepage "https://github.com/Jaewon94/ai-setting"
  url "https://github.com/Jaewon94/ai-setting/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "0a226c31b9cd532f216f25da2c65fed16f9e1cdb0caae9539adbc67a133bcdf2"
  license "MIT"

  depends_on "jq" => :recommended

  def install
    libexec.install Dir["*"]
    chmod 0555, libexec/"bin/ai-setting.js"
    bin.install_symlink libexec/"bin/ai-setting.js" => "ai-setting"
  end

  test do
    tmpdir = testpath/"test-project"
    tmpdir.mkpath
    system bin/"ai-setting", "--skip-ai", "--dry-run", tmpdir
  end
end
