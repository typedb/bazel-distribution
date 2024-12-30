load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")
load("@rules_python//python:pip.bzl", "pip_parse")
load("//common:rules.bzl", "python_interpreter_symlink")


def typedb_bazel_distribution_uploader():
    uploader_toolchain_name = "py39_for_uploader"
    python_register_toolchains(name=uploader_toolchain_name, python_version="3.9", ignore_root_user_error = True)
    python_interpreter_symlink(name="py39_for_uploader_symlink", interpreter_toolchain_name = uploader_toolchain_name)
    pip_parse(
        name = "typedb_bazel_distribution_uploader",
        requirements_lock = "@typedb_bazel_distribution//common/uploader:requirements.txt",
        python_interpreter_target = "@py39_for_uploader_symlink//:python"
    )
