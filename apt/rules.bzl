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
                 workspace_refs = None,
                 archives = [],
                 empty_dirs = [],
                 files = {},
                 depends = [],
                 symlinks = {},
                 permissions = {}):
    """Assemble package for installation with APT

    Args:
        name: A unique name for this target.
        package_name: Package name for built .deb package
            https://www.debian.org/doc/debian-policy/ch-controlfields#package
        maintainer: The package maintainer's name and email address.
            The name must come first, then the email address
            inside angle brackets <> (in RFC822 format)
        version_file: File containing version number of a package
            https://www.debian.org/doc/debian-policy/ch-controlfields#version
        description: description of the built package
            https://www.debian.org/doc/debian-policy/ch-controlfields#description
        installation_dir: directory into which .deb package is unpacked at installation
        workspace_refs: JSON file with other Bazel workspace references
        archives: Bazel labels of archives that go into .deb package
        empty_dirs: list of empty directories created at package installation
        files: mapping between Bazel labels of archives that go into .deb package
            and their resulting location on .deb package installation
        depends: list of Debian packages this package depends on
            https://www.debian.org/doc/debian-policy/ch-relationships.htm
        symlinks: mapping between source and target of symbolic links
            created at installation
        permissions: mapping between paths and UNIX permissions
    """
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

    args = [
        "$(location @graknlabs_bazel_distribution//apt:generate_depends_file)",
        "--output", "$@",
        "--version_file", "$(location {})".format(version_file),
        "--deps"
    ]
    for dep in depends:
        args.append('"{}"'.format(dep))
    srcs = [version_file]

    if workspace_refs:
        args.append("--workspace_refs")
        args.append("$(location {})".format(workspace_refs))
        srcs.append(workspace_refs)

    depends_file_target_name = name + "__depends__do_not_reference"

    native.genrule(
        name = depends_file_target_name,
        srcs = srcs,
        outs = ["{}.depends".format(name)],
        cmd = " ".join(args),
        tools = ["@graknlabs_bazel_distribution//apt:generate_depends_file"]
    )

    pkg_deb(
        name = name,
        data = deb_data,
        package = package_name,
        depends_file = depends_file_target_name,
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
        "target": attr.label(
            doc = 'assemble_apt label to deploy'
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = 'Properties file containing repo.apt.(snapshot|release) key'
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
    doc = 'Deploy package built with `assemble_apt` to APT repository'
)