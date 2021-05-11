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

load("@vaticle_bazel_distribution//common:assemble_versioned.bzl", _assemble_versioned = "assemble_versioned")
load("@vaticle_bazel_distribution//common:checksum.bzl", _checksum = "checksum")
load("@vaticle_bazel_distribution//common:java_deps.bzl", _java_deps = "java_deps")
load("@vaticle_bazel_distribution//common:tgz2zip.bzl", _tgz2zip = "tgz2zip")
load("@vaticle_bazel_distribution//common/targz:rules.bzl", _assemble_targz = "assemble_targz")
load("@vaticle_bazel_distribution//common/workspace_refs:rules.bzl", _workspace_refs = "workspace_refs")
load("@vaticle_bazel_distribution//common/zip:rules.bzl", _assemble_zip = "assemble_zip")

assemble_versioned = _assemble_versioned
checksum = _checksum
java_deps = _java_deps
tgz2zip = _tgz2zip
assemble_targz = _assemble_targz
workspace_refs = _workspace_refs
assemble_zip = _assemble_zip
