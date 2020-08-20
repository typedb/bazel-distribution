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

# File which loads *all* rules to make them visible for doc generation
# Rules *do* need to be reexported because otherwise they are not visible

load("//apt:rules.bzl", a = "assemble_apt", d = "deploy_apt")
assemble_apt = a
deploy_apt = d

load("//aws:rules.bzl", _ = "assemble_aws")
assemble_aws = _

load("//azure:rules.bzl", _ = "assemble_azure")
assemble_azure = _

load("//brew:rules.bzl", _ = "deploy_brew")
deploy_brew = _

load("//common:assemble_versioned.bzl", _ = "assemble_versioned")
assemble_versioned = _

load("//common:checksum.bzl", _ = "checksum")
checksum = _

load("//common:generate_json_config.bzl", _ = "generate_json_config")
generate_json_config = _

load("//common:java_deps.bzl",
    J = "JarToMavenCoordinatesMapping",
    j = "java_deps",
    M = "MAVEN_COORDINATES_PREFIX",
    T = "TransitiveJarToMavenCoordinatesMapping")
JarToMavenCoordinatesMapping = J
java_deps = j
MAVEN_COORDINATES_PREFIX = M
TransitiveJarToMavenCoordinatesMapping = T

load("//common:rules.bzl", _ = "assemble_targz", __ = "assemble_zip")
assemble_targz = _
assemble_zip = __

load("//common:tgz2zip.bzl", _ = "tgz2zip")
tgz2zip = _

load("//gcp:rules.bzl", _ = "assemble_gcp")
assemble_gcp = _

load('//github:rules.bzl', _ = "deploy_github")
deploy_github = _

load("//npm:rules.bzl", a = "assemble_npm", d = "deploy_npm")
assemble_npm = a
deploy_npm = d

load("//packer:rules.bzl", a = "assemble_packer", d = "deploy_packer")
assemble_packer = a
deploy_packer = d

load("//pip:rules.bzl", a = "assemble_pip", d = "deploy_pip")
assemble_pip = a
deploy_pip = d

load("//rpm:rules.bzl", a = "assemble_rpm", d = "deploy_rpm")
assemble_rpm = a
deploy_rpm = d
