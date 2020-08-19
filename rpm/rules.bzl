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

load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@rules_pkg//:rpm.bzl", "pkg_rpm")


def _assemble_rpm_version_file_impl(ctx):
    version = ctx.var.get('version', '0.0.0')

    if len(version) == 40:
        # this is a commit SHA, most likely
        version = "0.0.0_{}".format(version)

    ctx.actions.run_shell(
        inputs = [],
        outputs = [ctx.outputs.version_file],
        command = "echo {} > {}".format(version, ctx.outputs.version_file.path)
    )


_assemble_rpm_version_file = rule(
    outputs = {
        "version_file": "%{name}.version"
    },
    implementation = _assemble_rpm_version_file_impl
)

def assemble_rpm(name,
                 package_name,
                 spec_file,
                 version_file = None,
                 workspace_refs = None,
                 installation_dir = None,
                 archives = [],
                 empty_dirs = [],
                 files = {},
                 permissions = {},
                 symlinks = {},
                 tags = []):
    """Assemble package for installation with RPM

    Args:
        name: A unique name for this target.
        package_name: Package name for built .rpm package
        spec_file: The RPM spec file to use
        version_file: File containing version number of a package.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version defaults to '0.0.0'
        workspace_refs: JSON file with other Bazel workspace references
        installation_dir: directory into which .rpm package is unpacked at installation
        archives: Bazel labels of archives that go into .rpm package
        empty_dirs: list of empty directories created at package installation
        files: mapping between Bazel labels of archives that go into .rpm package
            and their resulting location on .rpm package installation
        permissions: mapping between paths and UNIX permissions
        symlinks: mapping between source and target of symbolic links
                    created at installation
        tags: additional tags passed to all wrapped rules
    """
    tag = "rpm_package_name={}".format(spec_file.split(':')[-1].replace('.spec', ''))
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
            tags = tags,
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
            ],
            tags = tags,
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
            tools = ["@graknlabs_bazel_distribution//rpm:generate_spec_file"],
            tags = tags,
        )
        spec_file = modified_spec_target_name

    if not version_file:
        version_file = name + "__version__do_not_reference"
        _assemble_rpm_version_file(
            name = version_file
        )

    pkg_rpm(
        name = "{}__do_not_reference__rpm".format(name),
        architecture = "x86_64",
        spec_file = spec_file,
        version_file = version_file,
        release = "1",
        data = rpm_data,
        rpmbuild_path = select({
            ":linux_build": "/usr/bin/rpmbuild",
            ":osx_build": "/usr/local/bin/rpmbuild",
            "//conditions:default": ""
        }),
        tags = tags,
    )

    native.genrule(
        name = name,
        srcs = ["{}__do_not_reference__rpm".format(name)],
        cmd = "cp $$(echo $(SRCS) | awk '{print $$1}') $@",
        outs = [package_name + ".rpm"],
        tags = [tag] + tags,
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
            "{RPM_PKG}": ctx.attr.target[RpmInfo].package_name,
            "{snapshot}": ctx.attr.snapshot,
            "{release}": ctx.attr.release,
        },
        is_executable = True
    )

    symlinks = {
        'package.rpm': ctx.files.target[0],
    }

    return DefaultInfo(executable = ctx.outputs.deployment_script,
                       runfiles = ctx.runfiles(
                           files=[ctx.files.target[0]],
                           symlinks = symlinks))


deploy_rpm = rule(
    attrs = {
        "target": attr.label(
            aspects = [collect_rpm_package_name],
            doc = "`assemble_rpm` target to deploy"
        ),
        "snapshot": attr.string(
            mandatory = True,
            doc = "Remote repository to deploy rpm snapshot to"
        ),
        "release": attr.string(
            mandatory = True,
            doc = "Remote repository to deploy rpm release to"
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "//rpm/templates:deploy.py"
        ),
    },
    outputs = {
        "deployment_script": "%{name}.py",
    },
    implementation = _deploy_rpm_impl,
    executable = True,
    doc = 'Deploy package built with `assemble_rpm` to RPM repository'
)
