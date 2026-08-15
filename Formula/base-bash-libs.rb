class BaseBashLibs < Formula
  desc "Reusable Bash libraries extracted from Base"
  homepage "https://github.com/basefoundry/base-bash-libs"
  url "https://github.com/basefoundry/base-bash-libs/releases/download/v2.0.0/base-bash-libs-v2.0.0.tar.gz"
  sha256 "73d6f92fab8f1a8ded7f3b4312ebbe51aa8ec0c16eacf18c2d8fa23fb5664333"
  license "Apache-2.0"
  head "https://github.com/basefoundry/base-bash-libs.git", branch: "main"

  bottle do
    root_url "https://github.com/basefoundry/homebrew-base/releases/download/base-v1.8.0"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "15da42f88a2b9887256ec3832102f6f578d1eba80b843a70b1f3e6181e240dc5"
    sha256 cellar: :any_skip_relocation, sequoia:       "615be38461944ec1d43f3d5814a9cf77ccb4b9b0eec8ba36f2e4b853eb6a3b47"
  end

  depends_on "bash"

  def install
    bin.install "bin/base-bash"
    libexec.install "lib"
    libexec.install "VERSION"
    pkgshare.install "docs"
  end

  def caveats
    <<~EOS
      Source the Bash stdlib with:
        source "#{opt_libexec}/lib/bash/std/lib_std.sh"

      Companion libraries live under:
        #{opt_libexec}/lib/bash

      Run standalone scripts with the stdlib preloaded:
        #!/usr/bin/env base-bash
    EOS
  end

  test do
    assert_path_exists libexec/"lib/bash/std/lib_std.sh"
    assert_path_exists libexec/"lib/bash/file/lib_file.sh"
    assert_path_exists libexec/"lib/bash/git/lib_git.sh"
    assert_path_exists libexec/"lib/bash/gh/lib_gh.sh"
    assert_path_exists bin/"base-bash"
    assert_path_exists pkgshare/"docs"

    (testpath/"smoke.sh").write <<~EOS
      source "#{libexec}/lib/bash/std/lib_std.sh"
      base_std_import file/lib_file.sh git/lib_git.sh gh/lib_gh.sh
      printf '%s\\n' "$BASE_BASH_LIBS_VERSION" "$(type -t base_std_run)" "$(type -t base_file_update_file_section)" "$(type -t base_git_get_current_branch)" "$(type -t base_gh_run)"
    EOS

    bash = formula_opt_bin("bash")/"bash"
    assert_equal "2.0.0\nfunction\nfunction\nfunction\nfunction\n", shell_output("#{bash} #{testpath}/smoke.sh")

    (testpath/"launcher.sh").write <<~EOS
      #!/usr/bin/env base-bash

      base_std_import str/lib_str.sh

      main() {
        local value="  launcher  "
        base_str_trim value
        printf '%s\\n' "$BASE_BASH_LIBS_VERSION" "$BASE_BASH_LIBS_STDLIB_LOADED" "$value" "$#"
      }
    EOS
    chmod 0755, testpath/"launcher.sh"

    assert_equal "2.0.0\n1\nlauncher\n1\n", shell_output("PATH=#{bin}:$PATH #{testpath}/launcher.sh arg")
  end
end
