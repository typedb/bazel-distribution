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

load("@io_bazel_skydoc//stardoc:stardoc.bzl", "stardoc")

stardoc(
    name = "docs",
    input = "doc_hub.bzl",
    out = "README.md",
    deps = [
        "//apt:lib",
        "//azure:lib",
        "//aws:lib",
        "//brew:lib",
        "//common:lib",
        "//gcp:lib",
        "//github:lib",
        "//maven/templates:lib",
        "//npm:lib",
        "//packer:lib",
        "//pip:lib",
        "//rpm:lib",
    ],
    symbol_names = [
        "assemble_azure",
        "pkg_deb",
        "assemble_apt",
        "deploy_apt",
        "assemble_aws",
        "deploy_brew",
        "assemble_versioned",
        "checksum",
        "generate_json_config",
        "JarToMavenCoordinatesMapping",
        "java_deps",
        "MAVEN_COORDINATES_PREFIX",
        "TransitiveJarToMavenCoordinatesMapping",
        "assemble_targz",
        "assemble_zip",
        "tgz2zip",
        "assemble_gcp",
        "deploy_github",
        "assemble_maven",
        "javadoc",
        "deploy_maven",
        "JavaLibInfo",
        "MavenDeploymentInfo",
        "MavenPomInfo",
        "assemble_npm",
        "deploy_npm",
        "assemble_packer",
        "deploy_packer",
        "assemble_pip",
        "deploy_pip",
        "assemble_rpm",
        "deploy_rpm",
    ],
)
