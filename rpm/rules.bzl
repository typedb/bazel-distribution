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
load("//rpm/pkg_rpm_modified_from_bazel:rules.bzl", "pkg_rpm")


def assemble_rpm(name,
                     package_name,
                     version_file,
                     spec_file,
                     installation_dir = None,
                     archives = [],
                     empty_dirs = [],
                     files = {},
                     permissions = {},
                     symlinks = {}):
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
            aspects = [collect_rpm_package_name]
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True
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
)