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

def _deploy_npm_impl(ctx):
    deploy_npm_script = ctx.actions.declare_file(ctx.attr.name)

    ctx.actions.expand_template(
        template = ctx.file._npm_deployer_wrapper_template,
        output = deploy_npm_script,
        substitutions = {
            "{deployer-path}": ctx.file._npm_deployer.short_path,
            "{npm-path}": ctx.file._npm.short_path,
            "{snapshot-repo}": ctx.attr.snapshot,
            "{release-repo}": ctx.attr.release,
        },
    )

    return DefaultInfo(
        executable = deploy_npm_script,
        runfiles = ctx.runfiles(
            files = [ctx.file.target, ctx.file._npm_deployer, ctx.file._npm],
            symlinks = {
                "deploy_npm.tgz": ctx.file.target,
            },
        ),
    )


deploy_npm = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "`assemble_npm` target to be included in the package",
        ),
        "snapshot": attr.string(
            mandatory = True,
            doc = 'Snapshot repository to deploy npm artifact to',
        ),
        "release": attr.string(
            mandatory = True,
            doc = 'Release repository to deploy npm artifact to',
        ),
        "_npm_deployer": attr.label(
            allow_single_file = True,
            default = "@vaticle_bazel_distribution//npm:deployer-bin_deploy.jar"
        ),
        "_npm_deployer_wrapper_template": attr.label(
            allow_single_file = True,
            default = "@vaticle_bazel_distribution//npm/templates:deploy.sh",
        ),
        "_npm": attr.label(
            allow_single_file = True,
            default = "@nodejs//:npm",
        ),
    },
    executable = True,
    implementation = _deploy_npm_impl,
    doc = """
    Deploy `assemble_npm` target into npm registry using token authentication

    ## How to generate an auth token

    ### On `npmjs.com`
    1. Sign in to the user account at https://npmjs.com that is used in your CI and has permissions to publish the package
    2. Navigate to the account's "Access Tokens", generate a new one and store it somewhere safe

    ### On `repo.vaticle.com`, or any other `npm` repository
    1. Run `npm adduser <repo_url>` (example: `npm adduser --registry=https://repo.vaticle.com/repository/npm-private`)
    2. When prompted, provide login credentials to sign in to the user account that is used in your CI and has permissions to publish the package
    3. If successful, a line will be added to your `.npmrc` file (`$HOME/.npmrc` on Unix) which looks like: `//repo.vaticle.com/repository/npm-snapshot/:_authToken=NpmToken.00000000-0000-0000-0000-000000000000`. The token is the value of `_authToken`, in this case `NpmToken.00000000-0000-0000-0000-000000000000`.
    4. Save the auth token somewhere safe and then delete it from your `.npmrc` file
    """,
)
