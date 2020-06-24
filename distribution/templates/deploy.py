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

from __future__ import print_function

import os
import re
import subprocess as sp
import sys
from posixpath import join as urljoin

# usual importing is not possible because
# this script and module with common functions
# are at different directory levels in sandbox
from runpy import run_path
parse_deployment_properties = run_path('common.py')['parse_deployment_properties']


def upload(url, username, password, local_fn, remote_fn):
    upload_status_code = sp.check_output([
        'curl', '--silent', '--output', '/dev/stderr',
        '--write-out', '%{http_code}',
        '-u', '{}:{}'.format(username, password),
        '--upload-file', local_fn,
        urljoin(url, remote_fn)
    ]).decode().strip()

    if upload_status_code != '201':
        raise Exception('upload of {} failed, got HTTP status code {}'.format(
            local_fn, upload_status_code))


if len(sys.argv) != 2:
    raise ValueError('Should pass only <snapshot|release> as arguments')

_, repo_type = sys.argv

username, password = os.getenv('DEPLOY_DISTRIBUTION_USERNAME'), os.getenv('DEPLOY_DISTRIBUTION_PASSWORD')

if not username:
    raise ValueError('Error: username should be passed via $DEPLOY_DISTRIBUTION_USERNAME env variable')

if not password:
    raise ValueError('Error: password should be passed via $DEPLOY_DISTRIBUTION_PASSWORD env variable')

version = open("{version_file}", "r").read().strip()

repo_type_snapshot = 'snapshot'
version_snapshot_regex = '^[0-9|a-f|A-F]{40}$'
repo_type_release = 'release'
version_release_regex = '^[0-9]+.[0-9]+.[0-9]+$'

if repo_type not in [repo_type_snapshot, repo_type_release]:
    raise ValueError("Invalid repository type: {}. It should be one of these: {}"
                     .format(repo_type, [repo_type_snapshot, repo_type_release]))
if repo_type == 'snapshot' and len(re.findall(version_snapshot_regex, version)) == 0:
    raise ValueError('Invalid version: {}. An artifact uploaded to a {} repository '
                     'must have a version which complies to this regex: {}'
                     .format(version, repo_type, version_snapshot_regex))
if repo_type == 'release' and len(re.findall(version_release_regex, version)) == 0:
    raise ValueError('Invalid version: {}. An artifact uploaded to a {} repository '
                     'must have a version which complies to this regex: {}'
                     .format(version, repo_type, version_snapshot_regex))

split_artifact = os.path.basename('{artifact_path}').split('.', 1)

filename = '{artifact_group}/{artifact_name}/{version}/{artifact_name}.{artifact_extension}'.format(
    version=version, artifact_name=split_artifact[0], artifact_extension=split_artifact[1])

deployment_properties = parse_deployment_properties('deployment.properties')
distribution_url = deployment_properties['repo.distribution.' + repo_type]

upload(distribution_url, username, password, '{artifact_path}', filename)