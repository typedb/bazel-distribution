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

def _file_rename_impl(ctx):
    output_file_name = ctx.attr.output
    replace_count = output_file_name.count("{")
    start_index = 0
    for i in range(replace_count):
        open_curly_index = output_file_name.find("{", start_index)
        close_curly_index = output_file_name.find("}", start_index)
        if open_curly_index == -1 or close_curly_index == -1:
            fail("Could not find matching {} from index: {}.".format(start_index))
        variable = output_file_name[open_curly_index + 1: close_curly_index]
        value = ctx.var.get(variable)
        if value == None:
            fail("Cound not find variable '{}' in the context.".format(variable))
        output_file_name = output_file_name.replace("{" + variable + "}", value)

    output_file = ctx.actions.declare_file(output_file_name)
    ctx.actions.run_shell(
        inputs = [ctx.attr.target.files.to_list()[0]],
        command = "cp $1 $2",
        arguments = [ctx.attr.target.files.to_list()[0].path, output_file.path],
        outputs = [output_file],
    )

    return DefaultInfo(
        files = depset([output_file])
    )


file_rename = rule(
    implementation = _file_rename_impl,
    attrs = {
        "target": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Target producing a file to which to append the variable value.",
        ),
        "output": attr.string(
            mandatory = True,
            doc = "Output filename to produce. Can substitute defined variables using {variable}.",
        ),
    }
)