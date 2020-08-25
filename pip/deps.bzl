load("@rules_python//python:pip.bzl", "pip_import")

def graknlabs_bazel_distribution_ci_pip():
    pip_import(
        name = "graknlabs_bazel_distribution_pip",
        requirements = "//pip:requirements.txt",
    )
