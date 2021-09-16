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
    _deploy_script = ctx.actions.declare_file("{}_deploy.py".format(ctx.attr.name))

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

    ctx.actions.expand_template(
        template = ctx.file._deploy_script,
        output = _deploy_script,
        substitutions = {
            "{organisation}" : ctx.attr.organisation,
            "{repository}" : ctx.attr.repository,
            "{title}": ctx.attr.title or "",
            "{title_append_version}": str(bool(ctx.attr.title_append_version)),
            "{release_description}": str(bool(ctx.file.release_description)),
            "{archive}": ctx.file.archive.short_path if (ctx.file.archive!=None) else "",
            "{draft}": str(bool(ctx.attr.draft)),
            "{ghr_binary_mac}": ctx.files._ghr[0].path,
            "{ghr_binary_linux}": ctx.files._ghr[1].path,
            "{ghr_binary_windows}": ctx.files._ghr[2].path,
        }
    )
    files = [
        version_file,
    ] + ctx.files._ghr

    if ctx.file.archive!=None:
        files.append(ctx.file.archive)

    symlinks = {
        'VERSION': version_file
    }

    if ctx.file.release_description:
        files.append(ctx.file.release_description)
        symlinks["release_description.txt"] = ctx.file.release_description

    deploy_script_runner = ctx.actions.declare_file("{}_deploy_runner{}".format(ctx.attr.name, ".bat" if ctx.attr.windows else ""))

    ctx.actions.write(
        content = "type MANIFEST && python {}".format(_deploy_script.path if ctx.attr.windows else _deploy_script.short_path),
        output = deploy_script_runner,
        is_executable = True,
    )

    files.append(_deploy_script)

    return DefaultInfo(
        executable = deploy_script_runner,
        runfiles = ctx.runfiles(
            files = files,
            symlinks = symlinks
        ),
    )


deploy_github = rule(
    attrs = {
        "organisation" : attr.string(
            mandatory = True,
            doc = "Github organisation to deploy to",
        ),
        "repository" : attr.string(
            mandatory = True,
            doc = "Github repository to deploy to within organisation",
        ),
        "title": attr.string(
            mandatory = False,
            doc = "Title of GitHub release"
        ),
        "title_append_version": attr.bool(
            default = False,
            doc = "Append version to GitHub release title"
        ),
        "release_description": attr.label(
            allow_single_file = True,
            doc = "Description of GitHub release"
        ),
        "archive": attr.label(
            mandatory = False,
            allow_single_file = [".zip"],
            doc = "`assemble_versioned` label to be deployed.",
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """
        ),
        "draft": attr.bool(
            default = True,
            doc = """
            Creates an unpublished / draft release when set to True.
            Defaults to True.
            """
        ),
        "_deploy_script": attr.label(
            allow_single_file = True,
            default = "//github/templates:deploy.py",
        ),
        "_ghr": attr.label_list(
            allow_files = True,
            default = ["@ghr_osx_zip//:ghr", "@ghr_linux_tar//:ghr", "@ghr_windows_zip//:ghr.exe"],
        ),
        "windows": attr.bool(
            default = False,
        ),
    },
    implementation = _deploy_github_impl,
    executable = True,
    doc = "Deploy `assemble_versioned` target to GitHub Releases"
)
