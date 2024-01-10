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

workspace(name="vaticle_bazel_distribution")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Load @rules_python, @io_bazel_rules_kotlin and @rules_jvm_external
load("//common:deps.bzl", "rules_python", "rules_kotlin", "rules_jvm_external", "rules_rust")
rules_python()
rules_kotlin()
rules_jvm_external()
rules_rust()

# Load @rules_python
load("@rules_python//python:repositories.bzl", "py_repositories")
py_repositories()

# Load @io_bazel_rules_kotlin
load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kotlin_repositories", "kt_register_toolchains")
kotlin_repositories()
kt_register_toolchains()

load("@vaticle_bazel_distribution//maven:deps.bzl", "maven_artifacts_with_versions")
load("@rules_jvm_external//:defs.bzl", "maven_install")
maven_install(
    artifacts = maven_artifacts_with_versions,
    repositories = [
        "https://repo1.maven.org/maven2",
    ],
    strict_visibility = True,
    version_conflict_policy = "pinned",
    fetch_sources = True,
)

# Load @vaticle_bazel_distribution_pip
load("//pip:deps.bzl", pip_deps = "deps")
pip_deps()
load("@vaticle_bazel_distribution_pip//:requirements.bzl", "install_deps")
install_deps()

# Load //docs
load("//docs:python/deps.bzl", python_docs_deps = "deps")
python_docs_deps()
load("@vaticle_dependencies_tool_docs//:requirements.bzl", install_doc_deps = "install_deps")
install_doc_deps()

# TODO: remove this declaration once we upgrade to @io_bazel_stardoc with Bazel 5 support
# Load @bazel_skylib
http_archive(
    name = "bazel_skylib",
    sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz"
    ],
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
bazel_skylib_workspace()

# Load @rules_pkg
load("//common:deps.bzl", "rules_pkg")
rules_pkg()
load("@rules_pkg//pkg:deps.bzl", "rules_pkg_dependencies")
rules_pkg_dependencies()


# Load @io_bazel_stardoc
http_archive(
    name = "bazel_stardoc",
    sha256 = "dfbc364aaec143df5e6c52faf1f1166775a5b4408243f445f44b661cfdc3134f",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/0.5.6/stardoc-0.5.6.tar.gz",
        "https://github.com/bazelbuild/stardoc/releases/download/0.5.6/stardoc-0.5.6.tar.gz",
    ],
)

load("@bazel_stardoc//:setup.bzl", "stardoc_repositories")
stardoc_repositories()

# Load @vaticle_bazel_distribution_cloudsmith
load("//common/cloudsmith:deps.bzl", cloudsmith_deps = "deps")
cloudsmith_deps()
load("@vaticle_bazel_distribution_cloudsmith//:requirements.bzl", install_cloudsmith_deps = "install_deps")
install_cloudsmith_deps()
