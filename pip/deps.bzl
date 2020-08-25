load("@rules_python//python:pip.bzl", "pip_import")

def deps():
    pip_import(
        name = "graknlabs_bazel_distribution_pip",
        requirements = "@graknlabs_bazel_distribution//pip:requirements.txt",
    )
