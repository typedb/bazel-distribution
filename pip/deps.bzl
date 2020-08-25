load("@rules_python//python:pip.bzl", "pip_import")

def deps():
    pip_import(
        name = "graknlabs_bazel_distribution_pip",
        requirements = "//pip:requirements.txt",
    )
