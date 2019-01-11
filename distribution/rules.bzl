#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2018 Grakn Labs Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar", "pkg_deb")
load("//rpm/pkg_rpm_modified_from_bazel:rules.bzl", "pkg_rpm")

def _java_deps_impl(ctx):
    names = {}
    files = []
    newfiles = []

    for file in ctx.attr.target.data_runfiles.files.to_list():
        if file.extension == 'jar':
            names[file.path] = ctx.attr.java_deps_root + file.basename
            files.append(file)

    ctx.actions.run(
        outputs = [ctx.outputs.distribution],
        inputs = files,
        arguments = [str(names), ctx.outputs.distribution.path],
        executable = ctx.file._java_deps_builder,
        progress_message = "Generating tarball with Java deps: {}".format(
            ctx.outputs.distribution.short_path)
    )


def _tgz2zip_impl(ctx):
    ctx.actions.run(
        inputs = [ctx.file.tgz],
        outputs = [ctx.outputs.zip],
        executable = ctx.file._tgz2zip_py,
        arguments = [ctx.file.tgz.path, ctx.outputs.zip.path, ctx.attr.prefix],
        progress_message = "Converting {} to {}".format(ctx.file.tgz.short_path, ctx.outputs.zip.short_path)
    )

    return DefaultInfo(data_runfiles = ctx.runfiles(files=[ctx.outputs.zip]))


def distribution_deb(name,
                     package_name,
                     installation_dir,
                     maintainer,
                     version_file,
                     description,
                     distribution_structures = [],
                     empty_dirs = [],
                     files = {},
                     depends = [],
                     symlinks = {},
                     permissions = {}):
    tar_name = "_{}-deb-tar".format(package_name)
    pkg_tar(
        name = tar_name,
        extension = "tar.gz",
        deps = distribution_structures,
        package_dir = installation_dir,
        empty_dirs = empty_dirs,
        files = files,
        mode = "0755",
        symlinks = symlinks,
        modes = permissions,
    )

    pkg_deb(
        name = name,
        data = tar_name,
        package = package_name,
        depends = depends,
        maintainer = maintainer,
        version_file = version_file,
        description = description
    )


def distribution_rpm(name,
                     package_name,
                     installation_dir,
                     version_file,
                     spec_file,
                     distribution_structures = [],
                     empty_dirs = [],
                     files = {},
                     permissions = {},
                     symlinks = {}):
    tar_name = "_{}-rpm-tar".format(package_name)
    rpm_version_file = "_{}-rpm-version".format(package_name)

    native.genrule(
        name = rpm_version_file,
        srcs = [version_file],
        outs = [rpm_version_file.replace("-version", ".VERSION")],
        cmd = "sed -e 's|-|_|g' $< > $@"
        # replaces any `-` with `_` since RPM does not allow a version number containing a `-` such as `1.5.0-SNAPSHOT`
    )

    pkg_tar(
        name = tar_name,
        extension = "tar.gz",
        deps = distribution_structures,
        package_dir = installation_dir,
        empty_dirs = empty_dirs,
        files = files,
        mode = "0755",
        symlinks = symlinks,
        modes = permissions,
    )

    if "osx_build" not in native.existing_rules():
        native.config_setting(
           name = "osx_build",
           constraint_values = [
               "@bazel_tools//platforms:osx",
               "@bazel_tools//platforms:x86_64",
           ]
        )

    if "linux_build" not in native.existing_rules():
        native.config_setting(
            name = "linux_build",
            constraint_values = [
                "@bazel_tools//platforms:linux",
                "@bazel_tools//platforms:x86_64",
            ]
        )

    pkg_rpm(
        name = name,
        architecture = "x86_64",
        spec_file = spec_file,
        version_file = rpm_version_file,
        data = [tar_name],
        rpmbuild_path = select({
            ":linux_build": "/usr/bin/rpmbuild",
            ":osx_build": "/usr/local/bin/rpmbuild",
        })
    )

def distribution_structure(name,
                           visibility = ["//visibility:private"],
                           targets = {},
                           additional_files = {},
                           empty_directories = [],
                           permissions = {}):
    all_java_deps = []
    for target, java_deps_root in targets.items():
        target_name = "{}-deps".format(Label(target).package)
        java_deps(
            name = target_name,
            target = target,
            java_deps_root = java_deps_root
        )
        all_java_deps.append(target_name)

    pkg_tar(
        name=name,
        deps = all_java_deps,
        extension = "tar.gz",
        mode = "0755",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
        visibility = visibility
    )


def distribution_zip(name,
                     output_filename,
                     distribution_structures = [],
                     additional_files = {},
                     empty_directories = [],
                     permissions = {}):
    pkg_tar(
        name="{}-tgz".format(name),
        deps = distribution_structures,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
    )

    tgz2zip(
        name = name,
        tgz = ":{}-tgz".format(name),
        output_filename = output_filename,
        prefix = "./" + output_filename,
        visibility = ["//visibility:public"]
    )


java_deps = rule(
    attrs = {
        "target": attr.label(mandatory=True),
        "java_deps_root": attr.string(
            default = "services/lib/",
            doc = "Folder inside archive to put JARs into"
        ),
        "_java_deps_builder": attr.label(
              allow_single_file = True,
              default="//distribution:java_deps.py"
        )
    },
    implementation = _java_deps_impl,
    outputs = {
        "distribution": "%{name}.tgz"
    },
)

tgz2zip = rule(
    attrs = {
        "tgz": attr.label(
            allow_single_file=[".tar.gz"],
            mandatory = True
        ),
        "output_filename": attr.string(
            mandatory = True,
        ),
        "prefix": attr.string(
            default="."
        ),
        "_tgz2zip_py": attr.label(
            allow_single_file = True,
            default="//distribution:tgz2zip.py"
        )
    },
    implementation = _tgz2zip_impl,
    outputs = {
        "zip": "%{output_filename}.zip"
    },
    output_to_genfiles = True
)
