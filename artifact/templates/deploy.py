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

from __future__ import print_function

import os
import re
import subprocess as sp
import sys
from posixpath import join as urljoin

import glob
# Prefer using the runfile dependency than system dependency
runfile_deps = [path for path in map(os.path.abspath, glob.glob('external/*/*'))]
sys.path = runfile_deps + sys.path

from common.uploader.uploader import Uploader

if len(sys.argv) != 2:
    raise ValueError('Should pass only <snapshot|release> as arguments')

_, repo_type = sys.argv

username, password = os.getenv('DEPLOY_ARTIFACT_USERNAME'), os.getenv('DEPLOY_ARTIFACT_PASSWORD')

if not username:
    raise ValueError('Error: username should be passed via $DEPLOY_ARTIFACT_USERNAME env variable')

if not password:
    raise ValueError('Error: password should be passed via $DEPLOY_ARTIFACT_PASSWORD env variable')

version = open("{version_file}", "r").read().strip()

snapshot = 'snapshot'
version_snapshot_regex = '^[0-9|a-f|A-F]{40}$'
release = 'release'
version_release_regex = '^[0-9]+.[0-9]+.[0-9]+(-[a-zA-Z0-9]+)*$'

if repo_type not in [snapshot, release]:
    raise ValueError("Invalid repository type: {}. It should be one of these: {}"
                     .format(repo_type, [snapshot, release]))
if repo_type == 'snapshot' and len(re.findall(version_snapshot_regex, version)) == 0:
    raise ValueError('Invalid version: {}. An artifact uploaded to a {} repository '
                     'must have a version which complies to this regex: {}'
                     .format(version, repo_type, version_snapshot_regex))
if repo_type == 'release' and len(re.findall(version_release_regex, version)) == 0:
    raise ValueError('Invalid version: {}. An artifact uploaded to a {} repository '
                     'must have a version which complies to this regex: {}'
                     .format(version, repo_type, version_snapshot_regex))

filename = '{artifact_filename}'
filename = filename.format(version = version)

base_url = None
if repo_type == 'release':
    base_url = '{release}'
else:
    base_url = '{snapshot}'

uploader = Uploader.create(username, password, base_url)
uploader.artifact("{artifact_group}", version, '{artifact_path}', filename)
