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
import os
import subprocess
import shutil

# usual importing is not possible because
# this script and module with common functions
# are at different directory levels in sandbox
import tarfile
import tempfile
from runpy import run_path

rpm_pkg="{RPM_PKG}"

parse_deployment_properties = run_path('common.py')['parse_deployment_properties']

parser = argparse.ArgumentParser()
parser.add_argument('repo_type')
args = parser.parse_args()

RPM_REPO_PREFIX = 'repo.rpm.'
repo_type_key = RPM_REPO_PREFIX + args.repo_type

properties = parse_deployment_properties('deployment.properties')
if repo_type_key not in properties:
    raise Exception('invalid repo type {}. valid repo types are: {}'.format(
        args.repo_type,
        list(
            map(lambda x: x.replace(RPM_REPO_PREFIX, ''),
                filter(lambda x: x.startswith(RPM_REPO_PREFIX), properties)))
    ))

rpm_registry = properties[repo_type_key]

rpm_username, rpm_password = (
    os.getenv('DEPLOY_RPM_USERNAME'),
    os.getenv('DEPLOY_RPM_PASSWORD'),
)

if not rpm_username:
    raise Exception(
        'username should be passed via '
        '$DEPLOY_RPM_USERNAME env variable'
    )

if not rpm_password:
    raise Exception(
        'password should be passed via '
        '$DEPLOY_RPM_PASSWORD env variable'
    )

package_name = '{}.rpm'.format(
    subprocess.check_output([
        'rpm',
        '-qp',
        'package.rpm'
]).decode().strip())

upload_status_code = subprocess.check_output([
    'curl',
    '--silent',
    '--output', '/dev/stderr',
    '--write-out', '%{http_code}',
    '-u', '{}:{}'.format(rpm_username, rpm_password),
    '-X', 'PUT',
    '--upload-file', 'package.rpm',
    '{}/{}/{}'.format(rpm_registry, rpm_pkg, package_name)
]).decode().strip()

if upload_status_code != '200':
    raise Exception('upload failed, got HTTP status code {}'.format(upload_status_code))

print('Deployment completed.')
