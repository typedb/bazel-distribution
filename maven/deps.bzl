load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

maven_artifacts = [
  "com.eclipsesource.minimal-json:minimal-json",
  "info.picocli:picocli",
]

maven_artifacts_with_versions = [
    "com.eclipsesource.minimal-json:minimal-json:0.9.5",
    "info.picocli:picocli:4.3.2",
]
