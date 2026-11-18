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

def _workspace_refs_impl(repository_ctx):
    repository_ctx.file("BUILD", content='exports_files(["refs.json"])', executable=False)
    workspace_refs_dict = _module_refs(repository_ctx.read(repository_ctx.attr.module_file))
    repository_ctx.file("refs.json", content=json.encode(workspace_refs_dict), executable=False)


_workspace_refs = repository_rule(
    implementation = _workspace_refs_impl,
    attrs = {
        "module_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The MODULE.bazel whose git_override and local_path_override calls are the refs, e.g. //:MODULE.bazel",
        ),
    },
)

def _module_refs(module_file_content):
    refs = {"commits": {}, "tags": {}, "remotes": {}, "paths": {}}
    for git_overrides in _calls(module_file_content, "git_override"):
        arguments = _string_arguments(git_overrides)
        workspace = _workspace_name(arguments, git_overrides)
        if "commit" in arguments:
            refs["commits"][workspace] = arguments["commit"]
        elif "tag" in arguments:
            refs["tags"][workspace] = arguments["tag"]
        else:
            fail("git_override of '{}' has neither a commit nor a tag".format(arguments["module_name"]))
        refs["remotes"][workspace] = arguments["remote"]
    for local_path_overrides in _calls(module_file_content, "local_path_override"):
        arguments = _string_arguments(local_path_overrides)
        refs["paths"][_workspace_name(arguments, local_path_overrides)] = arguments["path"]
    return refs

def _workspace_name(arguments, call):
    if "module_name" not in arguments:
        fail("cannot read the module_name of an override: " + call)
    return arguments["module_name"] + "+"

def _calls(content, function):
    code = "\n".join([_without_comment(line) for line in content.split("\n")])
    pieces = code.split(function + "(")
    calls = []
    for index in range(1, len(pieces)):
        before = pieces[index - 1]
        if before and (before[-1].isalnum() or before[-1] in "_."):
            continue
        calls.append(_until_closing_parenthesis(pieces[index]))
    return calls

def _without_comment(line):
    quote = None
    for index, character in enumerate(line.elems()):
        if quote:
            if character == quote:
                quote = None
        elif character in "\"'":
            quote = character
        elif character == "#":
            return line[:index]
    return line

def _until_closing_parenthesis(code):
    depth = 1
    for index in range(len(code)):
        if code[index] == "(":
            depth += 1
        elif code[index] == ")":
            depth -= 1
            if depth == 0:
                return code[:index]
    fail("unclosed call in the module file: " + code[:80])

def _string_arguments(call):
    arguments = {}
    for argument in call.split(","):
        name, _, value = argument.partition("=")
        value = value.strip()
        if len(value) >= 2 and value[0] in "\"'" and value[-1] == value[0]:
            arguments[name.strip()] = value[1:-1]
    return arguments
