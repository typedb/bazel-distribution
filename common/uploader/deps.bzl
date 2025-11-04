load("@rules_python//python:pip.bzl", "pip_parse")

def typedb_bazel_distribution_uploader(toolchain_name = None):
    # uploader_toolchain_name is whatever the name passed to python_register_toolchains
    python_interpreter_target = "@" + toolchain_name + "_host//:python" if toolchain_name else None
    pip_parse(
        name = "typedb_bazel_distribution_uploader",
        requirements_lock = "@typedb_bazel_distribution//common/uploader:requirements.txt",
        python_interpreter_target = python_interpreter_target
    )
