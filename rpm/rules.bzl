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

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar", "pkg_deb")
load("//rpm/pkg_rpm_modified_from_bazel:rules.bzl", "pkg_rpm")


def assemble_rpm(name,
                     package_name,
                     installation_dir,
                     version_file,
                     spec_file,
                     archives = [],
                     empty_dirs = [],
                     files = {},
                     permissions = {},
                     symlinks = {}):
    tar_name = "_{}-rpm-tar".format(package_name)
    rpm_version_file = "_{}-rpm-version".format(package_name)

    native.genrule(
        name = rpm_version_file,
        srcs = [version_file],
        outs = [rpm_version_file.replace("-version", ".VERSION")],
        cmd = "sed -e 's|-|_|g' $< > $@"
        # replaces any `-` with `_` since RPM does not allow a version number containing a `-` such as `1.5.0-SNAPSHOT`
    )

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
        version_file = rpm_version_file,
        data = [tar_name],
        rpmbuild_path = select({
            ":linux_build": "/usr/bin/rpmbuild",
            ":osx_build": "/usr/local/bin/rpmbuild",
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