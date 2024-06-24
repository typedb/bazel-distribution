#!/usr/bin/env python3

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

import argparse
import json
import re

WORKSPACE_REF_PATTERN = re.compile(r'.*%{@(?P<workspace_ref>.*)}.*')

parser = argparse.ArgumentParser()
parser.add_argument('--output', required=True, help='Output file')
parser.add_argument('--version_file', required=True, help='File containing version of package being built')
parser.add_argument('--workspace_refs', help='File with workspace references (optional)')
parser.add_argument('--deps', nargs='+', help='Dependency declarations (optional)')
args = parser.parse_args()

workspace_refs = {
    'commits': {},
    'tags': {}
}

with open(args.version_file) as f:
    version = f.read().strip()

replacements = {
    "%{version}": version
}

if args.workspace_refs:
    with open(args.workspace_refs) as f:
        workspace_refs = json.load(f)

all_workspaces = set()

for ws, commit in workspace_refs['commits'].items():
    replacements["%{{@{}}}".format(ws)] = "0.0.0-" + commit
    all_workspaces.add(ws)

for ws, tag in workspace_refs['tags'].items():
    replacements["%{{@{}}}".format(ws)] = tag
    all_workspaces.add(ws)

deps = []

for dep in (args.deps or []):
    match = WORKSPACE_REF_PATTERN.match(dep)
    if match:
        workspace_ref = match.group('workspace_ref')
        if workspace_ref not in all_workspaces:
            raise Exception('invalid workspace was referenced: `{}`; valid workspaces to reference are: {}'.format(
                workspace_ref, list(all_workspaces)
            ))
    for replacement_key, replacement_val in replacements.items():
        dep = dep.replace(replacement_key, replacement_val)
    deps.append(dep)

with open(args.output, 'w') as out:
    out.write(', '.join(deps))
