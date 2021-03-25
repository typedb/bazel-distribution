# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

exports_files(["rules.bzl"])

load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_jvm_library")

bzl_library(
    name = "lib",
    srcs = [
        "rules.bzl",
    ],
    visibility = ["//visibility:public"]
)

py_binary(
    name = "assemble",
    srcs = ["assemble.py"],
    visibility = ["//visibility:public"]
)

py_binary(
    name = "pom_replace_version",
    srcs = ["pom_replace_version.py"],
    visibility = ["//visibility:public"]
)


# FIXME(vmax): I couldn't make it a kt_jvm_binary because
#  it complained it couldn't find `java` executable
kt_jvm_library(
    name = "repackager-lib",
    srcs = ["Repackager.kt"],
)


kt_jvm_library(
    name = "pom-generator-lib",
    deps = [
      "@maven//:com_eclipsesource_minimal_json_minimal_json",
      "@maven//:info_picocli_picocli",
    ],
    srcs = [
        "PomGenerator.kt",
    ]
)

java_binary(
    name = "pom-generator",
    runtime_deps = [
        ":pom-generator-lib"
    ],
    main_class = "PomGeneratorKt",
    visibility = ["//visibility:public"]
)

java_binary(
    name = "repackager",
    runtime_deps = [
        ":repackager-lib"
    ],
    main_class = "RepackagerKt",
    visibility = ["//visibility:public"]
)


kt_jvm_library(
    name = "jar-assembler-lib",
    deps = [
      "@maven//:info_picocli_picocli",
    ],
    srcs = [
        "JarAssembler.kt"
    ]
)

java_binary(
    name = "jar-assembler",
    runtime_deps = [
        ":jar-assembler-lib"
    ],
    main_class = "JarAssemblerKt",
    visibility = ["//visibility:public"]
)
