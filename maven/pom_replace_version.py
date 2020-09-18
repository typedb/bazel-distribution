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
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--template_file', type=argparse.FileType('rt'))
parser.add_argument('--version_file', type=argparse.FileType('rt'))
parser.add_argument('--pom_file', type=argparse.FileType('wt'))
parser.add_argument('--workspace_refs', required=False, type=argparse.FileType('rt'))
args = parser.parse_args()

refs = {
    'commits': {},
    'tags': {},
}

if args.workspace_refs:
    refs = json.loads(args.workspace_refs.read().strip())

template = args.template_file.read().strip()
version = args.version_file.read().strip()

pom = template
for workspace in refs['commits']:
    pom = pom.replace(workspace, refs['commits'][workspace])
for workspace in refs['tags']:
    pom = pom.replace(workspace, refs['tags'][workspace])
pom = pom.replace('{pom_version}', version)

args.pom_file.write(pom)
