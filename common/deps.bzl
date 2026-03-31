# DEPRECATED: This file is for WORKSPACE mode only.
# New projects should use MODULE.bazel (Bzlmod) instead.
# These functions will be removed in a future release.

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_python():
    http_archive(
        name = "rules_python",
        sha256 = "4f7e2aa1eb9aa722d96498f5ef514f426c1f55161c3c9ae628c857a7128ceb07",
        strip_prefix = "rules_python-1.0.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.0.0/rules_python-1.0.0.tar.gz",
    )

def rules_pkg():
    git_repository(
        name = "rules_pkg",
        remote = "https://github.com/bazelbuild/rules_pkg",
        tag = "0.9.1",
    )

def rules_kotlin():
    http_archive(
        name = "io_bazel_rules_kotlin",
        urls = ["https://github.com/typedb/rules_kotlin/archive/c2519b00299cff9df22267e8359784e9948dba67.zip"],
        type = "zip",
        strip_prefix = "rules_kotlin-c2519b00299cff9df22267e8359784e9948dba67",
        sha256 = "1455f2ec4bf7ea12d2c90b0dfd6402553c3bb6cbc0271023e2e01ccdefb4a49a",
    )

def rules_jvm_external():
    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-6.6",
        sha256 = "3aadb9db3af0d7da2bd737d576f7e1c7db570ff99594bbd336a174e88e1c4bb2",
        url = "https://github.com/bazelbuild/rules_jvm_external/releases/download/6.6/rules_jvm_external-6.6.tar.gz",
    )

def rules_cc():
    http_archive(
        name = "rules_cc",
        urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.0.17/rules_cc-0.0.17.tar.gz"],
        sha256 = "abc605dd850f813bb37004b77db20106a19311a96b2da1c92b789da529d28fe1",
        strip_prefix = "rules_cc-0.0.17",
    )

def rules_rust():
    http_archive(
        name = "rules_rust",
        integrity = "sha256-8TBqrAsli3kN8BrZq8arsN8LZUFsdLTvJ/Sqsph4CmQ=",
        urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.56.0/rules_rust-0.56.0.tar.gz"],
    )
