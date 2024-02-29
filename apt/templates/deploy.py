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
import subprocess
import shutil

# usual importing is not possible because
# this script and module with common functions
# are at different directory levels in sandbox
import tarfile
import tempfile
from runpy import run_path

import sys, glob
# Prefer using the runfile dependency than system dependency
runfile_deps = [path for path in map(os.path.abspath, glob.glob('external/*/*'))]
sys.path = runfile_deps + sys.path

from common.uploader.uploader import Uploader

parser = argparse.ArgumentParser()
parser.add_argument('repo_type')
args = parser.parse_args()

repo_type_key = args.repo_type

apt_repositories = {
    'snapshot' : "{snapshot}",
    'release' : "{release}"
}

repo_url = apt_repositories[repo_type_key]

apt_username, apt_password = (
    os.getenv('DEPLOY_APT_USERNAME'),
    os.getenv('DEPLOY_APT_PASSWORD'),
)

if not apt_username:
    raise Exception(
        'username should be passed via '
        '$DEPLOY_APT_USERNAME env variable'
    )

if not apt_password:
    raise Exception(
        'password should be passed via '
        '$DEPLOY_APT_PASSWORD env variable'
    )

package_path = "{package_path}"

uploader = Uploader.create(apt_username, apt_password, repo_url)
uploader.apt(package_path)

print('Deployment completed.')
