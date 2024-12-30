load("@rules_python//python:pip.bzl", "pip_parse")

def typedb_bazel_distribution_uploader(python_interpreter_target):
    pip_parse(
        name = "typedb_bazel_distribution_uploader",
        requirements_lock = "@typedb_bazel_distribution//common/uploader:requirements.txt",
        python_interpreter_target = python_interpreter_target
    )
