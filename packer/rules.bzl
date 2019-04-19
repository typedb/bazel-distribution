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

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

def assemble_packer(name,
                    config,
                    files = {}):
    _files = {
        config: "config.json"
    }
    for k, v in files.items():
        _files[k] = "files/" + v
    pkg_tar(
        name = name,
        extension = "packer.tar",
        files = _files
    )

def _deploy_packer_impl(ctx):
    deployment_script = ctx.actions.declare_file("{}_deploy_packer.py".format(ctx.attr.target.label.name))

    ctx.actions.expand_template(
        template = ctx.file._deployment_script_template,
        output = deployment_script,
        substitutions = {
            "{packer_osx_binary}": ctx.files._packer[0].path,
            "{packer_linux_binary}": ctx.files._packer[1].path,
            "{target_tar}": ctx.file.target.short_path
        },
        is_executable = True
    )

    return DefaultInfo(
        executable = deployment_script,
        runfiles = ctx.runfiles(files = [ctx.file.target] + ctx.files._packer)
    )

deploy_packer = rule(
    attrs = {
        "target": attr.label(
            mandatory = False,
            allow_single_file = [".packer.tar"],
            doc = "Distribution to be deployed.",
        ),
        "_deployment_script_template": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//packer/templates:deploy_packer.py",
        ),
        "_packer": attr.label_list(
            allow_files = True,
            default = ["@packer_osx//:packer", "@packer_linux//:packer"]
        ),
    },
    executable = True,
    implementation = _deploy_packer_impl
)
