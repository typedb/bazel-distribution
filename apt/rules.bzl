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