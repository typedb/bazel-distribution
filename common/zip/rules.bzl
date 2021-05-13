#
# Copyright (C) 2021 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@vaticle_bazel_distribution//common/targz:rules.bzl", "assemble_targz")
load("@vaticle_bazel_distribution//common/tgz2zip:rules.bzl", "tgz2zip")

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

assemble_zip_prefix_file = rule(
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
                 targets = [],
                 additional_files = {},
                 empty_directories = [],
                 permissions = {},
                 append_version = True,
                 visibility = ["//visibility:private"],
                 tags = []):
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
    assemble_targz(
        name = "{}__do_not_reference__targz".format(name),
        output_filename = output_filename,
        targets = targets,
        additional_files = additional_files,
        empty_directories = empty_directories,
        permissions = permissions,
        append_version = append_version,
        visibility = ["//visibility:private"],
    )
    tgz2zip(
        name = name,
        tgz = ":{}__do_not_reference__targz".format(name),
        output_filename = output_filename,
        visibility = visibility,
        tags = tags
    )


