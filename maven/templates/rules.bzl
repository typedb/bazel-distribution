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
        if dep.label.name.endswith('.jar'):
            continue
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
        'srcjar': 'JAR file with sources',
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
    preprocessed_template = ctx.actions.declare_file("_{}_pom.xml".format(ctx.attr.name))

    pom_file = ctx.actions.declare_file("{}_pom.xml".format(ctx.attr.name))

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

    license_name = "LICENSE_NAME"
    license_url = "LICENSE_URL"
    license_comments = "LICENSE_COMMENTS"

    if ctx.attr.license == 'apache':
        license_name = "Apache License, Version 2.0"
        license_url = "https://www.apache.org/licenses/LICENSE-2.0.txt"
    if ctx.attr.license == 'MIT':
        license_name = "MIT License"
        license_url = "https://opensource.org/licenses/MIT"

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
        executable = ctx.file._pom_replace_version,
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
    srcjar = None

    if hasattr(target, "files") and target.files.to_list() and target.files.to_list()[0].extension == 'jar':
        all_jars = target[JavaInfo].outputs.jars
        jar = all_jars[0].class_jar

        for output in all_jars:
            if output.source_jar.basename.endswith('-src.jar'):
                srcjar = output.source_jar
                break
    else:
        fail("Could not find JAR file to deploy in {}".format(target))

    output_jar = ctx.actions.declare_file("{}:{}.jar".format(maven_coordinates.group_id, maven_coordinates.artifact_id))

    ctx.actions.run(
        inputs = [jar, pom_file],
        outputs = [output_jar],
        arguments = [output_jar.path, jar.path, pom_file.path],
        executable = ctx.executable._assemble_script,
    )

    if srcjar == None:
        return [
            DefaultInfo(files = depset([output_jar, pom_file])),
            MavenDeploymentInfo(jar = output_jar, pom = pom_file)
        ]
    else:
        return [
            DefaultInfo(files = depset([output_jar, pom_file, srcjar])),
            MavenDeploymentInfo(jar = output_jar, pom = pom_file, srcjar = srcjar)
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
            values=["apache", "MIT"],
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
        }
    )

    return DefaultInfo(
        executable = deploy_maven_script,
        runfiles = ctx.runfiles(files=[
            ctx.attr.target[MavenDeploymentInfo].jar,
            ctx.attr.target[MavenDeploymentInfo].pom,
            ctx.attr.target[MavenDeploymentInfo].srcjar,
            ctx.file.deployment_properties,
            ctx.file._common_py
        ], symlinks = {
            lib_jar_link: ctx.attr.target[MavenDeploymentInfo].jar,
            pom_xml_link: ctx.attr.target[MavenDeploymentInfo].pom,
            src_jar_link: ctx.attr.target[MavenDeploymentInfo].srcjar,
            'deployment.properties': ctx.file.deployment_properties,
            "common.py": ctx.file._common_py
        })
    )

_default_deployment_properties = None if 'deployment_properties_placeholder' in "{deployment_properties_placeholder}" else "{deployment_properties_placeholder}"
deploy_maven = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [MavenDeploymentInfo],
            doc = "assemble_maven target to deploy"
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = not bool(_default_deployment_properties),
            default = _default_deployment_properties,
            doc = 'Properties file containing repo.maven.(snapshot|release) key'
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//maven/templates:deploy.py",
        ),
        "_common_py": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//common:common.py",
        )
    },
    executable = True,
    implementation = _deploy_maven_impl,
    doc = "Deploy `assemble_maven` target into Maven repo"
)
