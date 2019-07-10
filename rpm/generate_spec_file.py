#!/usr/bin/env python

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

parser = argparse.ArgumentParser()
parser.add_argument('--output', required=True, help='Output .spec file')
parser.add_argument('--spec_file', required=True, help='Input .spec file')
parser.add_argument('--workspace_refs', help='Optional file with workspace references')
args = parser.parse_args()

workspace_refs = {
    'commits': {},
    'tags': {}
}

replacements = {}

if args.workspace_refs:
    with open(args.workspace_refs) as f:
        workspace_refs = json.load(f)

for ws, commit in workspace_refs['commits'].items():
    replacements["%{{@{}}}".format(ws)] = commit

for ws, tag in workspace_refs['tags'].items():
    replacements["%{{@{}}}".format(ws)] = tag

with open(args.spec_file) as spec, open(args.output, 'w') as output:
    lines = spec.readlines()
    for line in lines:
        for replacement_key, replacement_value in replacements.items():
            line = line.replace(replacement_key, replacement_value)
        output.write(line)
