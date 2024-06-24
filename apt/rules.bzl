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
load("@rules_pkg//pkg:mappings.bzl", "pkg_attributes", "pkg_mkdirs", "pkg_mklink", "pkg_filegroup", "pkg_files")

def _assemble_apt_version_file_impl(ctx):
    version = ctx.var.get('version', '0.0.0')

    if len(version) == 40:
        # this is a commit SHA, most likely
        version = "0.0.0-{}".format(version)

    ctx.actions.run_shell(
        inputs = [],
        outputs = [ctx.outputs.version_file],
        command = "echo {} > {}".format(version, ctx.outputs.version_file.path)
    )


_assemble_apt_version_file = rule(
    outputs = {
        "version_file": "%{name}.version"
    },
    implementation = _assemble_apt_version_file_impl
)

def assemble_apt(name,
                 package_name,
                 maintainer,
                 description,
                 version_file = None,
                 installation_dir = None,
                 workspace_refs = None,
                 archives = [],
                 empty_dirs = [],
                 empty_dirs_permission = "0777",
                 files = {},
                 depends = [],
                 symlinks = {},
                 permissions = {},
                 architecture = 'all',
                 target_compatible_with = []):
    """Assemble package for installation with APT

    Args:
        name: A unique name for this target.
        package_name: Package name for built .deb package
            https://www.debian.org/doc/debian-policy/ch-controlfields#package
        maintainer: The package maintainer's name and email address.
            The name must come first, then the email address
            inside angle brackets <> (in RFC822 format)
        description: description of the built package
            https://www.debian.org/doc/debian-policy/ch-controlfields#description
        version_file: File containing version number of a package.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Specifying commit SHA will result in prepending '0.0.0' to it to comply with Debian rules.
            Not specifying version at all defaults to '0.0.0'
            https://www.debian.org/doc/debian-policy/ch-controlfields#version
        installation_dir: directory into which .deb package is unpacked at installation
        workspace_refs: JSON file with other Bazel workspace references
        archives: Bazel labels of archives that go into .deb package
        empty_dirs: list of empty directories created at package installation
        empty_dirs_permission: UNIXy permission for the empty directories to be created
        files: mapping between Bazel labels of archives that go into .deb package
            and their resulting location on .deb package installation
        depends: list of Debian packages this package depends on
            https://www.debian.org/doc/debian-policy/ch-relationships.htm
        symlinks: mapping between source and target of symbolic links
            created at installation
        permissions: mapping between paths and UNIXy permissions
        architecture: package architecture (default option: 'all', common other options: 'amd64', 'arm64')
    """

    ALLOWED_ARCHITECTURES = ['all', 'amd64', 'arm64']
    if not architecture in ALLOWED_ARCHITECTURES:
        fail("Apt architectures supported are only: {}".format(ALLOWED_ARCHITECTURES))

    tar_name = "_{}-deb-tar".format(name)
    deb_data = None
    if installation_dir:
        empty_dirs_name = "_{}-empty-dirs".format(name)
        pkg_mkdirs(
            name = empty_dirs_name,
            attributes = pkg_attributes(
                mode = empty_dirs_permission
            ),
            dirs = empty_dirs
        )

        symlink_names = []
        for link, target in symlinks.items():
            print(link, target)
            symlink_name = "_{}-{}".format(name, link.replace("/", "_").replace("\\", "_"))
            symlink_names.append(symlink_name)
            pkg_mklink(
                name = symlink_name,
                link_name = link,
                target = target
            )

        archives_merged_name = "_{}_archives".format(name)
        pkg_tar(
            name = archives_merged_name,
            package_dir = installation_dir,
            deps = archives # using deps instead of sources will merge tars into a single tar
        )

        files_name = "_{}_files".format(name)
        pkg_files(
            name = files_name,
            prefix = installation_dir,
            srcs = files.keys(),
            renames = files,
        )

        pkg_tar(
            name = tar_name,
            extension = "tar.gz",
            srcs = [empty_dirs_name] + symlink_names + [files_name],
            mode = "0755",
            deps = [archives_merged_name],
            modes = permissions,
        )
        deb_data = tar_name
    else:
        pkg_tar(name = tar_name + "__do_not_reference__empty")
        deb_data = tar_name + "__do_not_reference__empty"

    if not version_file:
        version_file = name + "__version__do_not_reference"
        _assemble_apt_version_file(
            name = version_file
        )
    args = [
        "$(location @vaticle_bazel_distribution//apt:generate_depends_file)",
        "--output", "$@",
        "--version_file", "$(location {})".format(version_file),
    ]
    if len(depends):
        args.append("--deps")
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
        tools = ["@vaticle_bazel_distribution//apt:generate_depends_file"]
    )

    pkg_deb(
        name = name,
        data = deb_data,
        package = package_name,
        depends_file = depends_file_target_name,
        maintainer = maintainer,
        version_file = version_file,
        description = description,
        architecture = architecture,
        target_compatible_with = target_compatible_with
    )


def _deploy_apt_impl(ctx):
    _deploy_script = ctx.actions.declare_file(ctx.attr.deploy_script_name)
    package_path = ctx.files.target[0].short_path
    ctx.actions.expand_template(
        template = ctx.file._deployment_script,
        output = _deploy_script,
        substitutions = {
            '{snapshot}' : ctx.attr.snapshot,
            '{release}' : ctx.attr.release,
            '{package_path}' : package_path,
            '{version}' : ctx.var.get('version', '0.0.0')
        },
        is_executable = True
    )

    deployment_lib_files = ctx.attr._deployment_wrapper_lib[DefaultInfo].default_runfiles.files.to_list()
    return DefaultInfo(executable = _deploy_script,
                       runfiles = ctx.runfiles(files=[ctx.files.target[0]] + deployment_lib_files))


_deploy_apt = rule(
    attrs = {
        "target": attr.label(
            doc = 'assemble_apt label to deploy'
        ),
        "snapshot": attr.string(
            mandatory = True,
            doc = 'Snapshot repository to deploy apt artifact to'
        ),
        "release": attr.string(
            mandatory = True,
            doc = 'Release repository to deploy apt artifact to'
        ),
        "_deployment_wrapper_lib": attr.label(
            default = "//common/uploader:uploader",
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "//apt/templates:deploy.py"
        ),
        "deploy_script_name": attr.string(
            mandatory = True,
            doc = 'Name of instantiated deployment script'
        ),
    },
    implementation = _deploy_apt_impl,
    executable = True,
    doc = """Deploy package built with `assemble_apt` to APT repository.

    Select deployment to `snapshot` or `release` repository with `bazel run //:some-deploy-apt -- [snapshot|release]
    """
)

def deploy_apt(name, target, snapshot, release, **kwargs):
    deploy_script_target_name = name + "__deploy"
    deploy_script_name = deploy_script_target_name + "-deploy.py"

    _deploy_apt(
        name = deploy_script_target_name,
        target = target,
        snapshot = snapshot,
        release = release,
        deploy_script_name = deploy_script_name,
        **kwargs
    )

    native.py_binary(
        name = name,
        srcs = [deploy_script_target_name],
        main = deploy_script_name,
    )
