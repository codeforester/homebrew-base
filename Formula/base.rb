class Base < Formula
  desc "Workspace bootstrap and project environment orchestration tool"
  homepage "https://github.com/basefoundry/base"
  url "https://github.com/basefoundry/base/archive/refs/tags/v1.8.0.tar.gz"
  sha256 "646e8b7f16fad42caf702ff5357a3c73e9bf35a8a607ae1538b6fb982db637e1"
  license "AGPL-3.0-or-later"
  head "https://github.com/basefoundry/base.git", branch: "main"

  bottle do
    root_url "https://github.com/basefoundry/homebrew-base/releases/download/base-v1.8.0"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "ffaeaf8840fd2eb4ac798ee247ea1c5a05e95c14e81bdcdfccdd3fd1790ba62c"
    sha256 cellar: :any_skip_relocation, sequoia:       "26975bd77fc6025a0e5fa9d15c2eba76d088d46a6f33970f82e9e3d1193aea55"
  end

  depends_on "base-bash-libs"
  depends_on "bash"
  depends_on "python@3.13"

  def install
    stable_base_home = opt_libexec

    inreplace "bin/basectl",
              /^basectl_base_home\(\) \{.*?^\}/m,
              <<~EOS
                basectl_base_home() {
                    printf '%s\\n' "#{stable_base_home}"
                }
              EOS

    inreplace "bin/base-wrapper",
              /^base_wrapper_base_home\(\) \{.*?^\}/m,
              <<~EOS
                base_wrapper_base_home() {
                    printf '%s\\n' "#{stable_base_home}"
                }
              EOS

    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/basectl"
    bin.install_symlink libexec/"bin/base-wrapper"
    bash_completion.install_symlink libexec/"lib/shell/completions/basectl_completion.sh" => "basectl"
    zsh_completion.install_symlink libexec/"lib/shell/completions/basectl_completion.zsh" => "_basectl"
  end

  def caveats
    <<~EOS
      Finish Base setup with:
        basectl setup
        basectl update-profile
        exec "$SHELL" -l

      When installed through Homebrew, update Base with:
        brew upgrade --no-ask basefoundry/base/base
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/basectl --version")
    assert_path_exists libexec/"lib/shell/completions/basectl_completion.sh"
    assert_path_exists libexec/"lib/shell/completions/basectl_completion.zsh"
    assert_path_exists bash_completion/"basectl"
    assert_path_exists zsh_completion/"_basectl"

    bash = formula_opt_bin("bash")/"bash"
    bash_libs_dir = formula_opt_libexec("base-bash-libs")/"lib/bash"
    assert_path_exists bash_libs_dir/"std/lib_std.sh"

    (testpath/"bash-libs-dir.sh").write <<~EOS
      BASE_HOME="#{libexec}"
      source "#{libexec}/base_init.sh"
      printf '%s\\n' "$BASE_BASH_LIBS_DIR"
    EOS

    assert_equal "#{bash_libs_dir}\n",
                 shell_output("env -u BASE_HOME -u BASE_BASH_LIBS_DIR #{bash} #{testpath}/bash-libs-dir.sh")
  end
end
