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

import json
import sys

_, preprocessed_template_path, workspace_refs_path, version_file_path, pom_path = sys.argv

with open(preprocessed_template_path, 'r') as template_file, \
        open(workspace_refs_path, 'r') as refs_file, \
        open(version_file_path, 'r') as version_file, \
        open(pom_path, 'w') as pom_file:

    refs = json.loads(refs_file.read().strip())
    template = template_file.read().strip()
    version = version_file.read().strip()

    pom = template
    for workspace in refs['commits']:
        pom = pom.replace(workspace, refs['commits'][workspace])
    for workspace in refs['tags']:
        pom = pom.replace(workspace, refs['tags'][workspace])
    pom = pom.replace('{pom_version}', version)

    pom_file.write(pom)