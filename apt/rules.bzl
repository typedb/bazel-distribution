#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2018 Grakn Labs Ltd
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

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")
load("//apt/pkg_deb_modified_from_bazel:pkg.bzl", "pkg_deb")

def assemble_apt(name,
                     package_name,
                     maintainer,
                     version_file,
                     description,
                     installation_dir = None,
                     archives = [],
                     empty_dirs = [],
                     files = {},
                     depends = [],
                     symlinks = {},
                     permissions = {}):
    tar_name = "_{}-deb-tar".format(package_name)
    deb_data = None
    if installation_dir:
        pkg_tar(
            name = tar_name,
            extension = "tar.gz",
            deps = archives,
            package_dir = installation_dir,
            empty_dirs = empty_dirs,
            files = files,
            mode = "0755",
            symlinks = symlinks,
            modes = permissions,
        )
        deb_data = tar_name
    else:
        pkg_tar(name = tar_name + "__do_not_reference__empty")
        deb_data = tar_name + "__do_not_reference__empty"

    pkg_deb(
        name = name,
        data = deb_data,
        package = package_name,
        depends = depends,
        maintainer = maintainer,
        version_file = version_file,
        description = description
    )


def _deploy_apt_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._deployment_script,
        output = ctx.outputs.deployment_script,
        substitutions = {},
        is_executable = True
    )

    symlinks = {
        'package.deb': ctx.files.target[0],
        'deployment.properties': ctx.file.deployment_properties
    }

    return DefaultInfo(executable = ctx.outputs.deployment_script,
                       runfiles = ctx.runfiles(
                           files=[ctx.files.target[0], ctx.file.deployment_properties],
                           symlinks = symlinks))


deploy_apt = rule(
    attrs = {
        "target": attr.label(),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "//apt/templates:deploy.sh"
        )
    },
    outputs = {
        "deployment_script": "%{name}.sh",
    },
    implementation = _deploy_apt_impl,
    executable = True,
)