load("@rules_python//python:pip.bzl", "pip_install")

def deps():
    pip_install(
        name = "vaticle_bazel_distribution_pip",
        requirements = "@vaticle_bazel_distribution//pip:requirements.txt",
    )
