load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def deps():
    http_archive(
        name = "rules_jvm_external",
        strip_prefix = "rules_jvm_external-3.2",
        sha256 = "82262ff4223c5fda6fb7ff8bd63db8131b51b413d26eb49e3131037e79e324af",
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/3.2.zip",
    )
    http_archive(
        name = "io_bazel_rules_kotlin",
        urls = ["https://github.com/bazelbuild/rules_kotlin/archive/legacy-1.3.0.zip"],
        type = "zip",
        strip_prefix = "rules_kotlin-legacy-1.3.0",
        sha256 = "4fd769fb0db5d3c6240df8a9500515775101964eebdf85a3f9f0511130885fde",
    )

maven_artifacts = [
  "com.eclipsesource.minimal-json:minimal-json",
  "info.picocli:picocli",
]

maven_artifacts_with_versions = [
    "com.eclipsesource.minimal-json:minimal-json:0.9.5",
    "info.picocli:picocli:4.3.2",
]
