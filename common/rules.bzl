load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar", "pkg_deb")

LOCAL_JDK_PREFIX = "external/local_jdk/"
MAVEN_COORDINATES_PREFIX = "maven_coordinates="

# mapping of single JAR to its Maven coordinates
JarToMavenCoordinatesMapping = provider(
    fields = {
        "filename": "jar filename",
        "maven_coordinates" : "Maven coordinates of the jar"
    },
)

# mapping of all JARs to their Maven coordinates
TransitiveJarToMavenCoordinatesMapping = provider(
    fields = {
        'mapping': 'maps jar filename to coordinates'
    }
)

def _transitive_collect_maven_coordinate_impl(_target, ctx):
    mapping = {}

    if JarToMavenCoordinatesMapping in _target:
        mapping[_target[JarToMavenCoordinatesMapping].filename] = _target[
            JarToMavenCoordinatesMapping].maven_coordinates

    for dep in getattr(ctx.rule.attr, "jars", []):
        if TransitiveJarToMavenCoordinatesMapping in dep:
            mapping.update(dep[TransitiveJarToMavenCoordinatesMapping].mapping)
    for dep in getattr(ctx.rule.attr, "deps", []):
        if TransitiveJarToMavenCoordinatesMapping in dep:
            mapping.update(dep[TransitiveJarToMavenCoordinatesMapping].mapping)
    for dep in getattr(ctx.rule.attr, "exports", []):
        if TransitiveJarToMavenCoordinatesMapping in dep:
            mapping.update(dep[TransitiveJarToMavenCoordinatesMapping].mapping)
    for dep in getattr(ctx.rule.attr, "runtime_deps", []):
        if TransitiveJarToMavenCoordinatesMapping in dep:
            mapping.update(dep[TransitiveJarToMavenCoordinatesMapping].mapping)

    # don't store jars with no attached Maven coordinates
    cleaned_mapping = {k: v for k,v in mapping.items() if v}
    return [TransitiveJarToMavenCoordinatesMapping(mapping = cleaned_mapping)]


def _collect_maven_coordinate_impl(_target, ctx):
    for file in _target.files:
        if file.extension == 'jar':
            jar_file = file.path

    tags = getattr(ctx.rule.attr, "tags", [])
    jar_coordinates = ""

    for tag in tags:
        if tag.startswith(MAVEN_COORDINATES_PREFIX):
            jar_coordinates = tag[len(MAVEN_COORDINATES_PREFIX):]

    return [JarToMavenCoordinatesMapping(
        filename = jar_file,
        maven_coordinates = jar_coordinates
    )]


_collect_maven_coordinate = aspect(
    attr_aspects = [
        "jars",
        "deps",
        "exports",
        "runtime_deps"
    ],
    doc = """
    Collects the Maven information for targets, their dependencies, and their transitive exports.
    """,
    implementation = _collect_maven_coordinate_impl,
    provides = [JarToMavenCoordinatesMapping]
)


_transitive_collect_maven_coordinate = aspect(
    attr_aspects = [
        "jars",
        "deps",
        "exports",
        "runtime_deps"
    ],
    required_aspect_providers = [JarToMavenCoordinatesMapping],
    provides = [TransitiveJarToMavenCoordinatesMapping],
    implementation = _transitive_collect_maven_coordinate_impl
)


def _java_deps_impl(ctx):
    names = {}
    files = []
    filenames = []

    mapping = ctx.attr.target[TransitiveJarToMavenCoordinatesMapping].mapping

    for file in ctx.attr.target.data_runfiles.files.to_list():
        if file.basename in filenames:
            continue # do not pack JARs with same name
        if file.extension == 'jar' and not file.path.startswith(LOCAL_JDK_PREFIX):
            filename = mapping.get(file.path, file.basename).replace('.', '-').replace(':', '-')
            names[file.path] = ctx.attr.java_deps_root + filename + ".jar"
            files.append(file)
            filenames.append(file.basename)

    jars_mapping = ctx.actions.declare_file("jars.mapping")

    ctx.actions.write(
        output = jars_mapping,
        content = str(names)
    )

    ctx.actions.run(
        outputs = [ctx.outputs.distribution],
        inputs = files + [jars_mapping, ctx.file.version_file],
        arguments = [jars_mapping.path, ctx.outputs.distribution.path, ctx.file.version_file.path],
        executable = ctx.executable._java_deps_builder,
        progress_message = "Generating tarball with Java deps: {}".format(
            ctx.outputs.distribution.short_path)
    )


java_deps = rule(
    attrs = {
        "target": attr.label(
            mandatory=True,
            aspects = [
                _collect_maven_coordinate,
                _transitive_collect_maven_coordinate
            ]
        ),
        "java_deps_root": attr.string(
            doc = "Folder inside archive to put JARs into"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "_java_deps_builder": attr.label(
            default = "//common:java_deps",
            executable = True,
            cfg = "host"
        )
    },
    implementation = _java_deps_impl,
    outputs = {
        "distribution": "%{name}.tgz"
    },
)


def _tgz2zip_impl(ctx):
    ctx.actions.run(
        inputs = [ctx.file.tgz],
        outputs = [ctx.outputs.zip],
        executable = ctx.executable._tgz2zip_py,
        arguments = [ctx.file.tgz.path, ctx.outputs.zip.path, ctx.attr.prefix],
        progress_message = "Converting {} to {}".format(ctx.file.tgz.short_path, ctx.outputs.zip.short_path)
    )

    return DefaultInfo(data_runfiles = ctx.runfiles(files=[ctx.outputs.zip]))


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
            default = "//common:tgz2zip",
            executable = True,
            cfg = "host"
        )
    },
    implementation = _tgz2zip_impl,
    outputs = {
        "zip": "%{output_filename}.zip"
    },
    output_to_genfiles = True
)


def assemble_targz(name,
                   output_filename = None,
                   targets = [],
                   additional_files = {},
                   empty_directories = [],
                   permissions = {},
                   visibility = ["//visibility:private"]):
    pkg_tar(
        name = "{}__do_not_reference__targz_0".format(name),
        deps = targets,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
    )

    pkg_tar(
        name = "{}__do_not_reference__targz_1".format(name),
        deps = [":{}__do_not_reference__targz_0".format(name)],
        package_dir = output_filename,
        extension = "tar.gz"
    )

    output_filename = output_filename or name

    native.genrule(
        name = name,
        srcs = [":{}__do_not_reference__targz_1".format(name)],
        cmd = "cp $$(echo $(SRCS) | awk '{print $$1}') $@",
        outs = [output_filename + ".tar.gz"],
        visibility = visibility
    )


def assemble_zip(name,
                 output_filename,
                 targets,
                 additional_files = {},
                 empty_directories = [],
                 permissions = {},
                 visibility = ["//visibility:private"]):
    pkg_tar(
        name="{}__do_not_reference__targz".format(name),
        deps = targets,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
    )

    tgz2zip(
        name = name,
        tgz = ":{}__do_not_reference__targz".format(name),
        output_filename = output_filename,
        prefix = "./" + output_filename,
        visibility = visibility
    )


def _checksum(ctx):
    ctx.actions.run_shell(
        inputs = [ctx.file.target],
        outputs = [ctx.outputs.checksum_file],
        command = 'shasum -a 256 {} > {}'.format(ctx.file.target.path, ctx.outputs.checksum_file.path)
    )

checksum = rule(
    attrs = {
        'target': attr.label(allow_single_file = True, mandatory = True)
    },
    outputs = {
        'checksum_file': '%{name}.sha256'
    },
    implementation = _checksum

)