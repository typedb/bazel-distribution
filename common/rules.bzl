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

load("@typedb_bazel_distribution//common/assemble_versioned:rules.bzl", _assemble_versioned = "assemble_versioned")
load("@typedb_bazel_distribution//common/checksum:rules.bzl", _checksum = "checksum")
load("@typedb_bazel_distribution//common/generate_json_config:rules.bzl", _generate_json_config = "generate_json_config")
load("@typedb_bazel_distribution//common/java_deps:rules.bzl", _java_deps = "java_deps")
load("@typedb_bazel_distribution//common/tgz2zip:rules.bzl", _tgz2zip = "tgz2zip")
load("@typedb_bazel_distribution//common/targz:rules.bzl", _assemble_targz = "assemble_targz")
load("@typedb_bazel_distribution//common/workspace_refs:rules.bzl", _workspace_refs = "workspace_refs")
load("@typedb_bazel_distribution//common/zip:rules.bzl", _assemble_zip = "assemble_zip", _unzip_file = "unzip_file")
load("@typedb_bazel_distribution//common/rename:rules.bzl", _file_rename = "file_rename")

assemble_targz = _assemble_targz
assemble_versioned = _assemble_versioned
assemble_zip = _assemble_zip
checksum = _checksum
file_rename = _file_rename
generate_json_config = _generate_json_config
java_deps = _java_deps
tgz2zip = _tgz2zip
unzip_file = _unzip_file
workspace_refs = _workspace_refs

# python_interpreter_symlink
OS_NAMES = ("mac", "win", "linux")
OS_ARCHS = ("aarch64", "x86_64")
(MAC, WIN, LINUX) = OS_NAMES
(ARM64, X64) = OS_ARCHS

PYTHON_INTERPRETER_SUFFIXES = {
    (MAC, ARM64) : "aarch64-apple-darwin",
    (MAC, X64) : "x86_64-apple-darwin",
    (LINUX, ARM64): "aarch64-unknown-linux-gnu",
    (LINUX, X64): "x86_64-unknown-linux-gnu",
    (WIN, "amd64") : "x86_64-pc-windows-msvc",
}

def _python_interpreter_symlink_impl(rctx):
    os_name = None
    for name in OS_NAMES:
        if name in rctx.os.name:
            os_name = name

    if os_name == None:
        fail
    os_arch = rctx.os.arch
    interpreter_suffix = PYTHON_INTERPRETER_SUFFIXES.get((os_name, os_arch))

    resolved_interpreter_label = Label("@" + rctx.attr.interpreter_toolchain_name + "_" + interpreter_suffix + "//:python")
    build_file_content = """
package(default_visibility = ["//visibility:public"])
exports_files(["python"])
    """
    rctx.file("WORKSPACE", "workspace(name = \"%s\")"%rctx.attr.name)
    rctx.file("BUILD.bazel", content=build_file_content, executable=False)
    rctx.symlink(resolved_interpreter_label, "python")

python_interpreter_symlink = repository_rule(
    implementation= _python_interpreter_symlink_impl,
    attrs={
        "interpreter_toolchain_name" : attr.string(mandatory=True),
    }
)
