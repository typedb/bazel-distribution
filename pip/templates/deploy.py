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

# Prefer using the runfile dependency than system dependency
runfile_deps = [path for path in map(os.path.abspath, glob.glob('external/*/*'))]
sys.path = runfile_deps + sys.path
# noinspection PyUnresolvedReferences
import twine.commands.upload

PYPIRC_KEY = 'pypirc'
SNAPSHOT_KEY = 'snapshot'
RELEASE_KEY = 'release'

ENV_DEPLOY_PIP_USERNAME = 'DEPLOY_PIP_USERNAME'
ENV_DEPLOY_PIP_PASSWORD = 'DEPLOY_PIP_PASSWORD'

repositories = {
    PYPIRC_KEY: "{pypirc_repository}",
    SNAPSHOT_KEY: "{snapshot}",
    RELEASE_KEY: "{release}"
}
publish_args = {publish_args}


parser = argparse.ArgumentParser()
parser.add_argument('repo_type')


def upload_command(repo_type_key, packages):
    if repo_type_key not in repositories:
        raise Exception(f"Selected repository must be one of: {list(repositories.keys())}")

    if repo_type_key == PYPIRC_KEY:
        return packages + ['--repository', repositories[repo_type_key]] + publish_args
    elif repo_type_key == SNAPSHOT_KEY or repo_type_key == RELEASE_KEY:
        pip_username, pip_password = (os.getenv(ENV_DEPLOY_PIP_USERNAME), os.getenv(ENV_DEPLOY_PIP_PASSWORD))
        if not pip_username:
            raise Exception(f"username should be passed via the {ENV_DEPLOY_PIP_USERNAME} environment variable")
        if not pip_password:
            raise Exception(f"password should be passed via the {ENV_DEPLOY_PIP_PASSWORD} environment variable")
        return packages + ['-u', pip_username, '-p', pip_password, '--repository-url', repositories[repo_type_key]] + publish_args
    else:
        raise Exception(f"Unrecognised repository selector: {repo_type_key}")


if not os.path.exists("{source_package}"):
    raise Exception("Cannot find expected distribution .tar.gz to deploy at '{source_package}'")

if not os.path.exists("{wheel_package}"):
    raise Exception("Cannot find expected distribution wheel to deploy at '{wheel_package}'")

args = parser.parse_args()
repo_type_key = args.repo_type

dist_dir = "./dist"
with open("{version_file}") as version_file:
    version = version_file.read().strip()
try:
    source_package_name = dist_dir + "/{source_package}".replace("{suffix}", "").replace(".tar.gz", "-{}.tar.gz".format(version))
    wheel_package_name = dist_dir + "/{wheel_package}".replace("{suffix}", "").replace("-", "_").replace(".whl", "-{}-{distribution_tag}.whl".format(version))

    if not os.path.exists(os.path.dirname(source_package_name)):
        os.makedirs(os.path.dirname(source_package_name))

    if not os.path.exists(os.path.dirname(wheel_package_name)):
        os.makedirs(os.path.dirname(wheel_package_name))

    shutil.copy("{source_package}", source_package_name)
    shutil.copy("{wheel_package}", wheel_package_name)

    # Do not upload a package file if we build for specific platform, because we use a precompiled library
    if "{distribution_tag}".endswith("any"):
        packages = [source_package_name, wheel_package_name]
    else:
        packages = [wheel_package_name]
    twine.commands.upload.main(upload_command(repo_type_key, packages))
finally:
    try:
        shutil.rmtree(dist_dir)
    except PermissionError as err:
        sys.stderr.write(f"WARNING: unable to delete temporary distribution directory {dist_dir}: {str(err)}\n")
