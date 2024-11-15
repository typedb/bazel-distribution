load("@rules_python//python:pip.bzl", "pip_parse")

def typedb_bazel_distribution_uploader():
    pip_parse(
        name = "typedb_bazel_distribution_uploader",
        requirements_lock = "@typedb_bazel_distribution//common/uploader:requirements.txt",
    )
