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
import glob
import os
import shutil
import sys


sys.path.extend(map(os.path.abspath, glob.glob('external/*/*')))
# noinspection PyUnresolvedReferences
import twine.commands.upload

pypi_profile = "{pypi_profile}"
pip_registry = "{snapshot}" if "{snapshot}" else "{release}"

if pypi_profile:
    command = ['./dist/*', '--repository', pypi_profile]
else:
    pip_username, pip_password = (
        os.getenv('DEPLOY_PIP_USERNAME'),
        os.getenv('DEPLOY_PIP_PASSWORD'),
    )

    if not pip_username:
        raise Exception(
            'username should be passed via '
            'DEPLOY_PIP_USERNAME env variable'
        )

    if not pip_password:
        raise Exception(
            'password should be passed via '
            '$DEPLOY_PIP_PASSWORD env variable'
        )
    command = ['./dist/*', '-u', pip_username, '-p', pip_password, '--repository-url', pip_registry]

with open("{version_file}") as version_file:
    version = version_file.read().strip()
new_package_file = None
new_wheel_file = None
try:
    dist_prefix = "./dist/"
    if not os.path.exists(dist_prefix):
        os.mkdir(dist_prefix)
        
    new_package_file = dist_prefix + "{package_file}".replace(".tar.gz", "-{}.tar.gz".format(version))
    new_wheel_file = dist_prefix + "{wheel_file}".replace(".whl", "-{}.whl".format(version))

    if os.path.exists("{package_file}"):
        shutil.copy("{package_file}", new_package_file)

    if os.path.exists("{wheel_file}"):
        shutil.copy("{wheel_file}", new_wheel_file)

    twine.commands.upload.main(command)
finally:
    shutil.rmtree(dist_prefix)
