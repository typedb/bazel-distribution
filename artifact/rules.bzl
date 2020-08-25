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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _deploy_artifact_impl(ctx):
    _deploy_script = ctx.actions.declare_file("{}_deploy.py".format(ctx.attr.name))

    version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
    version = ctx.var.get('version', '0.0.0')

    ctx.actions.run_shell(
        inputs = [],
        outputs = [version_file],
        command = "echo {} > {}".format(version, version_file.path),
    )
    
    ctx.actions.expand_template(
        template = ctx.file._deploy_script,
        output = _deploy_script,
        substitutions = {
            "{version_file}": version_file.short_path,
            "{artifact_path}": ctx.file.target.short_path,
            "{artifact_group}": ctx.attr.artifact_group,
            "{artifact_filename}": ctx.attr.artifact_name,
            "{release}": ctx.attr.release,
            "{snapshot}": ctx.attr.snapshot,
        },
    )
    files = [
        ctx.file.target,
        version_file,
    ]

    symlinks = {
        'VERSION': version_file,
    }

    return DefaultInfo(
        executable = _deploy_script,
        runfiles = ctx.runfiles(
            files = files,
            symlinks = symlinks,
        ),
    )


deploy_artifact = rule(
    attrs = {
        "target": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File to deploy to repo",
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """,
        ),
        "artifact_group": attr.string(
            mandatory = True,
            doc = "The group of the artifact.",
        ),
        "artifact_name": attr.string(
            doc = "The artifact filename, automatic from the target file if not specified",
            default = '',
        ),
        "_deploy_script": attr.label(
            allow_single_file = True,
            default = "//artifact/templates:deploy.py",
        ),
        "release": attr.string(
            mandatory = True,
            doc = "Repository that the release artifact will be uploaded to"
        ),
        "snapshot": attr.string(
            mandatory = True,
            doc = "Repository that the snapshot artifact will be uploaded to"
        ),
    },
    executable = True,
    implementation = _deploy_artifact_impl,
    doc = "Deploy archive target into a raw repo",
)


def artifact_file(name,
                  group_name,
                  artifact_name,
                  tag_source,
                  commit_source,
                  downloaded_file_path = None,
                  commit = None,
                  tag = None,
                  sha = None,
                  tags = [],
                  **kwargs):
    """Macro to assist depending on a deployed artifact by generating urls for http_file.

    Args:
        name: Target name.
        group_name: Repo group name used to deploy artifact.
        artifact_name: Artifact name, use {version} to interpolate the version from tag/commit.
        tag_source: Which repository to download the artifact from, if the version given is a tag.
        commit_source: Which repository to download the artifact from, if the version given is a commit.
        downloaded_file_path: Equivalent to http_file downloaded_file_path, defaults to artifact_name, includes {version} interpolation.
        commit: Commit sha, for when this was used as the version for upload.
        tag: Git tag, for when this was used as the version for upload.
        tags: Tags to forward onto the http_file rule.
    """

    version = tag if tag != None else commit
    versiontype = "tag" if tag != None else "commit"

    repository_url = tag_source if tag != None else commit_source

    if downloaded_file_path == None:
        downloaded_file_path = artifact_name

    artifact_name = artifact_name.format(version = version)
    downloaded_file_path = downloaded_file_path.format(version = version)

    http_file(
        name = name,
        urls = ["{}/{}/{}/{}".format(repository_url, group_name, version, artifact_name)],
        downloaded_file_path = artifact_name,
        sha = sha,
        tags = tags + ["{}={}".format(versiontype, version)],
        **kwargs
    )

script_template_tar = """\
#!/bin/bash
set -ex
mkdir -p $BUILD_WORKSPACE_DIRECTORY/$1
tar -xzf {artifact_location} -C $BUILD_WORKSPACE_DIRECTORY/$1 --strip-components=2
"""

script_template_unzip = """\
#!/bin/bash
set -ex
mkdir -p $BUILD_WORKSPACE_DIRECTORY/$1
tmp_dir=$(mktemp -d)
unzip -qq {artifact_location} -d $tmp_dir
mv -v $tmp_dir/{artifact_unpacked_name}/* $BUILD_WORKSPACE_DIRECTORY/$1/
rm -rf {artifact_unpacked_name}
"""

def _artifact_extractor_impl(ctx):
    supported_extensions_script_map = {
        'zip': script_template_unzip,
        'tar.gz': script_template_tar,
        'tgz': script_template_tar,
        'taz': script_template_tar,
        'tar.bz2': script_template_tar,
        'tb2': script_template_tar,
        'tbz': script_template_tar,
        'tbz2': script_template_tar,
        'tz2': script_template_tar,
        'tar.lz': script_template_tar,
        'tar.lzma': script_template_tar,
        'tlz': script_template_tar,
        'tar.lzo': script_template_tar,
        'tar.xz': script_template_tar,
        'txz': script_template_tar,
        'tar.Z': script_template_tar,
        'tar.zst': script_template_tar,
    }

    artifact_file = ctx.file.artifact
    artifact_filename = artifact_file.basename

    extraction_method = ctx.attr.extraction_method

    if (extraction_method == 'auto'):
        artifact_extention = None
        for ext in supported_extensions_script_map.keys():
            if artifact_filename.rfind(ext) == len(artifact_filename) - len(ext):
                artifact_extention = ext
                target_script_template = supported_extensions_script_map.get(ext)
                artifact_unpacked_name = artifact_filename.replace('.' + ext, '')
                break
        
        if artifact_extention == None:
            fail("Extention [{extention}] is not supported by the artifiact_etractor.".format(extention = artifact_file.extension))
    elif (extraction_method == 'tar'):
        target_script_template = script_template_tar
    elif (extraction_method == 'unzip'):
        target_script_template = script_template_unzip

    # Emit the executable shell script.
    script = ctx.actions.declare_file("%s.sh" % ctx.label.name)
    script_content = target_script_template.format(
        artifact_location = artifact_file.short_path,
        artifact_unpacked_name = artifact_unpacked_name
    )

    ctx.actions.write(script, script_content, is_executable = True)

    # The datafile must be in the runfiles for the executable to see it.
    runfiles = ctx.runfiles(files = [artifact_file])
    return [DefaultInfo(executable = script, runfiles = runfiles)]

artifact_extractor = rule(
    implementation = _artifact_extractor_impl,
    attrs = {
        "artifact": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Artifact archive to extract.",
        ),
        "extraction_method": attr.string(
            default = "auto",
            values = ["unzip", "tar", "auto"],
            doc = "the method to use for extracting the artifact."
        )
    },
    executable = True,
)
