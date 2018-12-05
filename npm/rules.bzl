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

def _deploy_npm_impl(ctx):
    preprocessed_deploy_script = ctx.actions.declare_file('_deploy.sh')

    ctx.actions.expand_template(
        output = preprocessed_deploy_script,
        template = ctx.file._deployment_script_template,
        substitutions = {
            "$BAZEL_PACKAGE_NAME": ctx.attr.target.label.package,
            "$BAZEL_TARGET_NAME": ctx.attr.target.label.name,
        }
    )

    ctx.actions.run_shell(
        inputs = [preprocessed_deploy_script, ctx.file.version_file],
        outputs = [ctx.outputs.deployment_script],
        command = "VERSION=`cat %s` && sed -e s/{version}/$VERSION/g %s > %s" % (
                    ctx.file.version_file.path, preprocessed_deploy_script.path, ctx.outputs.deployment_script.path)
    )

    return DefaultInfo(executable = ctx.outputs.deployment_script,
                       runfiles = ctx.runfiles(
                           files = ctx.files.target + ctx.files._node_runfiles + [ctx.file.deployment_properties],
                           symlinks = {
                               "deployment.properties": ctx.file.deployment_properties
                           }))

deploy_npm = rule(
    implementation = _deploy_npm_impl,
    attrs = {
        "target": attr.label(
            mandatory = True,
            doc = "`npm_library` label to be included in the package",
        ),
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing version string"
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing Node repository url by `npm.repository-url` key"
        ),
        "_deployment_script_template": attr.label(
            allow_single_file = True,
            default = "//npm/templates:deploy.sh",
        ),
        "_node_runfiles": attr.label(
            default = Label("@nodejs//:node_runfiles"),
            allow_files = True
        )
    },
    executable = True,
    outputs = {
          "deployment_script": "%{name}.sh",
    }
)