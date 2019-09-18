load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def bazelbuild_rules_pkg():
    http_archive(
        name = "rules_pkg",
        url = "https://github.com/bazelbuild/rules_pkg/releases/download/0.2.2/rules_pkg-0.2.2.tar.gz",
        sha256 = "02de387c5ef874379e784ac968bf6efffe5285a168cab5a3169e08cfc634fd22",
    )
