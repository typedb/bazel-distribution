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

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar", "pkg_deb")
load("@graknlabs_bazel_distribution//common:java_deps.bzl", _java_deps = "java_deps")
load("@graknlabs_bazel_distribution//common:tgz2zip.bzl", _tgz2zip = "tgz2zip")
load("@graknlabs_bazel_distribution//common:checksum.bzl", _checksum = "checksum")
load("@graknlabs_bazel_distribution//common:assemble_versioned.bzl", _assemble_versioned = "assemble_versioned")


java_deps = _java_deps
tgz2zip = _tgz2zip
checksum = _checksum
assemble_versioned = _assemble_versioned


def assemble_targz(name,
                   output_filename = None,
                   targets = [],
                   additional_files = {},
                   empty_directories = [],
                   permissions = {},
                   visibility = ["//visibility:private"],
                   tags = []):
    """Assemble distribution archive (.tar.gz)

    Args:
        name: A unique name for this target.
        output_filename: filename of resulting archive
        targets: Bazel labels of archives that go into .tar.gz package
        additional_files: mapping between Bazel labels of files that go into archive
            and their resulting location in archive
        empty_directories: list of empty directories created at archive installation
        permissions: mapping between paths and UNIX permissions
        visibility: controls whether the target can be used by other packages
    """
    pkg_tar(
        name = "{}__do_not_reference__targz_0".format(name),
        deps = targets,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
        tags = tags,
    )

    pkg_tar(
        name = "{}__do_not_reference__targz_1".format(name),
        deps = [":{}__do_not_reference__targz_0".format(name)],
        package_dir = output_filename,
        extension = "tar.gz",
        tags = tags,
    )

    output_filename = output_filename or name

    native.genrule(
        name = name,
        srcs = [":{}__do_not_reference__targz_1".format(name)],
        cmd = "cp $$(echo $(SRCS) | awk '{print $$1}') $@",
        outs = [output_filename + ".tar.gz"],
        visibility = visibility,
        tags = tags,
    )


def assemble_zip(name,
                 output_filename,
                 targets,
                 additional_files = {},
                 empty_directories = [],
                 permissions = {},
                 visibility = ["//visibility:private"]):
    """Assemble distribution archive (.zip)

    Args:
        name: A unique name for this target.
        output_filename: filename of resulting archive
        targets: Bazel labels of archives that go into .tar.gz package
        additional_files: mapping between Bazel labels of files that go into archive
            and their resulting location in archive
        empty_directories: list of empty directories created at archive installation
        permissions: mapping between paths and UNIX permissions
        visibility: controls whether the target can be used by other packages
    """
    pkg_tar(
        name="{}__do_not_reference__targz".format(name),
        deps = targets,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
    )

    tgz2zip(
        name = name,
        tgz = ":{}__do_not_reference__targz".format(name),
        output_filename = output_filename,
        prefix = "./" + output_filename,
        visibility = visibility
    )


def _workspace_refs_impl(repository_ctx):
    repository_ctx.file('BUILD', content='exports_files(["refs.json"])', executable=False)
    workspace_refs_dict = {
        "commits": repository_ctx.attr.workspace_commit_dict,
        "tags": repository_ctx.attr.workspace_tag_dict,
    }
    repository_ctx.file('refs.json', content=struct(**workspace_refs_dict).to_json(), executable=False)


_workspace_refs = repository_rule(
    implementation = _workspace_refs_impl,
    attrs = {
        'workspace_commit_dict': attr.string_dict(),
        'workspace_tag_dict': attr.string_dict(),
    },
)


def workspace_refs(name):
    _workspace_refs(
        name = name,
        workspace_commit_dict = {k: v['commit'] for k, v in native.existing_rules().items() if 'commit' in v and len(v['commit'])>0},
        workspace_tag_dict = {k: v['tag'] for k, v in native.existing_rules().items() if 'tag' in v and len(v['tag'])>0}
    )
