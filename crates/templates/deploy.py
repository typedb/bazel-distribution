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
import os
import struct
import subprocess as sp
import tempfile
from posixpath import join as urljoin


def upload(token, file, url):
    complete_url = urljoin(url, 'api/v1/crates/new')
    upload_status_code = sp.check_output([
        'curl',
        '-vvv',
        '--silent',
        '--output', '/dev/stderr',
        '--write-out', '%{http_code}',
        '--header', 'Authorization: {}'.format(token),
        '--header', 'Content-Type: application/json',
        '--request', 'PUT',
        '--data-binary', '@' + file,
        complete_url
    ]).decode().strip()

    if upload_status_code not in {'200'}:
        raise Exception('upload of {} failed, got HTTP status code {}'.format(
            file, upload_status_code))


crate_path = "$CRATE_PATH"
metadata_json_path = "$METADATA_JSON_PATH"

with open(crate_path, 'rb') as f:
    crate_content = f.read()

with open(metadata_json_path, 'rb') as f:
    metadata_content = f.read()


crate_repositories = {
    'snapshot': "{snapshot}",
    'release': "{release}"
}

parser = argparse.ArgumentParser()
parser.add_argument('repo_type', choices=crate_repositories.keys())
args = parser.parse_args()

repo_type_key = args.repo_type

crate_registry = crate_repositories[repo_type_key]

crate_token = os.getenv('DEPLOY_CRATE_TOKEN')

if not crate_token:
    raise Exception(
        'password should be passed via '
        'DEPLOY_CRATE_TOKEN env variable'
    )

LITTLE_ENDIAN_INTEGER = '<i'


# Cargo sends a single-part body containing both metadata in JSON
# and the actual crate in a tarball. Each part is prefixed with a
# 32-bit little-endian length identifier. Split off the JSON and
# turn the tarball into a Blob as the former needs to be parsed
# before mapping onto an Asset while the latter is simply stored.

payload = bytearray()
payload += struct.pack(LITTLE_ENDIAN_INTEGER, len(metadata_content))
payload += metadata_content
payload += struct.pack(LITTLE_ENDIAN_INTEGER, len(crate_content))
payload += crate_content


with tempfile.NamedTemporaryFile('wb') as complete_package:
    complete_package.write(payload)
    complete_package.flush()
    upload(crate_token, complete_package.name, crate_registry)
