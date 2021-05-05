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

load("@rules_pkg//:pkg.bzl", "pkg_tar", "pkg_deb")
load("@vaticle_bazel_distribution//common:java_deps.bzl", _java_deps = "java_deps")
load("@vaticle_bazel_distribution//common:tgz2zip.bzl", _tgz2zip = "tgz2zip")
load("@vaticle_bazel_distribution//common:checksum.bzl", _checksum = "checksum")
load("@vaticle_bazel_distribution//common:assemble_versioned.bzl", _assemble_versioned = "assemble_versioned")


java_deps = _java_deps
tgz2zip = _tgz2zip
checksum = _checksum
assemble_versioned = _assemble_versioned


def _assemble_targz_package_dir_file_impl(ctx):
    version = ctx.var.get('version', '')

    package_dir = ctx.attr.package_dir
    if package_dir and version and ctx.attr.append_version:
        package_dir = '{}-{}'.format(package_dir, version)

    ctx.actions.run_shell(
        inputs = [],
        outputs = [ctx.outputs.package_dir_file],
        command = "echo {} > {}".format(package_dir, ctx.outputs.package_dir_file.path)
    )


_assemble_targz_package_dir_file = rule(
    attrs = {
        "append_version": attr.bool(default=True),
        "package_dir": attr.string()
    },
    outputs = {
        "package_dir_file": "%{name}.package_dir"
    },
    implementation = _assemble_targz_package_dir_file_impl
)

def assemble_targz(name,
                   output_filename = None,
                   targets = [],
                   additional_files = {},
                   empty_directories = [],
                   permissions = {},
                   append_version = True,
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
        append_version: append version to root folder inside the archive
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

    _assemble_targz_package_dir_file(
        name = "{}__do_not_reference__pkgdir".format(name),
        package_dir = output_filename,
        append_version = append_version
    )

    pkg_tar(
        name = "{}__do_not_reference__targz_1".format(name),
        deps = [":{}__do_not_reference__targz_0".format(name)],
        package_dir_file = "{}__do_not_reference__pkgdir".format(name),
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


def _assemble_archive_prefix_file_impl(ctx):
    version = ctx.var.get('version', '')

    prefix = ctx.attr.prefix
    if prefix and version and ctx.attr.append_version:
        prefix = '{}-{}'.format(prefix, version)

    ctx.actions.run_shell(
        inputs = [],
        outputs = [ctx.outputs.prefix_file],
        command = "echo {} > {}".format(prefix, ctx.outputs.prefix_file.path)
    )


_assemble_zip_prefix_file = rule(
    attrs = {
        "append_version": attr.bool(default=True),
        "prefix": attr.string()
    },
    outputs = {
        "prefix_file": "%{name}.prefix"
    },
    implementation = _assemble_archive_prefix_file_impl
)

def assemble_zip(name,
                 output_filename,
                 targets,
                 additional_files = {},
                 empty_directories = [],
                 permissions = {},
                 append_version = True,
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
        append_version: append version to root folder inside the archive
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

    _assemble_zip_prefix_file(
        name = "{}__do_not_reference__prefix_file".format(name),
        prefix = "./" + output_filename,
        append_version = append_version
    )

    tgz2zip(
        name = name,
        tgz = ":{}__do_not_reference__targz".format(name),
        output_filename = output_filename,
        prefix_file = "{}__do_not_reference__prefix_file".format(name),
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

    workspace_commit_dict = {}
    workspace_tag_dict = {}

    for k, v in native.existing_rules().items():
        if 'tags' in v:
            for t in v['tags']:
                key, eq, value = t.partition("=")
                if eq == "=":
                    if key == "tag":
                        workspace_tag_dict[k] = value
                    elif key == "commit":
                        workspace_commit_dict[k] = value

        if 'tag' in v and len(v['tag'])>0:
            workspace_tag_dict[k] = v['tag']
        elif 'commit' in v and len(v['commit'])>0:
            workspace_commit_dict[k] = v['commit']


    _workspace_refs(
        name = name,
        workspace_commit_dict = workspace_commit_dict,
        workspace_tag_dict = workspace_tag_dict
    )
