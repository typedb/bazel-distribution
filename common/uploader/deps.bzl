load("@rules_python//python:pip.bzl", "pip_parse")

def pip_uploader(python_interpreter_target = None):
    # Optionally specify the python interpreter to use instead of
    # e.g. @<toolchain_name>_host//:python
    pip_parse(
        name = "pip_uploader",
        requirements_lock = "@typedb_bazel_distribution//common/uploader:requirements.txt",
        python_interpreter_target = python_interpreter_target
    )
