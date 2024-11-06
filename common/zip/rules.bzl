#
#  This program is free software: you can redistribute it and/or modify
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

load("@typedb_bazel_distribution//common/targz:rules.bzl", "assemble_targz")
load("@typedb_bazel_distribution//common/tgz2zip:rules.bzl", "tgz2zip")

def assemble_zip(
        name,
        output_filename,
        targets = [],
        additional_files = {},
        empty_directories = [],
        permissions = {},
        append_version = True,
        visibility = ["//visibility:private"],
        tags = [],
        target_compatible_with = []):
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
        target_compatible_with = target_compatible_with,
    )
    tgz2zip(
        name = name,
        tgz = ":{}__do_not_reference__targz".format(name),
        output_filename = output_filename,
        visibility = visibility,
        tags = tags,
    )

def unzip_file(name, target, output, **kwargs):
    """Unzip a single-file archive

    Args:
        name: unique name for this target
        target: single input .zip archive
        output: name for the unzipped file
    """
    native.genrule(
        name = name,
        srcs = [target],
        outs = [output],
        tools = ["@bazel_tools//tools/zip:zipper"],
        cmd_bash = "mkdir -p $(@D)/tmp && $(location @bazel_tools//tools/zip:zipper) x $< -d $(@D)/tmp && mv $(@D)/tmp/* $@",
        cmd_bat = "MD $(@D)\\tmp && $(location @bazel_tools//tools/zip:zipper) x $< -d $(@D)\\tmp && MOVE $(@D)\\tmp\\* $@",
        **kwargs
    )
