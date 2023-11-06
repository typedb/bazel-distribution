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

load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@vaticle_bazel_distribution//common/java_deps:rules.bzl", "java_deps")

def _assemble_targz_package_dir_file_impl(ctx):
    version = ctx.var.get('version', '')

    package_dir = ctx.attr.package_dir
    if package_dir and version and ctx.attr.append_version:
        package_dir = '{}-{}'.format(package_dir, version)

    ctx.actions.run_shell(
        inputs = [],
        outputs = [ctx.outputs.package_dir_file],
        command = "echo {} > {}".format(package_dir, ctx.outputs.package_dir_file.path)
    )


_assemble_targz_package_dir_file = rule(
    attrs = {
        "append_version": attr.bool(default=True),
        "package_dir": attr.string()
    },
    outputs = {
        "package_dir_file": "%{name}.package_dir"
    },
    implementation = _assemble_targz_package_dir_file_impl
)

def assemble_targz(name,
                   output_filename = None,
                   targets = [],
                   additional_files = {},
                   empty_directories = [],
                   permissions = {},
                   append_version = True,
                   visibility = ["//visibility:private"],
                   tags = [],
                   target_compatible_with = []):
    """Assemble distribution archive (.tar.gz)

    Args:
        name: A unique name for this target.
        output_filename: filename of resulting archive
        targets: Bazel labels of archives that go into .tar.gz package
        additional_files: mapping between Bazel labels of files that go into archive
            and their resulting location in archive
        empty_directories: list of empty directories created at archive installation
        permissions: mapping between paths and UNIX permissions
        append_version: append version to root folder inside the archive
        visibility: controls whether the target can be used by other packages
    """
    pkg_tar(
        name = "{}__do_not_reference__targz_0".format(name),
        deps = targets,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
        tags = tags,
        target_compatible_with = target_compatible_with,
    )

    _assemble_targz_package_dir_file(
        name = "{}__do_not_reference__pkgdir".format(name),
        package_dir = output_filename,
        append_version = append_version
    )

    output_filename = output_filename or name
    pkg_tar(
        name = name,
        deps = [":{}__do_not_reference__targz_0".format(name)],
        package_dir_file = "{}__do_not_reference__pkgdir".format(name),
        out = output_filename + ".tar.gz",
        extension = "tar.gz",
        visibility = visibility,
        tags = tags,
    )

def targz_edit(name, src, strip_components = 0, **kwargs):
    extra_args = ["--strip-components", str(strip_components)]
    native.genrule(
        name = name,
        outs = [name],
        srcs = [src],
        cmd_bash =
            "mkdir -p tmpdir &&" +
            "tar -xzf $< -C tmpdir {} &&".format(" ".join(extra_args)) +
            "tar -czf $@ -C tmpdir --strip-components=1 .",
        **kwargs
    )
