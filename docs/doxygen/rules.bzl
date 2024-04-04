#
# Copyright (C) 2022 Vaticle
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

def _doxygen_docs_impl(ctx):
    output_directory = ctx.actions.declare_directory(ctx.attr._output_directory)
    files = []
    for target in ctx.attr.sources:
        files.extend(target.files.to_list())

    replacements = {
        "PROJECT_NAME": '"' + ctx.attr.project_name + '"',
        "PROJECT_NUMBER" : ctx.attr.version,
        "PROJECT_BRIEF" : ctx.attr.desc,
        "OUTPUT_DIRECTORY" : output_directory.path,
        "STRIP_FROM_PATH": ctx.attr.strip_prefix,
    }
    if ctx.file.main_page_md != None:
        files.append(ctx.file.main_page_md)
        replacements["USE_MDFILE_AS_MAINPAGE"] = ctx.file.main_page_md.path

    replacements["INPUT"] = " ".join([f.path for f in files])

    # Prepare doxyfile
    doxyfile = ctx.actions.declare_file("%s.doxyfile" % ctx.attr.name)
    ctx.actions.expand_template(
        template = ctx.file._doxyfile_template,
        output = doxyfile,
        substitutions = {"##{{%s}}"%k : replacements[k] for k in replacements}
    )

    files = [doxyfile] + files
    print(doxyfile.path)
    ctx.actions.run(
        inputs = files,
        outputs = [output_directory],
        arguments = [doxyfile.path],
        executable = "doxygen",
        use_default_shell_env = True
    )

    return DefaultInfo(files = depset([output_directory]))

doxygen_docs = rule(
    implementation = _doxygen_docs_impl,
    test = False,
    attrs = {
        "project_name" : attr.string(
            doc = "The project name for the doxygen docs",
            mandatory = True,
        ),
        "version" : attr.string(
            doc = "The version of the project being documented",
            default = ""
        ),
        "desc" : attr.string(
            doc = "A description for the project",
            default = ""
        ),
        "sources" : attr.label_list(
            doc = "A list of files made available to doxygen. This is NOT automatically included in the doxyfile",
            mandatory = True,
            allow_files = True,
        ),
        "strip_prefix" : attr.string(
            doc = "Prefix to strip from path of files being processed",
            default = ""
        ),
        "main_page_md" : attr.label(
            doc = "The file to use as main page for the generate docs",
            allow_single_file = True,
            mandatory = False
        ),
        "_doxyfile_template" : attr.label(
             allow_single_file = True,
             default = "//docs:doxygen/doxyfile.template"
        ),
        "_output_directory" : attr.string(
             doc = "The output directory for the doxygen docs",
             default = "doxygen_docs"
        )
    },
    doc = """
        Creates HTML documentation for C++ and C# projects using Doxygen.
        This rule is not hermetic, and requires doxygen to be installed on the host.
        """
)
