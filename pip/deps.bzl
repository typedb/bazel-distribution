# DEPRECATED: This file is for WORKSPACE mode only.
# New projects should use MODULE.bazel (Bzlmod) instead.

load("@rules_python//python:pip.bzl", "pip_parse")

def typedb_bazel_distribution_pip():
    pip_parse(
        name = "typedb_bazel_distribution_pip",
        requirements_lock = "@typedb_bazel_distribution//pip:requirements.txt",
    )
