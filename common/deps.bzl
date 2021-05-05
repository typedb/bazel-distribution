load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_python():
    git_repository(
        name = "rules_python",
        remote = "https://github.com/bazelbuild/rules_python.git",
        tag = "0.1.0",
        patches = [
            # Force rules_python to export the requirements.bzl file in
            # order for stardoc to be able to load it during documentation
            # generation.
            "@graknlabs_bazel_distribution//:bazelbuild_rules_python-export-requirements-bzl-for-stardoc.patch",
        ],
        patch_args = ["-p1"],
    )

def rules_pkg():
    http_archive(
        name = "rules_pkg",
        urls = [
            "https://github.com/bazelbuild/rules_pkg/releases/download/0.2.5/rules_pkg-0.2.5.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.2.5/rules_pkg-0.2.5.tar.gz",
        ],
        sha256 = "352c090cc3d3f9a6b4e676cf42a6047c16824959b438895a76c2989c6d7c246a",
        patches = [
            "@graknlabs_bazel_distribution//:bazelbuild_rules_pkg-fix-tarfile-format.patch"
        ],
        patch_args = ["-p1"],
    )


def rules_kotlin():
    http_archive(
        name = "io_bazel_rules_kotlin",
        urls = ["https://github.com/bazelbuild/rules_kotlin/archive/legacy-1.3.0.zip"],
        type = "zip",
        strip_prefix = "rules_kotlin-legacy-1.3.0",
        sha256 = "4fd769fb0db5d3c6240df8a9500515775101964eebdf85a3f9f0511130885fde",
    )


def rules_jvm_external():
    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-3.2",
        sha256 = "82262ff4223c5fda6fb7ff8bd63db8131b51b413d26eb49e3131037e79e324af",
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/3.2.zip",
    )
