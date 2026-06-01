# DEPRECATED: This file is for WORKSPACE mode only.
# New projects should use MODULE.bazel (Bzlmod) instead.

load("@rules_python//python:pip.bzl", "pip_parse")

def pip_tdb():
    pip_parse(
        name = "pip_tdb",
        requirements_lock = "@typedb_bazel_distribution//pip:requirements.txt",
    )
