load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

maven_artifacts = [
  "com.eclipsesource.minimal-json:minimal-json",
  "info.picocli:picocli",
  "org.apache.commons:commons-compress",
  "com.fasterxml.jackson.core:jackson-databind",
  "com.fasterxml.jackson.dataformat:jackson-dataformat-toml",
  "com.google.http-client:google-http-client",
]

maven_artifacts_with_versions = [
    "com.eclipsesource.minimal-json:minimal-json:0.9.5",
    "info.picocli:picocli:4.3.2",
    "org.apache.commons:commons-compress:1.21",
    "com.fasterxml.jackson.core:jackson-databind:2.13.0",
    "com.fasterxml.jackson.dataformat:jackson-dataformat-toml:2.13.0",
    "com.google.http-client:google-http-client:1.34.2",
]
