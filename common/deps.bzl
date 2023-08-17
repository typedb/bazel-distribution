load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_python():
    git_repository(
        name = "rules_python",
        remote = "https://github.com/bazelbuild/rules_python.git",
        tag = "0.24.0",
    )

def rules_pkg():
    http_archive(
        name = "rules_pkg",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.4.0/rules_pkg-0.4.0.tar.gz",
            "https://github.com/bazelbuild/rules_pkg/releases/download/0.4.0/rules_pkg-0.4.0.tar.gz",
        ],
        sha256 = "038f1caa773a7e35b3663865ffb003169c6a71dc995e39bf4815792f385d837d",
        patches = [
            "@vaticle_bazel_distribution//:bazelbuild_rules_pkg-allow-long-filenames.patch",
        ],
        patch_args = ["-p1"],
    )

def rules_kotlin():
    http_archive(
        name = "io_bazel_rules_kotlin",
        urls = ["https://github.com/vaticle/rules_kotlin/archive/c2519b00299cff9df22267e8359784e9948dba67.zip"],
        type = "zip",
        strip_prefix = "rules_kotlin-c2519b00299cff9df22267e8359784e9948dba67",
        sha256 = "1455f2ec4bf7ea12d2c90b0dfd6402553c3bb6cbc0271023e2e01ccdefb4a49a",
    )

def rules_jvm_external():
    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-3.2",
        sha256 = "82262ff4223c5fda6fb7ff8bd63db8131b51b413d26eb49e3131037e79e324af",
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/3.2.zip",
    )

def rules_rust():
    http_archive(
        name = "rules_rust",
        sha256 = "531bdd470728b61ce41cf7604dc4f9a115983e455d46ac1d0c1632f613ab9fc3",
        strip_prefix = "rules_rust-d8238877c0e552639d3e057aadd6bfcf37592408",
        urls = [
            "https://github.com/bazelbuild/rules_rust/archive/d8238877c0e552639d3e057aadd6bfcf37592408.tar.gz",
        ],
    )
