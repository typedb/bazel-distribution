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

load("@rules_rust//rust:rust_common.bzl", "CrateInfo")

CrateDeploymentInfo = provider(
    fields = {
        "crate": "Crate file to deploy",
        "metadata": "File containing package metadata",
    },
)

def _generate_version_file(ctx):
    version_file = ctx.file.version_file
    if not ctx.attr.version_file:
        version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
        version = ctx.var.get("version", "0.0.0")

        ctx.actions.run_shell(
            inputs = [],
            outputs = [version_file],
            command = "echo -n {} > {}".format(version, version_file.path),
        )
    return version_file

def validate_as_url(field_name, field_value):
    if not field_value.startswith("http://") and not field_value.startswith("https://"):
        fail("URL for field `{}` must begin with http:// or https://".format(field_name))


def validate_keywords(keywords):
    if len(keywords) > 5:
        fail("Maximum of 5 keywords is supported; {} found".format(len(keywords)))
    for keyword in keywords:
        if len(keyword) > 20:
            fail("Keywords need to be 20 characters maximum; {} is invalid (length = {})".format(
                keyword, len(keyword)
                ))


def _assemble_crate_impl(ctx):
    deps = {}
    for dependency in ctx.attr.target[RustLibInfo].deps:
        name = ctx.attr.mapping.get(dependency[RustLibInfo].name, dependency[RustLibInfo].name)
        deps[name] = dependency[RustLibInfo].version
    validate_as_url('homepage', ctx.attr.homepage)
    validate_as_url('repository', ctx.attr.repository)
    validate_keywords(ctx.attr.keywords)
    version_file = _generate_version_file(ctx)
    args = [
        "--srcs", ";".join([x.path for x in ctx.attr.target[CrateInfo].srcs.to_list()]),
        "--output-crate", ctx.outputs.crate_package.path,
        "--output-metadata-json", ctx.outputs.metadata_json.path,
        "--root", ctx.attr.target[CrateInfo].root.path,
        "--edition", ctx.attr.target[CrateInfo].edition,
        "--name", ctx.attr.target[CrateInfo].name,
        "--version-file", version_file.path,
        "--authors", ";".join(ctx.attr.authors),
        "--keywords", ";".join(ctx.attr.keywords),
        "--categories", ";".join(ctx.attr.categories),
        "--description", ctx.attr.description,
        "--homepage", ctx.attr.homepage,
        "--license", ctx.attr.license,
        "--repository", ctx.attr.repository,
        "--deps", ";".join(["{}={}".format(k, v) for k, v in deps.items()]),
    ]
    if ctx.attr.documentation != "":
        validate_as_url('documentation', ctx.attr.documentation)
        args.append("--documentation")
        args.append(ctx.attr.documentation)
    inputs = [version_file]
    if ctx.file.readme_file:
        args.append("--readme-file")
        args.append(ctx.file.readme_file.path)
        inputs.append(ctx.file.readme_file)
    ctx.actions.run(
        inputs = inputs + ctx.attr.target[CrateInfo].srcs.to_list(),
        outputs = [ctx.outputs.crate_package, ctx.outputs.metadata_json],
        executable = ctx.executable._crate_assembler_tool,
        arguments = args,
    )
    return [
        CrateDeploymentInfo(
            crate = ctx.outputs.crate_package,
            metadata = ctx.outputs.metadata_json,
        ),
    ]

RustLibInfo = provider(
    fields = {
        "name": "Crate name",
        "version": "Crate version",
        "deps": "Crate dependencies",
    },
)

def _aggregate_dependency_info_impl(target, ctx):
    return RustLibInfo(
        name = ctx.rule.attr.name,
        version = ctx.rule.attr.version,
        deps = [target for target in getattr(ctx.rule.attr, "deps", [])]
    )


aggregate_dependency_info = aspect(
    attr_aspects = [
       "deps",
    ],
    doc = "Collects the Crate coordinates of the given rust_library and its direct dependencies",
    implementation = _aggregate_dependency_info_impl,
    provides = [RustLibInfo],
)

assemble_crate = rule(
    implementation = _assemble_crate_impl,
    attrs = {
        "target": attr.label(
            mandatory = True,
            doc = "`rust_library` label to be included in the package",
            aspects = [aggregate_dependency_info]
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """,
        ),
        "authors": attr.string_list(
            doc = """Project authors""",
        ),
        "description": attr.string(
            mandatory = True,
            doc = """
            The description is a short blurb about the package. crates.io will display this with your package. This should be plain text (not Markdown).
            https://doc.rust-lang.org/cargo/reference/manifest.html#the-description-field
            """,
        ),
        "documentation": attr.string(
            doc = """Link to documentation of the project""",
        ),
        "homepage": attr.string(
            mandatory = True,
            doc = """Link to homepage of the project""",
        ),
        "readme_file": attr.label(
            allow_single_file = True,
            mandatory = False,
            doc = """README of the project""",
        ),
        "keywords": attr.string_list(
            doc = """
            The keywords field is an array of strings that describe this package.
            This can help when searching for the package on a registry, and you may choose any words that would help someone find this crate.

            Note: crates.io has a maximum of 5 keywords.
            Each keyword must be ASCII text, start with a letter, and only contain letters, numbers, _ or -, and have at most 20 characters.

            https://doc.rust-lang.org/cargo/reference/manifest.html#the-keywords-field
            """,
        ),
        "categories": attr.string_list(
            doc = """Project categories""",
        ),
        "license": attr.string(
            mandatory = True,
            doc = """
            The license field contains the name of the software license that the package is released under.
            https://doc.rust-lang.org/cargo/reference/manifest.html#the-license-and-license-file-fields
            """,
        ),
        "repository": attr.string(
            mandatory = True,
            doc = """Repository of the project""",
        ),
        "mapping": attr.string_dict(
            doc = """
            Maps Bazel target name to a real crate name, for example:
            { "antlr_rust": "antlr-rust" }
            """,
        ),
        "_crate_assembler_tool": attr.label(
            executable = True,
            cfg = "host",
            default = "@vaticle_bazel_distribution//crates:crate-assembler",
        ),
    },
    outputs = {
        "crate_package": "%{name}.crate",
        "metadata_json": "%{name}.json",
    },
)

def _deploy_crate_impl(ctx):
    deploy_crate_script = ctx.actions.declare_file(ctx.attr.name)

    files = [
        ctx.attr.target[CrateDeploymentInfo].crate,
        ctx.attr.target[CrateDeploymentInfo].metadata,
        ctx.file._crate_deployer,
    ]

    ctx.actions.expand_template(
        template = ctx.file._crate_deployer_wrapper_template,
        output = deploy_crate_script,
        substitutions = {
            "$CRATE_PATH": ctx.attr.target[CrateDeploymentInfo].crate.short_path,
            "$METADATA_JSON_PATH": ctx.attr.target[CrateDeploymentInfo].metadata.short_path,
            "$SNAPSHOT_REPO": ctx.attr.snapshot,
            "$RELEASE_REPO": ctx.attr.release,
            "$DEPLOYER_PATH": ctx.file._crate_deployer.short_path,
        },
    )

    return DefaultInfo(
        executable = deploy_crate_script,
        runfiles = ctx.runfiles(
            files = files,
        ),
    )

deploy_crate = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [CrateDeploymentInfo],
            doc = "assemble_crate target to deploy",
        ),
        "snapshot": attr.string(
            mandatory = True,
            doc = "Snapshot repository to release Crate artifact to",
        ),
        "release": attr.string(
            mandatory = True,
            doc = "Release repository to release Crate artifact to",
        ),
        "_crate_deployer": attr.label(
            allow_single_file = True,
            default = "@vaticle_bazel_distribution//crates:crate-deployer_deploy.jar"
        ),
        "_crate_deployer_wrapper_template": attr.label(
            allow_single_file = True,
            default = "@vaticle_bazel_distribution//crates/templates:deploy.sh",
        )
    },
    executable = True,
    implementation = _deploy_crate_impl,
    doc = "Deploy `assemble_crate` target into Crate repo",
)
