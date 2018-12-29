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

def _java_deps_impl(ctx):
    names = {}
    files = []
    newfiles = []

    for target in ctx.attr.targets:
        for file in target.data_runfiles.files.to_list():
            if file.extension == 'jar':
                names[file.path] = ctx.attr.java_deps_root + file.basename
                files.append(file)


    java_deps_builder = ctx.actions.declare_file('_java_deps.py')

    ctx.actions.expand_template(
        template = ctx.file._java_deps_builder,
        output = java_deps_builder,
        substitutions = {
            "{moves}": str(names),
            "{distribution_tgz_location}": ctx.outputs.distribution.path,
        },
        is_executable = True
    )

    ctx.actions.run(
        outputs = [ctx.outputs.distribution],
        inputs = files,
        executable = java_deps_builder
    )


def _distribution_impl(ctx):
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


load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar", "pkg_deb")
def deploy_deb(name,
               package_dir,
               maintainer,
               version_file,
               description,
               postinst = None,
               prerm = None,
               target = None,
               empty_dirs = [],
               files = {},
               depends = []):
    java_deps_tar = []
    if target:
        java_deps(
            name = "_{}-deps".format(name),
            targets = [target],
            java_deps_root = "services/lib/"
        )
        java_deps_tar.append("_{}-deps".format(name))

    pkg_tar(
        name = "_{}-tar".format(name),
        extension = "tgz",
        deps = java_deps_tar,
        package_dir = package_dir,
        empty_dirs = empty_dirs,
        files = files,
    )

    pkg_deb(
        name = "{}-deb".format(name),
        data = "_{}-tar".format(name),
        package = name,
        depends = depends,
        maintainer = maintainer,
        version_file = version_file,
        postinst = postinst,
        prerm = prerm,
        description = description
    )


java_deps = rule(
    attrs = {
        "targets": attr.label_list(mandatory=True),
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

distribution = rule(
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
    implementation = _distribution_impl,
    outputs = {
        "distribution": "%{output_filename}.zip"
    },
    output_to_genfiles = True,
    doc = "Create a distribution of Java program(s) containing additional files"
)
