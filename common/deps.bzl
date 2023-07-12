load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_python():
    http_archive(
        name = "rules_python",
        sha256 = "84aec9e21cc56fbc7f1335035a71c850d1b9b5cc6ff497306f84cced9a769841",
        strip_prefix = "rules_python-0.23.1",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.23.1/rules_python-0.23.1.tar.gz",
    )

def rules_pkg():
    http_archive(
        name = "rules_pkg",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.9.1/rules_pkg-0.9.1.tar.gz",
            "https://github.com/bazelbuild/rules_pkg/releases/download/0.9.1/rules_pkg-0.9.1.tar.gz",
        ],
        sha256 = "8f9ee2dc10c1ae514ee599a8b42ed99fa262b757058f65ad3c384289ff70c4b8",
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
    RULES_JVM_EXTERNAL_TAG = "5.3"
    RULES_JVM_EXTERNAL_SHA ="d31e369b854322ca5098ea12c69d7175ded971435e55c18dd9dd5f29cc5249ac"

    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
        sha256 = RULES_JVM_EXTERNAL_SHA,
        url = "https://github.com/bazelbuild/rules_jvm_external/releases/download/%s/rules_jvm_external-%s.tar.gz" % (RULES_JVM_EXTERNAL_TAG, RULES_JVM_EXTERNAL_TAG)
    )

def rules_rust():
    http_archive(
        name = "rules_rust",
        sha256 = "aaaa4b9591a5dad8d8907ae2dbe6e0eb49e6314946ce4c7149241648e56a1277",
        urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.16.1/rules_rust-v0.16.1.tar.gz"],
    )
