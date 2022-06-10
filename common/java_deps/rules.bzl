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
    for file in _target.files.to_list():
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
    full_output_paths = {}
    files_by_output_path = {}
    output_path_overrides = ctx.attr.java_deps_root_overrides

    mapping = ctx.attr.target[TransitiveJarToMavenCoordinatesMapping].mapping

    for file in ctx.attr.target.data_runfiles.files.to_list():
        if file.extension == "jar" and not file.path.startswith(LOCAL_JDK_PREFIX):
            if ctx.attr.maven_name and file.path not in mapping:
                fail("{} does not have associated Maven coordinate".format(file.owner))
            output_path = mapping.get(file.path, default=file.basename).replace('.', '-').replace(':', '-')
            conflicting_file = files_by_output_path.get(output_path)
            if conflicting_file:
                fail(
                    ("'{}' and '{}' were both mapped to the same filename, '{}'. Distinct JARs should be mapped to distinct " +
                    "filenames, either by supplying Maven coordinates, or ensuring the original filenames are distinct."
                    ).format(conflicting_file.path, file.path, output_path)
                )
            for jar_pattern in output_path_overrides:
                if file.basename == jar_pattern or (jar_pattern.endswith("*") and file.basename.startswith(jar_pattern.rstrip("*"))):
                    full_output_paths[file.path] = output_path_overrides[jar_pattern] + output_path + ".jar"
                    break
            if file.path not in full_output_paths:
                full_output_paths[file.path] = ctx.attr.java_deps_root + output_path + ".jar"
            files_by_output_path[output_path] = file

    jars_mapping = ctx.actions.declare_file("{}_jars.mapping".format(ctx.attr.target.label.name))

    ctx.actions.write(
        output = jars_mapping,
        content = str(full_output_paths)
    )

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

    ctx.actions.run(
        outputs = [ctx.outputs.distribution],
        inputs = files_by_output_path.values() + [jars_mapping, version_file],
        arguments = [jars_mapping.path, ctx.outputs.distribution.path, version_file.path],
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
            ],
            doc = "Java target to pack into archive"
        ),
        "java_deps_root": attr.string(
            doc = "Folder inside archive to put JARs into"
        ),
        "java_deps_root_overrides": attr.string_dict(
            doc = """
            JARs with filenames matching the given patterns will be placed into the specified folders inside the archive,
            instead of the default folder. Patterns can be either the full name of a JAR, or a prefix followed by a '*'.
            """
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """
        ),
        "maven_name": attr.bool(
            doc = "Name JAR files inside archive based on Maven coordinates",
            default = False,
        ),
        "_java_deps_builder": attr.label(
            default = "//common/java_deps",
            executable = True,
            cfg = "host"
        )
    },
    implementation = _java_deps_impl,
    outputs = {
        "distribution": "%{name}.tgz"
    },
    doc = "Packs Java library alongside with its dependencies into archive"
)
