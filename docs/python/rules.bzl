#
#  Licensed to the Apache Software Foundation (ASF) under one
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

def _sphinx_docs_impl(ctx):
    package = ctx.actions.declare_directory("package")

    ctx.actions.run_shell(
        inputs = ctx.files.target,
        outputs = [package],
        command = 'PACKAGE=$(find . -name "*.tar.gz") && tar -xf ${PACKAGE} && mv */%s %s'
            % (ctx.attr.package_subdir, package.path),
    )

    args = ctx.actions.args()
    args.add('--output', ctx.outputs.out.path)
    args.add('--package', package.path)
    args.add('--source_dir', ctx.files.sphinx_conf[0].dirname)

    ctx.actions.run(
        inputs = [ctx.executable._script, package] + ctx.files.sphinx_conf + ctx.files.sphinx_rst,
        outputs = [ctx.outputs.out],
        arguments = [args],
        executable = ctx.executable._script,
        env = {"PYTHONPATH": package.path},
    )

    return DefaultInfo(files = depset([ctx.outputs.out]))


sphinx_docs = rule(
    attrs = {
        "_script": attr.label(
            default = ":sphinx_runner",
            executable = True,
            cfg = "exec",
            doc = "Script for running sphinx",
        ),
        "target": attr.label(
            mandatory = True,
            allow_files = True,
            doc = "Package including .tar.gz archive",
        ),
        "sphinx_conf": attr.label(
            mandatory = True,
            allow_files = True,
            doc = "Configuration file for the Sphinx documentation builder",
        ),
        "sphinx_rst": attr.label(
            mandatory = True,
            allow_files = True,
            doc = "Sphinx documentation master file for the package",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "Output directory",
        ),
        "package_subdir": attr.string(
            mandatory = True,
            doc = "Directory with the module files in the package archive",
        )
    },
    implementation = _sphinx_docs_impl,
    doc = """
        Creates an HTML documentation for python module using Sphinx.
        """
)
