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

workspace(name="typedb_bazel_distribution")

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

load("@typedb_bazel_distribution//maven:deps.bzl", "maven_artifacts_with_versions")
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

# Load @typedb_bazel_distribution_pip
load("//pip:deps.bzl", "typedb_bazel_distribution_pip")
typedb_bazel_distribution_pip()
load("@typedb_bazel_distribution_pip//:requirements.bzl", pip_install_deps = "install_deps")
pip_install_deps()

# Load //docs
load("//docs:python/deps.bzl", "typedb_bazel_distribution_docs_py")
typedb_bazel_distribution_docs_py()
load("@typedb_bazel_distribution_docs_py//:requirements.bzl", docs_py_install_deps = "install_deps")
docs_py_install_deps()

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

# Load @typedb_bazel_distribution_uploader
load("//common/uploader:deps.bzl", "typedb_bazel_distribution_uploader")
typedb_bazel_distribution_uploader()
load("@typedb_bazel_distribution_uploader//:requirements.bzl", uploader_install_deps = "install_deps")
uploader_install_deps()
