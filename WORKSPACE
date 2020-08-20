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

# Load NodeJS
http_archive(
    name = "build_bazel_rules_nodejs",
    sha256 = "10fffa29f687aa4d8eb6dfe8731ab5beb63811ab00981fc84a93899641fd4af1",
    urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/2.0.3/rules_nodejs-2.0.3.tar.gz"],
)
load("@build_bazel_rules_nodejs//:index.bzl", "node_repositories")
node_repositories()

# Common helper tools
http_archive(
    name = "bazel_skylib",
    urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/0.8.0/bazel-skylib.0.8.0.tar.gz"],
    sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
)
# Load Github
load("//github:dependencies.bzl", "tcnksm_ghr")
tcnksm_ghr()

# Load Python
git_repository(
    name = "rules_python",
    remote = "https://github.com/bazelbuild/rules_python.git",
    tag = "0.0.2",
    patches = [
        # Force rules_python to export the requirements.bzl file in
        # order for stardoc to be able to load it during documentation
        # generation.
        "//:bazelbuild_rules_python-export-requirements-bzl-for-stardoc.patch",
    ],
    patch_args = ["-p1"],
)
load("@rules_python//python:pip.bzl", "pip_repositories", "pip_import")
pip_repositories()
pip_import(
    name = "graknlabs_bazel_distribution_pip",
    requirements = "//pip:requirements.txt",
)
load("@graknlabs_bazel_distribution_pip//:requirements.bzl", graknlabs_bazel_distribution_pip_install = "pip_install")
graknlabs_bazel_distribution_pip_install()

# Load Apt and RPM
load("//common:dependencies.bzl", "bazelbuild_rules_pkg")
bazelbuild_rules_pkg()
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
rules_pkg_dependencies()

# Load Stardoc
git_repository(
    name = "io_bazel_stardoc",
    remote = "https://github.com/bazelbuild/stardoc",
    commit = "87dc99cfe1baa9255c607ac0229bfd33a65367f5",
)
load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")
stardoc_repositories()
