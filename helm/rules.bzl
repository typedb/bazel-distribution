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

def _deploy_helm_impl(ctx):
    _deploy_script = ctx.actions.declare_file(ctx.attr.deploy_script_name)
    ctx.actions.expand_template(
        template = ctx.file._deploy_script_template,
        output = _deploy_script,
        substitutions = {
            "{chart_path}": ctx.file.chart.short_path,
            "{release}": ctx.attr.release,
            "{snapshot}": ctx.attr.snapshot,
        },
    )

    cloudsmith_lib_files = ctx.attr._cloudsmith_pylib[DefaultInfo].default_runfiles.files.to_list()
    return DefaultInfo(
        executable = _deploy_script,
        runfiles = ctx.runfiles(
            files = [ctx.file.chart] + cloudsmith_lib_files
        ),
    )

_deploy_helm = rule(
    attrs = {
        "chart": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Chart to deploy to repo",
        ),
        "_cloudsmith_pylib": attr.label(
            default = "//common/cloudsmith:cloudsmith-wrapper",
        ),
        "_deploy_script_template": attr.label(
            allow_single_file = True,
            default = "//helm/templates:deploy.py",
        ),
        "deploy_script_name": attr.string(
            mandatory = True,
            doc = 'Name of instantiated deployment script'
        ),
        "release": attr.string(
            mandatory = True,
            doc = "Repository that the release chart will be uploaded to"
        ),
        "snapshot": attr.string(
            mandatory = True,
            doc = "Repository that the snapshot chart will be uploaded to"
        ),
    },
    executable = True,
    implementation = _deploy_helm_impl,
    doc = "Deploy helm chart into a raw repo",
)

def deploy_helm(name, chart, snapshot, release, **kwargs):
    deploy_script_target_name = name + "__deploy"
    deploy_script_name = deploy_script_target_name + "-deploy.py"

    _deploy_helm(
        name = deploy_script_target_name,
        chart = chart,
        deploy_script_name = deploy_script_name,
        snapshot = snapshot,
        release = release,
        **kwargs
    )

    native.py_binary(
        name = name,
        srcs = [deploy_script_target_name],
        main = deploy_script_name,
    )
