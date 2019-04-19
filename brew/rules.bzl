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

def _deploy_brew_impl(ctx):
    if ctx.attr.type == "brew":
        brew_formula_folder = "Formula"
    elif ctx.attr.type == "cask":
        brew_formula_folder = "Casks"

    ctx.actions.expand_template(
        template = ctx.file._deploy_brew_template,
        output = ctx.outputs.deployment_script,
        substitutions = {
            "{brew_folder}": brew_formula_folder
        },
        is_executable = True
    )
    files = [
        ctx.file.deployment_properties,
        ctx.file.formula,
        ctx.file.version_file
    ]

    symlinks = {
        'deployment.properties': ctx.file.deployment_properties,
        'formula': ctx.file.formula,
        'VERSION': ctx.file.version_file
    }

    if ctx.file.checksum:
        files.append(ctx.file.checksum)
        symlinks['checksum.sha256'] = ctx.file.checksum

    return DefaultInfo(
        runfiles = ctx.runfiles(
            files = files,
            symlinks = symlinks
        ),
        executable = ctx.outputs.deployment_script
    )


deploy_brew = rule(
    attrs = {
        "checksum": attr.label(
            allow_single_file = True,
        ),
        "type": attr.string(
            values = ["brew", "cask"],
            default = "brew"
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "formula": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The brew formula definition"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "_deploy_brew_template": attr.label(
            allow_single_file = True,
            default = "//brew/templates:deploy.py"
        ),
    },
    executable = True,
    outputs = {
        "deployment_script": "%{name}.py"
    },
    implementation = _deploy_brew_impl
)