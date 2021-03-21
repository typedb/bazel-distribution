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
        "class_jars": "Class JAR files to be merged into this target's class jar",
        "source_jars": "Source JAR files to be merged into this target's source jar",
    },
)

_JAVA_LIB_INFO_EMPTY = JavaLibInfo(
    target_coordinates = "",
    target_deps_coordinates = depset(),
)

_TAG_KEY_MAVEN_COORDINATES = "maven_coordinates="

def _target_coordinates(targets):
    return [target[JavaLibInfo].target_coordinates for target in targets]

def _source_jars(targets):
    return [target[JavaLibInfo].source_jars for target in targets]

def _class_jars(targets):
    return [target[JavaLibInfo].class_jars for target in targets]

def _java_lib_deps_impl(_target, ctx):
    tags = getattr(ctx.rule.attr, "tags", [])
    deps = getattr(ctx.rule.attr, "deps", [])
    runtime_deps = getattr(ctx.rule.attr, "runtime_deps", [])
    exports = getattr(ctx.rule.attr, "exports", [])
    deps_all = deps + exports + runtime_deps

    maven_coordinates = []
    source_jars = []
    class_jars = []
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

    if len(maven_coordinates) == 0:
        # Targets that don't have Maven coordinates are subject to
        # merging into the target being deployed
        source_jars.append(
            _target[OutputGroupInfo]._source_jars.to_list()[-1]
        )
        class_jars.append(
            _target[OutputGroupInfo].compilation_outputs.to_list()[0]
        )
    java_lib_info = JavaLibInfo(
        target_coordinates = depset(maven_coordinates, transitive=_target_coordinates(exports)),
        target_deps_coordinates = depset([], transitive = _target_coordinates(deps_all)),
        source_jars = depset(source_jars, transitive = _source_jars(deps_all)),
        class_jars = depset(class_jars, transitive = _class_jars(deps_all))
    )
    return [java_lib_info]

_java_lib_deps = aspect(
    attr_aspects = [
        "jars",
        "deps",
        "exports",
        "runtime_deps"
    ],
    doc = """
    Collects the Maven coordinates of a java_library, and its direct dependencies.
    """,
    implementation = _java_lib_deps_impl,
    provides = [JavaLibInfo]
)

#############################
####    MAVEN POM INFO   ####
#############################

MavenPomInfo = provider(
    fields = {
        'direct_pom_deps': 'Maven coordinates declared directly by a target',
        'transitive_pom_deps': 'Maven coordinates for dependencies, transitively collected',
    }
)

def _maven_pom_deps_impl(_target, ctx):
    dep_coordinates = []

    # Collect the JavaLibInfo recursed dependencies
    for direct_dep_coordinate in _target[JavaLibInfo].target_deps_coordinates.to_list():
        dep_coordinates.append(direct_dep_coordinate)

    # Now we traverse all the dependencies of our direct-dependencies
    # The aspect execution will have already collected their dependencies recursively
    deps = \
        getattr(ctx.rule.attr, "jars", []) + \
        getattr(ctx.rule.attr, "deps", []) + \
        getattr(ctx.rule.attr, "exports", []) + \
        getattr(ctx.rule.attr, "runtime_deps", [])

    dep_coordinates_with_transitive = dep_coordinates + []
    for dep in deps:
        if dep.label.name.endswith('.jar'):
            continue
        for recursive_dep_coordinate in dep[MavenPomInfo].transitive_pom_deps:
            if recursive_dep_coordinate not in dep_coordinates_with_transitive:
                dep_coordinates_with_transitive.append(recursive_dep_coordinate)

    # collect all transitive pom dependencies of all versions into one list
    return [MavenPomInfo(direct_pom_deps = dep_coordinates, transitive_pom_deps = dep_coordinates_with_transitive)]


# Filled in by deployment_rules_builder
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
    provides = [MavenPomInfo]
)


####################################
####    MAVEN DEPLOYMENT INFO   ####
####################################

MavenDeploymentInfo = provider(
    fields = {
        'jar': 'JAR file to deploy',
        'srcjar': 'JAR file with sources',
        'pom': 'Accompanying pom.xml file'
    }
)


#############################
####    MAVEN ASSEMBLY   ####
#############################

apache_license_text = """
<!--
  ~
  ~ Licensed to the Apache Software Foundation (ASF) under one
  ~ or more contributor license agreements.  See the NOTICE file
  ~ distributed with this work for additional information
  ~ regarding copyright ownership.  The ASF licenses this file
  ~ to you under the Apache License, Version 2.0 (the
  ~ "License"); you may not use this file except in compliance
  ~ with the License.  You may obtain a copy of the License at
  ~
  ~   http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  ~
-->
"""

mit_license_text = """
<!--
 ~
 ~ Released under MIT License
 ~
 ~ Permission is hereby granted, free of charge, to any person obtaining a copy of 
 ~ this software and associated documentation files (the "Software"), to deal in 
 ~ the Software without restriction, including without limitation the rights to 
 ~ use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
 ~ of the Software, and to permit persons to whom the Software is furnished to 
 ~ do so, subject to the following conditions:
 ~
 ~ The above copyright notice and this permission notice shall be included in all 
 ~ copies or substantial portions of the Software.
 ~
 ~ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 ~ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 ~ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
 ~ THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 ~ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 ~ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
 ~ THE SOFTWARE.
 ~
-->
"""

def _parse_maven_artifact(coordinate_string):
    """ Return the artifact (group + artifact) and version """
    group_id, artifact_id, version = coordinate_string.split(':')
    return group_id + ":" + artifact_id, version

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
    preprocessed_template = ctx.actions.declare_file("_{}_pom.xml".format(ctx.attr.name))

    pom_file = ctx.actions.declare_file("{}_pom.xml".format(ctx.attr.name))

    transitive_pom_deps = ctx.attr.target[MavenPomInfo].transitive_pom_deps
    direct_pom_deps = ctx.attr.target[MavenPomInfo].direct_pom_deps

    # keep all direct_pom_deps but override if necessary
    deps = {}
    for direct_dep in direct_pom_deps:
        artifact, found_version = _parse_maven_artifact(direct_dep)
        version = ctx.attr.version_overrides.get(artifact, found_version) # default to collected version if not overriden
        deps[artifact] = version


    # only keep overriden transitive deps
    for transitive_dep in transitive_pom_deps:
        artifact, version = _parse_maven_artifact(transitive_dep)
        overriden_version = ctx.attr.version_overrides.get(artifact)
        if artifact not in deps and overriden_version != None:
            deps[artifact] = overriden_version

    # reconstruct full coordinates
    maven_pom_deps = [artifact + ":" + version for artifact, version in deps.items()]

    maven_pom_deps = direct_pom_deps + transitive_pom_deps

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

    license_name = "LICENSE_NAME"
    license_url = "LICENSE_URL"
    license_comments = "LICENSE_COMMENTS"

    if ctx.attr.license == 'apache':
        license_name = "Apache License, Version 2.0"
        license_url = "https://www.apache.org/licenses/LICENSE-2.0.txt"
        license_text = apache_license_text
    if ctx.attr.license == 'mit':
        license_name = "MIT License"
        license_url = "https://opensource.org/licenses/MIT"
        license_text= mit_license_text

    scm_connection = ctx.attr.scm_url
    scm_developer_connection = ctx.attr.scm_url
    scm_tag = "{pom_version}"

    developers = ""
    for dev, dev_info in ctx.attr.developers.items():
        tag = "<developer>"
        for x in dev_info:
            k, v = x.split('=')
            tag += "<{k}>{v}</{k}>".format(k=k, v=v)
        tag += "</developer>"
        developers += tag
        developers += "\n"

    # Step 1: fill in everything except version using `pom_file` rule implementation
    ctx.actions.expand_template(
        template = ctx.file._pom_xml_template,
        output = preprocessed_template,
        substitutions = {
            "{project_name}": ctx.attr.project_name,
            "{project_description}": ctx.attr.project_description,
            "{project_url}": ctx.attr.project_url,
            "{license_name}": license_name,
            "{license_url}": license_url,
            "{license_text}": license_text,
            "{scm_connection}": scm_connection,
            "{scm_developer_connection}": scm_developer_connection,
            "{scm_tag}": scm_tag,
            "{scm_url}": ctx.attr.scm_url,
            "{developers}": developers,
            "{target_group_id}": maven_coordinates.group_id,
            "{target_artifact_id}": maven_coordinates.artifact_id,
            "{target_deps_coordinates}": "\n".join(xml_tags)
        }
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

    inputs = [preprocessed_template, version_file]

    args = ctx.actions.args()
    args.add('--template_file', preprocessed_template.path)
    args.add('--version_file', version_file.path)
    args.add('--pom_file', pom_file.path)

    if ctx.attr.workspace_refs:
        inputs.append(ctx.file.workspace_refs)
        args.add('--workspace_refs', ctx.file.workspace_refs.path)

    # Step 2: fill in {pom_version} from version_file
    ctx.actions.run(
        inputs = inputs,
        executable = ctx.executable._pom_replace_version,
        arguments = [args],
        outputs = [pom_file],
    )

    return pom_file

def _assemble_maven_impl(ctx):
    target = ctx.attr.target
    target_string = target[JavaLibInfo].target_coordinates.to_list()[-1]

    maven_coordinates = _parse_maven_coordinates(target_string)

    pom_file = _generate_pom_xml(ctx, maven_coordinates)

    # there is also .source_jar which produces '.srcjar'
    jar = None
    srcjar = None

    if hasattr(target, "files") and target.files.to_list() and target.files.to_list()[0].extension == 'jar':
        all_jars = target[JavaInfo].outputs.jars
        jar = all_jars[0].class_jar

        for output in all_jars:
            if output.source_jar and (output.source_jar.basename.endswith('-src.jar') or output.source_jar.basename.endswith('-sources.jar')):
                srcjar = output.source_jar
                break
    else:
        fail("Could not find JAR file to deploy in {}".format(target))

    output_jar_without_pom = ctx.actions.declare_file("{}:{}__without_pom.jar".format(maven_coordinates.group_id, maven_coordinates.artifact_id))
    output_jar = ctx.actions.declare_file("{}:{}.jar".format(maven_coordinates.group_id, maven_coordinates.artifact_id))
    source_jar = None

    ctx.actions.run(
        executable = ctx.executable._repackager,
        inputs = [jar] + target[JavaLibInfo].class_jars.to_list(),
        outputs = [output_jar_without_pom],
        arguments = ["", output_jar_without_pom.path, jar.path] + [x.path for x in target[JavaLibInfo].class_jars.to_list()]
    )

    if srcjar:
        source_jar = ctx.actions.declare_file("{}:{}-sources.jar".format(maven_coordinates.group_id, maven_coordinates.artifact_id))
        ctx.actions.run(
            executable = ctx.executable._repackager,
            inputs = [srcjar] + target[JavaLibInfo].source_jars.to_list(),
            outputs = [source_jar],
            arguments = [ctx.attr.source_jar_prefix, source_jar.path, srcjar.path] + [x.path for x in target[JavaLibInfo].source_jars.to_list()]
        )

    ctx.actions.run(
        inputs = [output_jar_without_pom, pom_file],
        outputs = [output_jar],
        arguments = [output_jar.path, output_jar_without_pom.path, pom_file.path],
        executable = ctx.executable._assemble_script,
    )

    files = [output_jar, pom_file]
    if source_jar:
        files.append(source_jar)

    return [
        DefaultInfo(files = depset(files)),
        MavenDeploymentInfo(jar = output_jar, pom = pom_file, srcjar = source_jar)
    ]

assemble_maven = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            aspects = [
                _java_lib_deps,
                _maven_pom_deps,
            ],
            doc = "Java target for subsequent deployment"
        ),
        "package": attr.string(
            doc = "Bazel package of this target. Must match one defined in `_maven_packages`"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """
        ),
        "workspace_refs": attr.label(
            allow_single_file = True,
            doc = 'JSON file describing dependencies to other Bazel workspaces'
        ),
        "version_overrides": attr.string_dict(
            default = {},
            doc = 'Dictionary of maven artifact : version to pin artifact versions to'
        ),
        "project_name": attr.string(
            default = "PROJECT_NAME",
            doc = 'Project name to fill into pom.xml'
        ),
        "project_description": attr.string(
            default = "PROJECT_DESCRIPTION",
            doc = 'Project description to fill into pom.xml'
        ),
        "project_url": attr.string(
            default = "PROJECT_URL",
            doc = 'Project URL to fill into pom.xml'
        ),
        "license": attr.string(
            values=["apache", "mit"],
            default = "apache",
            doc = 'Project license to fill into pom.xml'
        ),
        "scm_url": attr.string(
            default = "PROJECT_URL",
            doc = 'Project source control URL to fill into pom.xml'
        ),
        "developers": attr.string_list_dict(
            default = {},
            doc = 'Project developers to fill into pom.xml'
        ),
        "source_jar_prefix": attr.string(
            default = "",
            doc = 'Prefix source JAR files with this directory'
        ),
        "_repackager": attr.label(
            default = "@graknlabs_bazel_distribution//maven:repackager",
            executable = True,
            cfg = "host"
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
            default = "@graknlabs_bazel_distribution//maven:pom_replace_version",
            executable = True,
            cfg = "host",
        )
    },
    implementation = _assemble_maven_impl,
    doc = "Assemble Java package for subsequent deployment to Maven repo"
)


###############################
####    MAVEN DEPLOYMENT   ####
###############################

def _deploy_maven_impl(ctx):
    deploy_maven_script = ctx.actions.declare_file("deploy.py")

    lib_jar_link = "lib.jar"
    src_jar_link = "lib.srcjar"
    pom_xml_link = ctx.attr.target[MavenDeploymentInfo].pom.basename

    ctx.actions.expand_template(
        template = ctx.file._deployment_script,
        output = deploy_maven_script,
        substitutions = {
            "$JAR_PATH": lib_jar_link,
            "$SRCJAR_PATH": src_jar_link,
            "$POM_PATH": pom_xml_link,
            "{snapshot}": ctx.attr.snapshot,
            "{release}": ctx.attr.release
        }
    )

    files = [
        ctx.attr.target[MavenDeploymentInfo].jar,
        ctx.attr.target[MavenDeploymentInfo].pom,
    ]
    symlinks = {
        lib_jar_link: ctx.attr.target[MavenDeploymentInfo].jar,
        pom_xml_link: ctx.attr.target[MavenDeploymentInfo].pom,
    }
    if ctx.attr.target[MavenDeploymentInfo].srcjar:
        files.append(ctx.attr.target[MavenDeploymentInfo].srcjar)
        symlinks[src_jar_link] = ctx.attr.target[MavenDeploymentInfo].srcjar

    return DefaultInfo(
        executable = deploy_maven_script,
        runfiles = ctx.runfiles(files=files, symlinks = symlinks)
    )

deploy_maven = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [MavenDeploymentInfo],
            doc = "assemble_maven target to deploy"
        ),
        "snapshot" : attr.string(
            mandatory = True,
            doc = 'Snapshot repository to release maven artifact to',
        ),
        "release" : attr.string(
            mandatory = True,
            doc = 'Release repository to release maven artifact to'
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//maven/templates:deploy.py",
        ),
    },
    executable = True,
    implementation = _deploy_maven_impl,
    doc = "Deploy `assemble_maven` target into Maven repo"
)
