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


def _old_distribution_impl(ctx):
    # files to put into archive
    files = []
    # maps real fs paths to paths inside archive
    names = {}

    for target in ctx.attr.targets:
        for file in target.data_runfiles.files.to_list():
            if file.extension == 'jar':
                names[file.path] = ctx.attr.java_deps_root + file.basename
                files.append(file)

    for label, filename in ctx.attr.additional_files.items():
        if len(label.files.to_list()) != 1:
            fail("should specify target producing single file instead of {}".format(label))
        single_file = label.files.to_list()[0]
        names[single_file.path] = filename

    archiver_script = ctx.actions.declare_file('_archiver.py')

    ctx.actions.expand_template(
        template = ctx.file._distribution_py,
        output = archiver_script,
        substitutions = {
            "{moves}": str(names),
            "{distribution_zip_location}": ctx.outputs.distribution.path,
            "{empty_directories}": str(ctx.attr.empty_directories)
        },
        is_executable = True
    )

    ctx.actions.run(
        outputs = [ctx.outputs.distribution],
        inputs = files + ctx.files.additional_files,
        executable = archiver_script
    )

    return DefaultInfo(data_runfiles = ctx.runfiles(files=[ctx.outputs.distribution]))

def _tgz2zip_impl(ctx):
    ctx.actions.run(
        inputs = [ctx.file.tgz],
        outputs = [ctx.outputs.zip],
        executable = ctx.file._tgz2zip_py,
        arguments = [ctx.file.tgz.path, ctx.outputs.zip.path],
        progress_message = "Converting {} to {}".format(ctx.file.tgz.short_path, ctx.outputs.zip.short_path)
    )

    return DefaultInfo(data_runfiles = ctx.runfiles(files=[ctx.outputs.zip]))

def deploy_deb(package_name,
               installation_dir,
               maintainer,
               version_file,
               description,
               postinst = None,
               prerm = None,
               target = None,
               empty_dirs = [],
               files = {},
               depends = [],
               symlinks = {},
               modes = {}):
    java_deps_tar = []
    if target:
        java_deps(
            name = "_{}-deps".format(package_name),
            target = target,
            java_deps_root = "services/lib/"
        )
        java_deps_tar.append("_{}-deps".format(package_name))

    pkg_tar(
        name = "_{}-tar".format(package_name),
        extension = "tgz",
        deps = java_deps_tar,
        package_dir = installation_dir,
        empty_dirs = empty_dirs,
        files = files,
        symlinks = symlinks,
        modes = modes,
    )

    pkg_deb(
        name = "deploy-deb",
        data = "_{}-tar".format(package_name),
        package = package_name,
        depends = depends,
        maintainer = maintainer,
        version_file = version_file,
        postinst = postinst,
        prerm = prerm,
        description = description
    )


def distribution(targets,
                 additional_files,
                 output_filename,
                 empty_directories = [],
                 modes = {}):
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
        name="distribution_tgz",
        deps = all_java_deps,
        extension = "tgz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = modes,
    )

    tgz2zip(
        name = "distribution",
        tgz = ":distribution_tgz",
        output_filename = output_filename,
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
            allow_single_file=[".tgz"],
            mandatory = True
        ),
        "output_filename": attr.string(
            mandatory = True,
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

old_distribution = rule(
    attrs = {
        "targets": attr.label_list(mandatory=True),
        "java_deps_root": attr.string(
            default = "services/lib/",
            doc = "Folder inside archive to put JARs into"
        ),
        "additional_files": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Additional files to put into the archive"
        ),
        "empty_directories": attr.string_list(
            doc = "List of names to create empty directories inside the archive"
        ),
        "output_filename": attr.string(
            doc = "Filename for result of rule execution",
            mandatory = True
        ),
        "_distribution_py": attr.label(
            allow_single_file = True,
            default="//distribution:archiver.py"
        )
    },
    implementation = _old_distribution_impl,
    outputs = {
        "distribution": "%{output_filename}.zip"
    },
    output_to_genfiles = True,
    doc = "Create a distribution of Java program(s) containing additional files"
)
