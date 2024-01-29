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
from xml.etree import ElementTree

import hashlib
import os
import re
import subprocess as sp
import sys
import tempfile
from posixpath import join as urljoin

import sys, glob

# Prefer using the runfile dependency than system dependency
runfile_deps = [path for path in map(os.path.abspath, glob.glob('external/*/*'))]
sys.path = runfile_deps + sys.path

from common.uploader.uploader import Uploader


def unpack_args(_, a, b=False):
    return a, b == '--gpg'


if len(sys.argv) < 2:
    raise ValueError('Should pass <snapshot|release> [--gpg] as arguments')

repo_type, should_sign = unpack_args(*sys.argv)

if should_sign: raise NotImplementedError("Signing is not implemented yet")

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

namespace = {'namespace': 'http://maven.apache.org/POM/4.0.0'}
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
version_snapshot_regex = '^[0-9]+.[0-9]+.[0-9]+-[0-9|a-f|A-F]{40}$|.*-SNAPSHOT$'
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
                     .format(version, repo_type, version_release_regex))

uploader = Uploader.create(username, password, maven_url)
uploader.maven(group_id.text, artifact_id.text, version,
    jar_path=jar_path, pom_path=pom_file_path,
    sources_path=srcjar_path if os.path.exists(srcjar_path) else None,
    javadoc_path=srcjar_path if os.path.exists(srcjar_path) else None,
    tests_path = None
)
