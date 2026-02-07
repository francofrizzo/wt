class Wt < Formula
  desc "Git worktree manager with GitHub PR and CI status integration"
  homepage "https://github.com/OWNER/wt"
  url "https://github.com/OWNER/wt/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  depends_on "jq"
  depends_on "gh"

  def install
    bin.install "bin/wt"
    zsh_completion.install "completions/_wt"
    (share/"wt").install "functions/wt.zsh"
  end

  def caveats
    <<~EOS
      To enable the cd-into-worktree shell wrapper and completions,
      add this to your ~/.zshrc:

        source "$(brew --prefix)/share/wt/wt.zsh"

      Then configure your first repo:

        wt init myproject --bare ~/code/myproject.git
    EOS
  end
end
