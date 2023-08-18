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

load("@bazel_stardoc//stardoc:stardoc.bzl", "stardoc")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")


stardoc(
    name = "docs",
    input = "doc_hub.bzl",
    out = "README.md",
    deps = [
        "//apt:lib",
        "//aws:lib",
        "//azure:lib",
        "//brew:lib",
        "//common:lib",
        "//crates:lib",
        "//gcp:lib",
        "//github:lib",
        "//maven:lib",
        "//npm:lib",
        "//npm/assemble:lib",
        "//npm/deploy:lib",
        "//packer:lib",
        "//pip:lib",
        "//rpm:lib",
    ],
    symbol_names = [
        # From: //apt:rules.bzl
        "assemble_apt",
        "deploy_apt",

        # From: //aws:rules.bzl
        "assemble_aws",

        # From: //azure:rules.bzl
        "assemble_azure",

        # From: //brew:rules.bzl
        "deploy_brew",

        # From: //common/assemble_versioned:rules.bzl
        "assemble_versioned",

        # From: //common/checksum:rules.bzl
        "checksum",

        # From: //common/generate_json_config:rules.bzl
        "generate_json_config",

        # From: //common/java_deps:rules.bzl
        "MAVEN_COORDINATES_PREFIX",
        "JarToMavenCoordinatesMapping",
        "TransitiveJarToMavenCoordinatesMapping",
        "java_deps",

        # From: //common:rules.bzl
        "assemble_targz",
        "assemble_zip",

        # From: //common/tgz2zip:rules.bzl
        "tgz2zip",

        # From: //crates:rules.bzl
        "assemble_crate",
        "deploy_crate",

        # From: //gcp:rules.bzl
        "assemble_gcp",

        # From: //github:rules.bzl
        "deploy_github",

        # From: //maven:rules.bzl
        "JavaLibInfo",
        "MavenPomInfo",
        "MavenDeploymentInfo",
        "assemble_maven",
        "deploy_maven",

        # From: //npm:rules.bzl
        "assemble_npm",
        "deploy_npm",

        # From: //packer:rules.bzl
        "assemble_packer",
        "deploy_packer",

        # From: //pip:rules.bzl
        "assemble_pip",
        "deploy_pip",

        # From: //rpm:rules.bzl
        "assemble_rpm",
        "deploy_rpm",
    ],
)
