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
load("@vaticle_bazel_distribution//common:rules.bzl", "assemble_zip_prefix_file", "tgz2zip")

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

    assemble_zip_prefix_file(
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


