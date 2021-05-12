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
    repository_ctx.file('BUILD', content='exports_files(["refs.json"])', executable=False)
    workspace_refs_dict = {
        "commits": repository_ctx.attr.workspace_commit_dict,
        "tags": repository_ctx.attr.workspace_tag_dict,
    }
    repository_ctx.file('refs.json', content=struct(**workspace_refs_dict).to_json(), executable=False)


_workspace_refs = repository_rule(
    implementation = _workspace_refs_impl,
    attrs = {
        'workspace_commit_dict': attr.string_dict(),
        'workspace_tag_dict': attr.string_dict(),
    },
)

def workspace_refs(name):

    workspace_commit_dict = {}
    workspace_tag_dict = {}

    for k, v in native.existing_rules().items():
        if 'tags' in v:
            for t in v['tags']:
                key, eq, value = t.partition("=")
                if eq == "=":
                    if key == "tag":
                        workspace_tag_dict[k] = value
                    elif key == "commit":
                        workspace_commit_dict[k] = value

        if 'tag' in v and len(v['tag'])>0:
            workspace_tag_dict[k] = v['tag']
        elif 'commit' in v and len(v['commit'])>0:
            workspace_commit_dict[k] = v['commit']


    _workspace_refs(
        name = name,
        workspace_commit_dict = workspace_commit_dict,
        workspace_tag_dict = workspace_tag_dict
    )
