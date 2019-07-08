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

def _assemble_npm_impl(ctx):
    if len(ctx.files.target) != 1:
        fail("target contains more files than expected")
    args = ctx.actions.args()
    args.add('--package', ctx.files.target[0].path)
    args.add('--output', ctx.outputs.npm_package.path)
    args.add('--version_file', ctx.file.version_file.path)

    ctx.actions.run(
        inputs = ctx.files.target + ctx.files._node_runfiles + [ctx.file.version_file],
        outputs = [ctx.outputs.npm_package],
        arguments = [args],
        executable = ctx.executable._assemble_script,
        execution_requirements = {
            "local": "1"
        }
    )


assemble_npm = rule(
    implementation = _assemble_npm_impl,
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
        "_assemble_script": attr.label(
            default = "//npm:assemble",
            executable = True,
            cfg = "host"
        ),
        "_node_runfiles": attr.label(
            default = Label("@nodejs//:node_runfiles"),
            allow_files = True
        )
    },
    outputs = {
          "npm_package": "%{name}.tar.gz",
    },
    doc = "Assemble `npm_package` target for further deployment"
)


def _deploy_npm(ctx):
    ctx.actions.expand_template(
        template = ctx.file._deployment_script_template,
        output = ctx.outputs.executable,
        substitutions = {},
        is_executable = True
    )

    files = [
        ctx.file.target,
        ctx.file.deployment_properties,
        ctx.file._common_py
    ]
    files.extend(ctx.files._node_runfiles)

    return DefaultInfo(
        executable = ctx.outputs.executable,
        runfiles = ctx.runfiles(
            files = files,
            symlinks = {
                "deploy_npm.tgz": ctx.file.target,
                "deployment.properties": ctx.file.deployment_properties,
                "common.py": ctx.file._common_py
            }))


deploy_npm = rule(
    implementation = _deploy_npm,
    executable = True,
    attrs = {
        "target": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "`assemble_npm` label to be included in the package",
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing Node repository url by `repo.npm` key"
        ),
        "_deployment_script_template": attr.label(
            allow_single_file = True,
            default = "//npm/templates:deploy.py",
        ),
        "_common_py": attr.label(
            allow_single_file = True,
            default = "//common:common.py"
        ),
        "_node_runfiles": attr.label(
            default = Label("@nodejs//:node_runfiles"),
            allow_files = True
        ),
    },
)
