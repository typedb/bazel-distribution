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

load("//apt:rules.bzl", _assemble_apt = "assemble_apt", _deploy_apt = "deploy_apt")
assemble_apt = _assemble_apt
deploy_apt = _deploy_apt

load("//aws:rules.bzl", _ = "assemble_aws")
assemble_aws = _

load("//azure:rules.bzl", _ = "assemble_azure")
assemble_azure = _

load("//brew:rules.bzl", _ = "deploy_brew")
deploy_brew = _

load("//common:assemble_versioned/rules.bzl", _ = "assemble_versioned")
assemble_versioned = _

load("//common/checksum:rules.bzl", _ = "checksum")
checksum = _

load("//common:generate_json_config/rules.bzl", _ = "generate_json_config")
generate_json_config = _

load("//common:java_deps/rules.bzl",
    _MAVEN_COORDINATES_PREFIX = "MAVEN_COORDINATES_PREFIX",
    _JarToMavenCoordinatesMapping = "JarToMavenCoordinatesMapping",
    _TransitiveJarToMavenCoordinatesMapping = "TransitiveJarToMavenCoordinatesMapping",
    _java_deps = "java_deps",
)
MAVEN_COORDINATES_PREFIX = _MAVEN_COORDINATES_PREFIX
JarToMavenCoordinatesMapping = _JarToMavenCoordinatesMapping
TransitiveJarToMavenCoordinatesMapping = _TransitiveJarToMavenCoordinatesMapping
java_deps = _java_deps

load("//common:rules.bzl", _assemble_targz = "assemble_targz", _assemble_zip = "assemble_zip")
assemble_targz = _assemble_targz
assemble_zip = _assemble_zip

load("//common/tgz2zip:rules.bzl", _ = "tgz2zip")
tgz2zip = _

load("//gcp:rules.bzl", _ = "assemble_gcp")
assemble_gcp = _

load('//github:rules.bzl', _ = "deploy_github")
deploy_github = _

load('//maven:rules.bzl',
    _JarInfo = "JarInfo",
    _MavenDeploymentInfo = "MavenDeploymentInfo",
    _assemble_maven = "assemble_maven",
    _deploy_maven = "deploy_maven",
)
JarInfo = _JarInfo
MavenDeploymentInfo = _MavenDeploymentInfo
assemble_maven = _assemble_maven
deploy_maven = _deploy_maven

load("//npm:rules.bzl", _assemble_npm = "assemble_npm", _deploy_npm = "deploy_npm")
assemble_npm = _assemble_npm
deploy_npm = _deploy_npm

load("//packer:rules.bzl", _assemble_packer = "assemble_packer", _deploy_packer = "deploy_packer")
assemble_packer = _assemble_packer
deploy_packer = _deploy_packer

load("//pip:rules.bzl", _assemble_pip = "assemble_pip", _deploy_pip = "deploy_pip")
assemble_pip = _assemble_pip
deploy_pip = _deploy_pip

load("//rpm:rules.bzl", _assemble_rpm = "assemble_rpm", _deploy_rpm = "deploy_rpm")
assemble_rpm = _assemble_rpm
deploy_rpm = _deploy_rpm
