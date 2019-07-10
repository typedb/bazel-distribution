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
load("@bazel_tools//tools/build_defs/pkg:rpm.bzl", "pkg_rpm")


def assemble_rpm(name,
                 package_name,
                 version_file,
                 spec_file,
                 workspace_refs = None,
                 installation_dir = None,
                 archives = [],
                 empty_dirs = [],
                 files = {},
                 permissions = {},
                 symlinks = {}):
    """Assemble package for installation with RPM

    Args:
        name: A unique name for this target.
        package_name: Package name for built .deb package
        version_file: File containing version number of a package
        spec_file: The RPM spec file to use
        installation_dir: directory into which .rpm package is unpacked at installation
        archives: Bazel labels of archives that go into .rpm package
        empty_dirs: list of empty directories created at package installation
        files: mapping between Bazel labels of archives that go into .rpm package
            and their resulting location on .rpm package installation
        permissions: mapping between paths and UNIX permissions
        symlinks: mapping between source and target of symbolic links
                    created at installation
    """
    tar_name = "_{}-rpm-tar".format(package_name)

    rpm_data = []

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
        rpm_data.append(tar_name)

    if "osx_build" not in native.existing_rules():
        native.config_setting(
           name = "osx_build",
           constraint_values = [
               "@bazel_tools//platforms:osx",
               "@bazel_tools//platforms:x86_64",
           ]
        )

    if "linux_build" not in native.existing_rules():
        native.config_setting(
            name = "linux_build",
            constraint_values = [
                "@bazel_tools//platforms:linux",
                "@bazel_tools//platforms:x86_64",
            ]
        )

    if workspace_refs:
        modified_spec_target_name = name + "__spec_do_not_reference"
        modified_spec_filename = name + '.spec'
        args = [
            "$(location @graknlabs_bazel_distribution//rpm:generate_spec_file)",
            "--output", "$(location {})".format(modified_spec_filename),
            "--spec_file", "$(location {})".format(spec_file),
            "--workspace_refs", "$(location {})".format(workspace_refs),
        ]
        native.genrule(
            name = modified_spec_target_name,
            srcs = [spec_file, workspace_refs],
            outs = [modified_spec_filename],
            cmd = " ".join(args),
            tools = ["@graknlabs_bazel_distribution//rpm:generate_spec_file"]
        )
        spec_file = modified_spec_target_name

    pkg_rpm(
        name = "{}__do_not_reference__rpm".format(name),
        architecture = "x86_64",
        spec_file = spec_file,
        version_file = version_file,
        data = rpm_data,
        rpmbuild_path = select({
            ":linux_build": "/usr/bin/rpmbuild",
            ":osx_build": "/usr/local/bin/rpmbuild",
            "//conditions:default": ""
        })
    )
    tag = "rpm_package_name={}".format(spec_file.split(':')[-1].replace('.spec', ''))

    native.genrule(
        name = name,
        srcs = ["{}__do_not_reference__rpm".format(name)],
        cmd = "cp $$(echo $(SRCS) | awk '{print $$1}') $@",
        outs = [package_name + ".rpm"],
        tags = [tag]
    )


RpmInfo = provider(
    fields = {
        "package_name": "RPM package name"
    }
)

def _collect_rpm_package_name(target, ctx):
    rpm_tag = ctx.rule.attr.tags[0]
    package_name = rpm_tag.replace('rpm_package_name=', '')
    return RpmInfo(package_name=package_name)


collect_rpm_package_name = aspect(
    implementation = _collect_rpm_package_name
)

def _deploy_rpm_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._deployment_script,
        output = ctx.outputs.deployment_script,
        substitutions = {
            "{RPM_PKG}": ctx.attr.target[RpmInfo].package_name
        },
        is_executable = True
    )

    symlinks = {
        'package.rpm': ctx.files.target[0],
        'deployment.properties': ctx.file.deployment_properties
    }

    return DefaultInfo(executable = ctx.outputs.deployment_script,
                       runfiles = ctx.runfiles(
                           files=[ctx.files.target[0], ctx.file.deployment_properties],
                           symlinks = symlinks))


deploy_rpm = rule(
    attrs = {
        "target": attr.label(
            aspects = [collect_rpm_package_name],
            doc = "`assemble_rpm` target to deploy"
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = 'Properties file containing repo.rpm.(snapshot|release) key'
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "//rpm/templates:deploy.sh"
        )
    },
    outputs = {
        "deployment_script": "%{name}.sh",
    },
    implementation = _deploy_rpm_impl,
    executable = True,
    doc = 'Deploy package built with `assemble_rpm` to RPM repository'
)
