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

def _assemble_versioned_impl(ctx):
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

    # assemble-version.py $output $version $targets
    ctx.actions.run(
        inputs = ctx.files.targets + [version_file],
        outputs = [ctx.outputs.archive],
        executable = ctx.executable._assemble_versioned_py,
        arguments = [ctx.outputs.archive.path, version_file.path] + [target.path for target in ctx.files.targets],
        progress_message = "Versioning assembled distributions to {}".format(version_file.short_path)
    )

    return DefaultInfo(data_runfiles = ctx.runfiles(files=[ctx.outputs.archive]))

assemble_versioned = rule(
    attrs = {
        "targets": attr.label_list(
            allow_files = [".zip", ".tar.gz"],
            doc = "Archives to version and put into output archive"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = "File containing version string"
        ),
        "_assemble_versioned_py": attr.label(
            default = "//common/assemble_versioned:assemble-versioned",
            executable = True,
            cfg = "host"
        )
    },
    implementation = _assemble_versioned_impl,
    outputs = {
        "archive": "%{name}.zip"
    },
    output_to_genfiles = True,
    doc = "Version multiple archives for subsequent simultaneous deployment"
)
