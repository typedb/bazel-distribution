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
from xml.etree import ElementTree

import hashlib
import operator
import os
import re
import subprocess as sp
import sys
import tempfile

print(os.getcwd())


def parse_deployment_properties(fn):
    deployment_properties = {}
    with open(fn) as deployment_properties_file:
        for line in deployment_properties_file.readlines():
            if line.startswith('#'):
                # skip comments
                pass
            elif '=' in line:
                k, v = line.split('=')
                deployment_properties[k] = v.strip()
    return deployment_properties


def sha1(fn):
    return hashlib.sha1(open(fn).read()).hexdigest()


def md5(fn):
    return hashlib.md5(open(fn).read()).hexdigest()


def upload(url, username, password, local_fn, remote_fn):
    upload_status_code = sp.check_output([
        'curl', '--silent', '--output', '/dev/stderr',
        '--write-out', '%{http_code}',
        '-u', '{}:{}'.format(username, password),
        '--upload-file', local_fn,
        url + remote_fn
    ]).strip()

    if upload_status_code != '201':
        raise Exception('upload of {} failed, got HTTP status code {}'.format(
            local_fn, upload_status_code))


if len(sys.argv) != 3:
    raise ValueError('Should pass <snapshot|release> <version> as arguments')
_, repo_type, version = sys.argv

username, password = os.getenv('DEPLOY_MAVEN_USERNAME'), os.getenv('DEPLOY_MAVEN_PASSWORD')

if not username:
    raise ValueError('Error: username should be passed via $DEPLOY_MAVEN_USERNAME env variable')

if not password:
    raise ValueError('Error: password should be passed via $DEPLOY_MAVEN_PASSWORD env variable')

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

deployment_properties = parse_deployment_properties('deployment.properties')
maven_url = deployment_properties['repo.maven.' + repo_type]
jar_path = "$JAR_PATH"
pom_file_path = "$POM_PATH"
group_id, artifact_id, version_placeholder = list(map(operator.attrgetter('text'),
                                                      ElementTree.parse(pom_file_path).getroot()[1:4]))
filename_base = '{coordinates}/{artifact}/{version}/{artifact}-{version}'.format(
    coordinates=group_id.replace('.', '/'), version=version, artifact=artifact_id)

upload(maven_url, username, password, jar_path, filename_base + '.jar')

with open(pom_file_path, 'r') as pom_original, tempfile.NamedTemporaryFile(delete=True) as pom_updated:
    updated = pom_original.read().replace(version_placeholder, version)
    pom_updated.write(updated)
    pom_updated.flush()
    upload(maven_url, username, password, pom_updated.name, filename_base + '.pom')

with tempfile.NamedTemporaryFile(delete=True) as pom_md5:
    pom_md5.write(md5(pom_file_path))
    pom_md5.flush()
    upload(maven_url, username, password, pom_md5.name, filename_base + '.pom.md5')

with tempfile.NamedTemporaryFile(delete=True) as pom_sha1:
    pom_sha1.write(sha1(pom_file_path))
    pom_sha1.flush()
    upload(maven_url, username, password, pom_sha1.name, filename_base + '.pom.sha1')

with tempfile.NamedTemporaryFile(delete=True) as jar_md5:
    jar_md5.write(md5(jar_path))
    jar_md5.flush()
    upload(maven_url, username, password, jar_md5.name, filename_base + '.jar.md5')

with tempfile.NamedTemporaryFile(delete=True) as jar_sha1:
    jar_sha1.write(sha1(jar_path))
    jar_sha1.flush()
    upload(maven_url, username, password, jar_sha1.name, filename_base + '.jar.sha1')
