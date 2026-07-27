load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library")

kt_jvm_library(
    name = "macsigning-lib",
    srcs = glob(["*.kt"]),
    deps = [
        "@typedb_bazel_distribution//common",
        "@typedb_bazel_distribution//common/shell",
        "@bazel_distribution_maven//:info_picocli_picocli",
    ],
    visibility = ["//visibility:public"],
)

java_binary(
    name = "macsigning-bin",
    runtime_deps = [":macsigning-lib"],
    main_class = "com.typedb.bazel.distribution.common.macsigning.MainKt",
    visibility = ["//visibility:public"],
)

exports_files([
    "default_entitlements.plist",
    "distribution_template.xml",
])
