load("@graknlabs_bazel_distribution//maven:rules.bzl", "MavenDeploymentInfo")

def _parse_maven_coordinates(coordinates_string):
    group_id, artifact_id, version = coordinates_string.split(":")
    if version != "{pom_version}":
        fail("should assign {pom_version} as Maven version via `tags` attribute")
    return struct(
        group_id = group_id,
        artifact_id = artifact_id,
    )

def _parse_maven_artifact(coordinates_string):
    """ Return the artifact (group + artifact) and version """
    group_id, artifact_id, version = coordinates_string.split(":")
    return group_id + ":" + artifact_id, version

def _construct_version_file(ctx):
    version_file = ctx.file.version_file
    if not ctx.attr.version_file:
        version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
        version = ctx.var.get("version", "0.0.0")

        ctx.actions.run_shell(
            inputs = [],
            outputs = [version_file],
            command = "echo {} > {}".format(version, version_file.path),
        )
    return version_file

def _generate_pom_file(ctx, version_file):
    target = ctx.attr.target
    maven_coordinates = _parse_maven_coordinates(target[AggregatedDependencyInfo].maven_coordinates)
    pom_file = ctx.actions.declare_file("{}_pom.xml".format(ctx.attr.name))

    pom_deps = []
    for pom_dependency in target[AggregatedDependencyInfo].pom_deps.to_list():
        if pom_dependency == target[AggregatedDependencyInfo].maven_coordinates:
            continue
        pom_dependency_artifact, pom_dependency_version = _parse_maven_artifact(pom_dependency)
        version = ctx.attr.version_overrides.get(pom_dependency_artifact, pom_dependency_version)
        pom_deps.append(pom_dependency_artifact + ":" + version)

    ctx.actions.run(
        executable = ctx.executable._pom_generator,
        inputs = [version_file, ctx.file.workspace_refs],
        outputs = [pom_file],
        arguments = [
            "--project_name=" + ctx.attr.project_name,
            "--project_description=" + ctx.attr.project_description,
            "--project_url=" + ctx.attr.project_url,
            "--license=" + ctx.attr.license,
            "--scm_url=" + ctx.attr.scm_url,
            "--target_group_id=" + maven_coordinates.group_id,
            "--target_artifact_id= " + maven_coordinates.artifact_id,
            "--target_deps_coordinates=" + ";".join(pom_deps),
            "--version_file=" + version_file.path,
            "--output_file=" + pom_file.path,
            "--workspace_refs_file=" + ctx.file.workspace_refs.path,
        ],
    )

    return pom_file

def _generate_class_jar(ctx, pom_file):
    target = ctx.attr.target
    maven_coordinates = _parse_maven_coordinates(target[AggregatedDependencyInfo].maven_coordinates)

    jar = None
    if hasattr(target, "files") and target.files.to_list() and target.files.to_list()[0].extension == "jar":
        jar = target[JavaInfo].outputs.jars[0].class_jar
    else:
        fail("Could not find JAR file to deploy in {}".format(target))

    output_jar = ctx.actions.declare_file("{}:{}.jar".format(maven_coordinates.group_id, maven_coordinates.artifact_id))

    class_jar_paths = [jar.path] + [target.path for target in target[AggregatedDependencyInfo].class_jar_deps.to_list()]

    ctx.actions.run(
        executable = ctx.executable._jar_assembler,
        inputs = [jar, pom_file] + target[AggregatedDependencyInfo].class_jar_deps.to_list(),
        outputs = [output_jar],
        arguments = [
            "--prefix=",  # prefix is deliberately left empty
            "--group-id=" + maven_coordinates.group_id,
            "--artifact-id=" + maven_coordinates.artifact_id,
            "--pom-file=" + pom_file.path,
            "--jars=" + ";".join(class_jar_paths),
            "--output=" + output_jar.path,
        ],
    )

    return output_jar

def _generate_source_jar(ctx):
    target = ctx.attr.target
    maven_coordinates = _parse_maven_coordinates(target[AggregatedDependencyInfo].maven_coordinates)

    srcjar = None

    if hasattr(target, "files") and target.files.to_list() and target.files.to_list()[0].extension == "jar":
        for output in target[JavaInfo].outputs.jars:
            if output.source_jar and (output.source_jar.basename.endswith("-src.jar") or output.source_jar.basename.endswith("-sources.jar")):
                srcjar = output.source_jar
                break
    else:
        fail("Could not find JAR file to deploy in {}".format(target))

    if not srcjar:
        return None

    output_jar = ctx.actions.declare_file("{}:{}-sources.jar".format(maven_coordinates.group_id, maven_coordinates.artifact_id))

    source_jar_paths = [srcjar.path] + [target.path for target in target[AggregatedDependencyInfo].source_jar_deps.to_list()]

    ctx.actions.run(
        executable = ctx.executable._jar_assembler,
        inputs = [srcjar] + target[AggregatedDependencyInfo].source_jar_deps.to_list(),
        outputs = [output_jar],
        arguments = [
            "--prefix=" + ctx.attr.source_jar_prefix,
            "--jars=" + ";".join(source_jar_paths),
            "--output=" + output_jar.path,
        ],
    )

    return output_jar

def _assemble_maven_impl(ctx):
    version_file = _construct_version_file(ctx)
    pom_file = _generate_pom_file(ctx, version_file)
    class_jar = _generate_class_jar(ctx, pom_file)
    source_jar = _generate_source_jar(ctx)

    output_files = [pom_file, class_jar]
    if source_jar:
        output_files.append(source_jar)

    return [
        DefaultInfo(files = depset(output_files)),
        MavenDeploymentInfo(jar = class_jar, pom = pom_file, srcjar = source_jar)
    ]

def find_maven_coordinates(target, tags):
    _TAG_KEY_MAVEN_COORDINATES = "maven_coordinates="
    for tag in tags:
        if tag.startswith(_TAG_KEY_MAVEN_COORDINATES):
            coordinates = tag[len(_TAG_KEY_MAVEN_COORDINATES):]
            target_is_in_root_workspace = target.label.workspace_root == ""
            if coordinates.endswith("{pom_version}") and not target_is_in_root_workspace:
                coordinates = coordinates.replace("{pom_version}", target.label.workspace_root.replace("external/", ""))
            return coordinates

AggregatedDependencyInfo = provider(
    fields = {
        "maven_coordinates": "Coordinates of a given JAR",
        "pom_deps": "The depset of all of the Maven coordinates this JAR depends on",
        "source_jar_deps": "The depset of all of the source JARs this JAR is comprised of",
        "class_jar_deps": "The depset of all of the class JARs this JAR is comprised of",
    },
)

def _aggregate_dependency_info_impl(target, ctx):
    tags = getattr(ctx.rule.attr, "tags", [])
    deps = getattr(ctx.rule.attr, "deps", [])
    runtime_deps = getattr(ctx.rule.attr, "runtime_deps", [])
    exports = getattr(ctx.rule.attr, "exports", [])
    deps_all = deps + exports + runtime_deps

    maven_coordinates = find_maven_coordinates(target, tags)

    if maven_coordinates:
        # depend via POM
        return AggregatedDependencyInfo(
            maven_coordinates = maven_coordinates,
            pom_deps = depset([maven_coordinates], transitive = [target[AggregatedDependencyInfo].pom_deps for target in deps_all]),
            source_jar_deps = depset([], transitive = [target[AggregatedDependencyInfo].source_jar_deps for target in deps_all]),
            class_jar_deps = depset([], transitive = [target[AggregatedDependencyInfo].class_jar_deps for target in deps_all]),
        )
    else:
        # include in the JAR
        return AggregatedDependencyInfo(
            maven_coordinates = "",
            pom_deps = depset([], transitive = [target[AggregatedDependencyInfo].pom_deps for target in ctx.rule.attr.deps]),
            source_jar_deps = depset(
                [target[OutputGroupInfo]._source_jars.to_list()[-1]],
                transitive = [target[AggregatedDependencyInfo].source_jar_deps for target in deps_all],
            ),
            class_jar_deps = depset(
                [target[OutputGroupInfo].compilation_outputs.to_list()[0]],
                transitive = [target[AggregatedDependencyInfo].class_jar_deps for target in deps_all],
            ),
        )

aggregate_dependency_info = aspect(
    attr_aspects = [
        "jars",
        "deps",
        "exports",
        "runtime_deps",
    ],
    doc = "Collects the Maven coordinates of the given java_library, its direct dependencies and transitive dependencies",
    implementation = _aggregate_dependency_info_impl,
    provides = [AggregatedDependencyInfo],
)

assemble_maven = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            aspects = [
                aggregate_dependency_info,
            ],
            doc = "Java target for subsequent deployment",
        ),
        "source_jar_prefix": attr.string(
            default = "",
            doc = "Prefix source JAR files with this directory",
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """,
        ),
        "workspace_refs": attr.label(
            allow_single_file = True,
            doc = "JSON file describing dependencies to other Bazel workspaces",
        ),
        "version_overrides": attr.string_dict(
            default = {},
            doc = "Dictionary of maven artifact : version to pin artifact versions to",
        ),
        "project_name": attr.string(
            default = "PROJECT_NAME",
            doc = "Project name to fill into pom.xml",
        ),
        "project_description": attr.string(
            default = "PROJECT_DESCRIPTION",
            doc = "Project description to fill into pom.xml",
        ),
        "project_url": attr.string(
            default = "PROJECT_URL",
            doc = "Project URL to fill into pom.xml",
        ),
        "license": attr.string(
            values = ["apache", "mit"],
            default = "apache",
            doc = "Project license to fill into pom.xml",
        ),
        "scm_url": attr.string(
            default = "PROJECT_URL",
            doc = "Project source control URL to fill into pom.xml",
        ),
        "_pom_generator": attr.label(
            default = "@graknlabs_bazel_distribution//maven:pom-generator",
            executable = True,
            cfg = "host",
        ),
        "_jar_assembler": attr.label(
            default = "@graknlabs_bazel_distribution//maven:jar-assembler",
            executable = True,
            cfg = "host",
        ),
    },
    implementation = _assemble_maven_impl,
    doc = "Assemble Java package for subsequent deployment to Maven repo",
)
