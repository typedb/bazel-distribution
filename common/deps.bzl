load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def bazelbuild_rules_python():
    git_repository(
        name = "rules_python",
        remote = "https://github.com/bazelbuild/rules_python.git",
        tag = "0.0.2",
        patches = [
            # Force rules_python to export the requirements.bzl file in
            # order for stardoc to be able to load it during documentation
            # generation.
            "//:bazelbuild_rules_python-export-requirements-bzl-for-stardoc.patch",
        ],
        patch_args = ["-p1"],
    )

def bazelbuild_rules_pkg():
    http_archive(
        name = "rules_pkg",
        urls = [
            "https://github.com/bazelbuild/rules_pkg/releases/download/0.2.5/rules_pkg-0.2.5.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.2.5/rules_pkg-0.2.5.tar.gz",
        ],
        sha256 = "352c090cc3d3f9a6b4e676cf42a6047c16824959b438895a76c2989c6d7c246a",
    )
