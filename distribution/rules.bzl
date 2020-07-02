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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _deploy_distribution_impl(ctx):
    _deploy_script = ctx.actions.declare_file("{}_deploy.py".format(ctx.attr.name))

    version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
    version = ctx.var.get('version', '0.0.0')

    ctx.actions.run_shell(
        inputs = [],
        outputs = [version_file],
        command = "echo {} > {}".format(version, version_file.path),
    )
    
    ctx.actions.expand_template(
        template = ctx.file._deploy_script,
        output = _deploy_script,
        substitutions = {
            "{version_file}": version_file.short_path,
            "{artifact_path}": ctx.file.target.short_path,
            "{artifact_group}": ctx.attr.artifact_group,
        },
    )
    files = [
        ctx.file.target,
        ctx.file.deployment_properties,
        version_file,
        ctx.file._common_py
    ]

    symlinks = {
        "deployment.properties": ctx.file.deployment_properties,
        "common.py": ctx.file._common_py,
        'VERSION': version_file,
    }

    return DefaultInfo(
        executable = _deploy_script,
        runfiles = ctx.runfiles(
            files = files,
            symlinks = symlinks,
        ),
    )


deploy_distribution = rule(
    attrs = {
        "target": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File to deploy to repo",
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing repository url by `repo.distribution` key",
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """,
        ),
        "artifact_group": attr.string(
            mandatory = True,
            doc = "The group of the artifact.",
        ),
        "_deploy_script": attr.label(
            allow_single_file = True,
            default = "//distribution/templates:deploy.py",
        ),
        "_common_py": attr.label(
            allow_single_file = True,
            default = "//common:common.py",
        ),
    },
    executable = True,
    implementation = _deploy_distribution_impl,
    doc = "Deploy archive target into a raw repo",
)

def distribution_file(name,
                      repository_url,
                      group_name,
                      artifact_name,
                      extension,
                      commit = None,
                      tag = None,
                      output_filename = None,
                      sha = None,
                      tags = []):

    repo_name = "distribution" if tag != None else "distribution-snapshot"
    filename = "{}.{}".format(artifact_name, extension)
    version = tag if tag != None else commit
    versiontype = "tag" if tag != None else "commit"

    http_file(
        name = name,
        urls = ["{}/{}/{}/{}/{}/{}".format(repository_url, repo_name, group_name, artifact_name, version, filename)],
        downloaded_file_path = filename,
        sha = sha,
        tags = tags + ["{}={}".format(versiontype, version)]
    )
