load("@rules_python//python:pip.bzl", "pip_parse")

def deps():
    pip_parse(
        name = "vaticle_bazel_distribution_cloudsmith",
        requirements_lock = "@vaticle_bazel_distribution//common/cloudsmith:requirements.txt",
    )
