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
    names = {}
    files = []
    filenames = []

    mapping = ctx.attr.target[TransitiveJarToMavenCoordinatesMapping].mapping

    for file in ctx.attr.target.data_runfiles.files.to_list():
        if file.extension == 'jar' and not file.path.startswith(LOCAL_JDK_PREFIX):
            if ctx.attr.maven_name and file.path not in mapping:
                fail("{} does not have associated Maven coordinate".format(file.owner))
            filename = mapping.get(file.path, file.basename).replace('.', '-').replace(':', '-')
            if filename in filenames:
                print("Excluded duplicate: {}".format(filename))
                continue # do not pack JARs with same name
            names[file.path] = ctx.attr.java_deps_root + filename + ".jar"
            files.append(file)
            filenames.append(filename)

    jars_mapping = ctx.actions.declare_file("{}_jars.mapping".format(ctx.attr.target.label.name))

    ctx.actions.write(
        output = jars_mapping,
        content = str(names)
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
        inputs = files + [jars_mapping, version_file],
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
            default = "//common:java_deps",
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
