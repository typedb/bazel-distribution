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

load("@io_bazel_rules_kotlin//kotlin:jvm.bzl", "kt_jvm_binary")

def doxygen_to_adoc(name, data, docs_dirs):
    args = ["$(location %s)" % target for target in data] + [
        "--output",
        "cpp/docs",
    ] + ["--dir=%s=%s" % (filename, docs_dirs[filename]) for filename in docs_dirs]
    kt_jvm_binary(
        name = name,
        srcs = [
            "@vaticle_bazel_distribution//docs:cpp/DoxygenParser.kt",
        ],
        main_class = "com.vaticle.typedb.driver.tool.docs.cpp.DoxygenParserKt",
        args = args,
        deps = [
            "@vaticle_bazel_distribution//docs:html_docs_to_adoc_lib",
            "@maven//:org_jsoup_jsoup",
            "@maven//:info_picocli_picocli",
        ],
        data = data,
        visibility = ["//visibility:public"],
    )

def _doxygen_docs_impl(ctx):
    output_directory = ctx.actions.declare_directory(ctx.attr._output_directory)
    files = []
    for target in ctx.attr.sources:
        files.extend(target.files.to_list())

    replacements = {
        "PROJECT_NAME": ctx.attr.project_name,
        "OUTPUT_DIRECTORY" : output_directory.path
    }
    if ctx.attr.strip_from_path != None:
            replacements["STRIP_FROM_PATH"] =ctx.attr.strip_from_path

    if ctx.file.main_page_md != None:
        files.append(ctx.file.main_page_md)
        replacements["USE_MDFILE_AS_MAINPAGE"] = ctx.file.main_page_md.path

    replacements["INPUT"] = " ".join([f.path for f in files])

    # Prepare doxyfile replacements
    replacements_file = ctx.actions.declare_file("%s.replacements" % ctx.attr.name)
    ctx.actions.write(
        output = replacements_file,
        content = "\n".join([(k + " = " +replacements[k]) for k in replacements]),
        is_executable = False,
    )

    # Prepare doxyfile
    doxyfile = ctx.actions.declare_file("%s.doxyfile" % ctx.attr.name)
    ctx.actions.run(
        inputs = [ctx.file._templater_script, ctx.file._doxyfile_template, replacements_file],
        outputs = [doxyfile],
        arguments = [ctx.file._templater_script.path, ctx.file._doxyfile_template.path, replacements_file.path, doxyfile.path],
        executable = "python3",
        use_default_shell_env = True
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
    attrs = {
        "project_name" : attr.string(
            doc = "The project name for the doxygen docs",
            mandatory = True,
        ),
        "sources" : attr.label_list(
            doc = "A list of files made available to doxygen. This is NOT automatically included in the doxyfile",
            mandatory = True,
            allow_files = True,
        ),
        "strip_from_path" : attr.string(
            doc = "Prefix to strip from path of files being processed",
            mandatory = False
        ),
        "main_page_md" : attr.label(
            doc = "The file to use as main page for the generate docs",
            allow_single_file = True,
            mandatory = False
        ),
        "_doxyfile_template" : attr.label(
             doc = "A template for the doxygen configuration file.",
             allow_single_file = True,
             default = "@vaticle_bazel_distribution//docs:cpp/doxyfile.template"
         ),
         "_output_directory" : attr.string(
             doc = "The output directory for the doxygen docs",
             default = "doxygen_docs"
         ),
         "_templater_script": attr.label(
             default = "@vaticle_bazel_distribution//docs:cpp/doxyfile_templater.py",
             allow_single_file = True,
         )
    },
)
