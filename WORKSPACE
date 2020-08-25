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

workspace(name="graknlabs_bazel_distribution")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Load @rules_python
load("//common:deps.bzl", "bazelbuild_rules_python")
bazelbuild_rules_python()
load("@rules_python//python:pip.bzl", "pip_repositories", "pip_import")
pip_repositories()

# Load @graknlabs_bazel_distribution_pip
pip_import(
    name = "graknlabs_bazel_distribution_pip",
    requirements = "//pip:requirements.txt",
)
load("@graknlabs_bazel_distribution_pip//:requirements.bzl", graknlabs_bazel_distribution_pip_install = "pip_install")
graknlabs_bazel_distribution_pip_install()

# Load @rules_pkg
load("//common:deps.bzl", "bazelbuild_rules_pkg")
bazelbuild_rules_pkg()
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
rules_pkg_dependencies()

# Load @io_bazel_stardoc
git_repository(
    name = "io_bazel_stardoc",
    remote = "https://github.com/bazelbuild/stardoc",
    commit = "87dc99cfe1baa9255c607ac0229bfd33a65367f5",
)
load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")
stardoc_repositories()
