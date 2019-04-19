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

def _deploy_github_impl(ctx):
    _deploy_script = ctx.actions.declare_file("_deploy.py")

    ctx.actions.expand_template(
        template = ctx.file._deploy_script,
        output = _deploy_script,
        substitutions = {
            "{archive}": ctx.file.archive.short_path if (ctx.file.archive!=None) else "",
            "{has_release_description}": str(int(bool(ctx.file.release_description))),
            "{ghr_osx_binary}": ctx.files._ghr[0].path,
            "{ghr_linux_binary}": ctx.files._ghr[1].path,
        }
    )
    files = [
        ctx.file.deployment_properties,
        ctx.file.version_file
    ] + ctx.files._ghr

    if ctx.file.archive!=None:
        files.append(ctx.file.archive)

    symlinks = {
        "deployment.properties": ctx.file.deployment_properties
    }

    if ctx.file.release_description:
        files.append(ctx.file.release_description)
        symlinks["release_description.txt"] = ctx.file.release_description

    return DefaultInfo(
        executable = _deploy_script,
        runfiles = ctx.runfiles(
            files = files,
            symlinks = symlinks
        ),
    )


deploy_github = rule(
    attrs = {
        "archive": attr.label(
            mandatory = False,
            allow_single_file = [".zip"],
            doc = "`assemble_versioned` label to be deployed.",
        ),
        "release_description": attr.label(
            allow_single_file = True,
            doc = "Description of GitHub release"
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing `repo.github.organisation` and `repo.github.repository` keys"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing version string"
        ),
        "_deploy_script": attr.label(
            allow_single_file = True,
            default = "//github:deploy.py",
        ),
        "_ghr": attr.label_list(
            allow_files = True,
            default = ["@ghr_osx_zip//:ghr", "@ghr_linux_tar//:ghr"]
        )
    },
    implementation = _deploy_github_impl,
    executable = True
)
