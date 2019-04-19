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

############################
####    JAVA_LIB INFO   ####
############################

JavaLibInfo = provider(
    fields = {
        "target_coordinates": """
        The Maven coordinates for the artifacts that are exported by this target: i.e. the target
        itself and its transitively exported targets.
        """,
        "target_deps_coordinates": """
        The Maven coordinates of the direct dependencies, and the transitively exported targets, of
        this target.
        """,
    },
)

_JAVA_LIB_INFO_EMPTY = JavaLibInfo(
    target_coordinates = "",
    target_deps_coordinates = depset(),
)

_TAG_KEY_MAVEN_COORDINATES = "maven_coordinates="

def _target_coordinates(targets):
    return [target[JavaLibInfo].target_coordinates for target in targets]

def _java_lib_deps_impl(_target, ctx):
    tags = getattr(ctx.rule.attr, "tags", [])
    deps = getattr(ctx.rule.attr, "deps", [])
    runtime_deps = getattr(ctx.rule.attr, "runtime_deps", [])
    exports = getattr(ctx.rule.attr, "exports", [])
    deps_all = deps + exports + runtime_deps

    maven_coordinates = []
    for tag in tags:
        if tag in ("maven:compile_only", "maven:shaded"):
            return _JAVA_LIB_INFO_EMPTY
        if tag.startswith(_TAG_KEY_MAVEN_COORDINATES):
            coordinate = tag[len(_TAG_KEY_MAVEN_COORDINATES):]
            target_is_in_root_workspace = _target.label.workspace_root == ""
            if coordinate.endswith('{pom_version}') and not target_is_in_root_workspace:
                maven_coordinates.append(coordinate.replace('{pom_version}', _target.label.workspace_root.replace('external/', '')))
            else:
                maven_coordinates.append(coordinate)

        if len(maven_coordinates) > 1:
            fail("You should not set more than one maven_coordinates tag per java_library")

    java_lib_info = JavaLibInfo(target_coordinates = depset(maven_coordinates, transitive=_target_coordinates(exports)),
                                target_deps_coordinates = depset([], transitive = _target_coordinates(deps_all)))
    return [java_lib_info]

_java_lib_deps = aspect(
    attr_aspects = [
        "jars",
        "deps",
        "exports",
        "runtime_deps"
    ],
    doc = """
    Collects the Maven coordinats of a java_library, and its direct dependencies.
    """,
    implementation = _java_lib_deps_impl,
    provides = [JavaLibInfo]
)


#############################
####    MAVEN POM INFO   ####
#############################

MavenPomInfo = provider(
    fields = {
        'maven_pom_deps': 'Maven coordinates for dependencies, transitively collected'
    }
)

def _maven_pom_deps_impl(_target, ctx):
    deps_coordinates = []
    # This seems to be all the direct dependencies of this given _target
    for x in _target[JavaLibInfo].target_deps_coordinates.to_list():
        deps_coordinates.append(x)

    # Now we traverse all the dependencies of our direct-dependencies,
    # if our direct-depenencies is a sub-package of ourselves (_target)
    deps = \
        getattr(ctx.rule.attr, "jars", []) + \
        getattr(ctx.rule.attr, "deps", []) + \
        getattr(ctx.rule.attr, "exports", []) + \
        getattr(ctx.rule.attr, "runtime_deps", [])

    for dep in deps:
        if dep.label.package.startswith(ctx.attr.package):
            deps_coordinates += dep[MavenPomInfo].maven_pom_deps

    return [MavenPomInfo(maven_pom_deps = deps_coordinates)]

# Filled in by deployment_rules_builder
_maven_packages = "{maven_packages}".split(",")
_maven_pom_deps = aspect(
    attr_aspects = [
        "jars",
        "deps",
        "exports",
        "runtime_deps",
        "extension"
    ],
    required_aspect_providers = [JavaLibInfo],
    implementation = _maven_pom_deps_impl,
    attrs = {
        "package": attr.string(values = _maven_packages)
    },
    provides = [MavenPomInfo]
)


####################################
####    MAVEN DEPLOYMENT INFO   ####
####################################

MavenDeploymentInfo = provider(
    fields = {
        'jar': 'JAR file to deploy',
        'pom': 'Accompanying pom.xml file'
    }
)


#############################
####    MAVEN ASSEMBLY   ####
#############################

def _parse_maven_coordinates(coordinate_string):
    group_id, artifact_id, version = coordinate_string.split(':')
    if version != '{pom_version}':
        fail('should assign {pom_version} as Maven version via `tags` attribute')
    return struct(
        group_id = group_id,
        artifact_id = artifact_id,
    )

def _generate_pom_xml(ctx, maven_coordinates):
    # Final 'pom.xml' is generated in 2 steps
    preprocessed_template = ctx.actions.declare_file("_pom.xml")

    pom_file = ctx.actions.declare_file("pom.xml")

    maven_pom_deps = ctx.attr.target[MavenPomInfo].maven_pom_deps
    deps_coordinates = depset(maven_pom_deps).to_list()

    # Indentation of the DEP_BLOCK string is such, so that it renders nicely in the output pom.xml
    DEP_BLOCK = """        <dependency>
            <groupId>{0}</groupId>
            <artifactId>{1}</artifactId>
            <version>{2}</version>
        </dependency>"""
    xml_tags = []
    for coord in deps_coordinates:
        xml_tags.append(DEP_BLOCK.format(*coord.split(":")))

    # Step 1: fill in everything except version using `pom_file` rule implementation
    ctx.actions.expand_template(
        template = ctx.file._pom_xml_template,
        output = preprocessed_template,
        substitutions = {
            "{target_group_id}": maven_coordinates.group_id,
            "{target_artifact_id}": maven_coordinates.artifact_id,
            "{target_deps_coordinates}": "\n".join(xml_tags)
        }
    )

    # Step 2: fill in {pom_version} from version_file
    ctx.actions.run(
        inputs = [preprocessed_template, ctx.file.workspace_refs, ctx.file.version_file],
        executable = ctx.file._pom_replace_version,
        arguments = [preprocessed_template.path, ctx.file.workspace_refs.path, ctx.file.version_file.path, pom_file.path],
        outputs = [pom_file],
    )

    return pom_file

def _assemble_maven_impl(ctx):
    target = ctx.attr.target
    target_string = target[JavaLibInfo].target_coordinates.to_list()[0]

    maven_coordinates = _parse_maven_coordinates(target_string)

    pom_file = _generate_pom_xml(ctx, maven_coordinates)

    # there is also .source_jar which produces '.srcjar'
    if hasattr(target, "java"):
        jar = target.java.outputs.jars[0].class_jar
    elif hasattr(target, "files"):
        jar = target.files.to_list()[0]
    else:
        fail("Could not find JAR file to deploy in {}".format(target))

    output_jar = ctx.actions.declare_file("{}:{}.jar".format(maven_coordinates.group_id, maven_coordinates.artifact_id))

    ctx.actions.run(
        inputs = [jar, pom_file, ctx.file.version_file],
        outputs = [output_jar],
        arguments = [output_jar.path, jar.path, pom_file.path],
        executable = ctx.executable._assemble_script,
    )

    return [
        DefaultInfo(files = depset([output_jar, pom_file])),
        MavenDeploymentInfo(jar = output_jar, pom = pom_file)
    ]

assemble_maven = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            aspects = [
                _java_lib_deps,
                _maven_pom_deps,
            ]
        ),
        "package": attr.string(),
        "version_file": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "workspace_refs": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "_pom_xml_template": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//maven/templates:pom.xml",
        ),
        "_assemble_script": attr.label(
            default = "@graknlabs_bazel_distribution//maven:assemble",
            executable = True,
            cfg = "host"
        ),
        "_pom_replace_version": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//maven:_pom_replace_version.py"
        )
    },
    implementation = _assemble_maven_impl,
)


###############################
####    MAVEN DEPLOYMENT   ####
###############################

def _deploy_maven_impl(ctx):
    deploy_maven_script = ctx.actions.declare_file("deploy.py")

    lib_jar_link = "lib.jar"
    pom_xml_link = "pom.xml"

    ctx.actions.expand_template(
        template = ctx.file._deployment_script,
        output = deploy_maven_script,
        substitutions = {
            "$JAR_PATH": lib_jar_link,
            "$POM_PATH": pom_xml_link,
        }
    )

    return DefaultInfo(
        executable = deploy_maven_script,
        runfiles = ctx.runfiles(files=[
            ctx.attr.target[MavenDeploymentInfo].jar,
            ctx.attr.target[MavenDeploymentInfo].pom,
            ctx.file.deployment_properties
        ], symlinks = {
            lib_jar_link: ctx.attr.target[MavenDeploymentInfo].jar,
            pom_xml_link: ctx.attr.target[MavenDeploymentInfo].pom,
            'deployment.properties': ctx.file.deployment_properties,
        })
    )

_default_deployment_properties = None if 'deployment_properties_placeholder' in "{deployment_properties_placeholder}" else "{deployment_properties_placeholder}"
deploy_maven = rule(
    attrs = {
        "target": attr.label(
            providers = [MavenDeploymentInfo]
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = not bool(_default_deployment_properties),
            default = _default_deployment_properties
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//maven/templates:deploy.py",
        ),
    },
    executable = True,
    implementation = _deploy_maven_impl
)
