load("@rules_python//python:pip.bzl", "pip_install")

def deps():
    pip_install(
        name = "graknlabs_bazel_distribution_pip",
        requirements = "@graknlabs_bazel_distribution//pip:requirements.txt",
    )
