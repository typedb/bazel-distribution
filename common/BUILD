#
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

exports_files(["archiver.py"])

load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "lib",
    srcs = [
        "assemble_versioned.bzl",
        "checksum.bzl",
        "generate_json_config.bzl",
        "java_deps.bzl",
        "rules.bzl",
        "tgz2zip.bzl",
    ],
    visibility = ["//visibility:public"]
)

py_binary(
    name = "java_deps",
    srcs = ["java_deps.py"],
    visibility = ["//visibility:public"]
)

py_binary(
    name = "tgz2zip",
    srcs = ["tgz2zip.py"],
    visibility = ["//visibility:public"]
)

py_binary(
    name = "assemble-versioned",
    srcs = ["assemble-versioned.py"],
    deps = [":common"],
    visibility = ["//visibility:public"]
)
