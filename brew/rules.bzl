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

    substitution_files = {}
    for file, key in ctx.attr.file_substitutions.items():
        if len(file.files.to_list()) != 1:
            fail(
                "deploy_brew() expects single files as keys in the `file_substitutions` parameter, " +
                "received {} files in {}".format(len(file.files.to_list()), file)
            )
        else:
            substitution_files[key] = file.files.to_list()[0]

    ctx.actions.expand_template(
        template = ctx.file._deploy_brew_template,
        output = ctx.outputs.deployment_script,
        substitutions = {
            '{brew_folder}': brew_formula_folder,
            '{snapshot}' : ctx.attr.snapshot,
            '{release}' : ctx.attr.release,
            '{substitution_files}': json.encode({key: file.path for key, file in substitution_files.items()}),
        },
        is_executable = True,
    )

    if not ctx.attr.version_file:
        version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
        version = ctx.var.get('version', '0.0.0')

        ctx.actions.run_shell(
            inputs = [],
            outputs = [version_file],
            command = "echo {} > {}".format(version, version_file.path)
        )
    else:
        version_file = ctx.file.version_file

    files = [
        ctx.file.formula,
        version_file,
    ] + list(substitution_files.values())

    symlinks = {
        'formula': ctx.file.formula,
        'VERSION': version_file,
    }

    return DefaultInfo(
        runfiles = ctx.runfiles(files = files),
        executable = ctx.outputs.deployment_script
    )


deploy_brew = rule(
    attrs = {
        "file_substitutions": attr.label_keyed_string_dict(
            allow_files = True,
            doc = """
            Substitute file contents into the formula.
            Key: file to read the substitution from.
            Value: placeholder in the formula template to substitute.
            """
        ),
        "type": attr.string(
            values = ["brew", "cask"],
            default = "brew",
            doc = """
            Type of deployment (Homebrew/Caskroom).
            Cask is generally used for graphic applications
            """
        ),
        "snapshot" : attr.string(
            mandatory = True,
            doc = 'Snapshot repository to deploy brew artifact to'
        ),
        "release" : attr.string(
            mandatory = True,
            doc = 'Release repository to deploy brew artifact to'
        ),
        "formula": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The brew formula definition"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """
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
    implementation = _deploy_brew_impl,
    doc = """Deploy Homebrew (Caskroom) formula to Homebrew tap.

    Select deployment to `snapshot` or `release` repository with `bazel run //:some-deploy-brew -- [snapshot|release]
    """
)
