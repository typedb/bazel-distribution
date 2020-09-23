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
import os
import re
import subprocess as sp
import sys
import tempfile
from posixpath import join as urljoin


def sha1(fn):
    return hashlib.sha1(open(fn, 'rb').read()).hexdigest()


def md5(fn):
    return hashlib.md5(open(fn, 'rb').read()).hexdigest()


def upload(url, username, password, local_fn, remote_fn):
    upload_status_code = sp.check_output([
        'curl', '--silent', '--output', '/dev/stderr',
        '--write-out', '%{http_code}',
        '-u', '{}:{}'.format(username, password),
        '--upload-file', local_fn,
        urljoin(url, remote_fn)
    ]).decode().strip()

    if upload_status_code not in {'200', '201'}:
        raise Exception('upload of {} failed, got HTTP status code {}'.format(
            local_fn, upload_status_code))


def sign(fn):
    # TODO(vmax): current limitation of this functionality
    # is that gpg key should already be present in keyring
    # and should not require passphrase
    asc_file = tempfile.mktemp()
    sp.check_call([
        'gpg',
        '--detach-sign',
        '--armor',
        '--output',
        asc_file,
        fn
    ])
    return asc_file


def unpack_args(_, a, b=False):
    return a, b == '--gpg'


if len(sys.argv) < 2:
    raise ValueError('Should pass <snapshot|release> [--gpg] as arguments')


repo_type, should_sign = unpack_args(*sys.argv)

username, password = os.getenv('DEPLOY_MAVEN_USERNAME'), os.getenv('DEPLOY_MAVEN_PASSWORD')

if not username:
    raise ValueError('Error: username should be passed via $DEPLOY_MAVEN_USERNAME env variable')

if not password:
    raise ValueError('Error: password should be passed via $DEPLOY_MAVEN_PASSWORD env variable')

maven_repositories = {
    "snapshot": "{snapshot}",
    "release": "{release}"
}
maven_url = maven_repositories[repo_type]
jar_path = "$JAR_PATH"
pom_file_path = "$POM_PATH"
srcjar_path = "$SRCJAR_PATH"

namespace = { 'namespace': 'http://maven.apache.org/POM/4.0.0' }
root = ElementTree.parse(pom_file_path).getroot()
group_id = root.find('namespace:groupId', namespace)
artifact_id = root.find('namespace:artifactId', namespace)
version = root.find('namespace:version', namespace)
if group_id is None or len(group_id.text) == 0:
    raise Exception("Could not get groupId from pom.xml")
if artifact_id is None or len(artifact_id.text) == 0:
    raise Exception("Could not get artifactId from pom.xml")
if version is None or len(version.text) == 0:
    raise Exception("Could not get version from pom.xml")

version = version.text

snapshot = 'snapshot'
version_snapshot_regex = '^[0-9|a-f|A-F]{40}$'
release = 'release'
version_release_regex = '^[0-9]+.[0-9]+.[0-9]+$'

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
                     .format(version, repo_type, version_release_regex))

filename_base = '{coordinates}/{artifact}/{version}/{artifact}-{version}'.format(
    coordinates=group_id.text.replace('.', '/'), version=version, artifact=artifact_id.text)

upload(maven_url, username, password, pom_file_path, filename_base + '.pom')
if should_sign:
    upload(maven_url, username, password, sign(pom_file_path), filename_base + '.pom.asc')
upload(maven_url, username, password, jar_path, filename_base + '.jar')
if should_sign:
    upload(maven_url, username, password, sign(jar_path), filename_base + '.jar.asc')
upload(maven_url, username, password, srcjar_path, filename_base + '-sources.jar')
if should_sign:
    upload(maven_url, username, password, sign(srcjar_path), filename_base + '-sources.jar.asc')
# TODO(vmax): use real Javadoc instead of srcjar
upload(maven_url, username, password, srcjar_path, filename_base + '-javadoc.jar')
if should_sign:
    upload(maven_url, username, password, sign(srcjar_path), filename_base + '-javadoc.jar.asc')

with tempfile.NamedTemporaryFile(mode='wt', delete=True) as pom_md5:
    pom_md5.write(md5(pom_file_path))
    pom_md5.flush()
    upload(maven_url, username, password, pom_md5.name, filename_base + '.pom.md5')

with tempfile.NamedTemporaryFile(mode='wt', delete=True) as pom_sha1:
    pom_sha1.write(sha1(pom_file_path))
    pom_sha1.flush()
    upload(maven_url, username, password, pom_sha1.name, filename_base + '.pom.sha1')

with tempfile.NamedTemporaryFile(mode='wt', delete=True) as jar_md5:
    jar_md5.write(md5(jar_path))
    jar_md5.flush()
    upload(maven_url, username, password, jar_md5.name, filename_base + '.jar.md5')

with tempfile.NamedTemporaryFile(mode='wt', delete=True) as jar_sha1:
    jar_sha1.write(sha1(jar_path))
    jar_sha1.flush()
    upload(maven_url, username, password, jar_sha1.name, filename_base + '.jar.sha1')

with tempfile.NamedTemporaryFile(mode='wt', delete=True) as srcjar_md5:
    srcjar_md5.write(md5(srcjar_path))
    srcjar_md5.flush()
    upload(maven_url, username, password, srcjar_md5.name, filename_base + '-sources.jar.md5')
    # TODO(vmax): use checksum of real Javadoc instead of srcjar
    upload(maven_url, username, password, srcjar_md5.name, filename_base + '-javadoc.jar.md5')

with tempfile.NamedTemporaryFile(mode='wt', delete=True) as srcjar_sha1:
    srcjar_sha1.write(sha1(srcjar_path))
    srcjar_sha1.flush()
    upload(maven_url, username, password, srcjar_sha1.name, filename_base + '-sources.jar.sha1')
    # TODO(vmax): use checksum of real Javadoc instead of srcjar
    upload(maven_url, username, password, srcjar_sha1.name, filename_base + '-javadoc.jar.sha1')
