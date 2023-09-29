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
import hashlib
import json
import os
import shutil
import subprocess as sp
import sys
import tempfile
import zipfile


def get_distribution_urls_from_formula(content):
    return [
        line[1].strip('"')
        for line in map(lambda line: line.strip().split(), content.split('\n'))
        if len(line) == 2 and line[0] == 'url'
    ]


def get_checksums_from_formula(content):
    return [
        line[1].strip('"')
        for line in map(lambda line: line.strip().split(), content.split('\n'))
        if len(line) == 2 and line[0] == 'sha256'
    ]


def url_with_credential(url, credential):
    scheme, rest = url.split('://')
    return scheme + '://"' + credential + '"@' + rest


def verify_zip_file(fn):
    with zipfile.ZipFile(fn) as zf:
        first_bad_file = zf.testzip()
        if first_bad_file:
            raise ValueError('Corrupt ZIP found at {}; first bad file is {}'.format(fn, first_bad_file))


def verify_environment():
    for var in ["DEPLOY_BREW_TOKEN", "DEPLOY_BREW_USERNAME", "DEPLOY_BREW_EMAIL"]:
        if not os.getenv(var):
            print('Error - ${} must be defined'.format(var))
            sys.exit(1)


def expand_formula_template(formula_template: str, substitution_files: dict[str, str]) -> str:
    expanded = formula_template
    for key, filename in substitution_files.items():
        if os.path.isfile(filename):
            with open(filename) as file:
                expanded = expanded.replace(key, file.read().strip())
        else:
            raise ValueError(f'Error - {filename} substitution for key "{key}" not found (or not a regular file)')
    return expanded


if len(sys.argv) != 2:
    print('Error - needs an argument: <snapshot|release>')
    sys.exit(1)

verify_environment()

substitution_files = json.loads('{substitution_files}')

# configurations #
git_username = os.getenv('DEPLOY_BREW_USERNAME')
git_email = os.getenv('DEPLOY_BREW_EMAIL')
formula_filename = os.path.basename('{formula_template}')
with open('{formula_template}') as formula_file:
    formula_template = formula_file.read()
with open('{version_file}') as version_file:
    version = version_file.read().strip()
tap_type = sys.argv[1]

tap_repositories = {
    "snapshot": "{snapshot}",
    "release": "{release}"
}
tap_url = tap_repositories[tap_type]

tap_localpath = tempfile.mkdtemp()
try:
    print('Cloning brew tap: "{}"...'.format(tap_url))
    sp.check_call(['bash', '-c', 'git clone ' + url_with_credential(tap_url, '$DEPLOY_BREW_TOKEN') + ' ' + tap_localpath])
    sp.check_call(["git", "config", "user.email", git_email], cwd=tap_localpath)
    sp.check_call(["git", "config", "user.name", git_username], cwd=tap_localpath)
    sp.check_call(['mkdir', '-p', '{brew_folder}'], cwd=tap_localpath)

    formula_content = expand_formula_template(formula_template.replace('{version}', version), substitution_files)
    checksums = get_checksums_from_formula(formula_content)
    distribution_urls = get_distribution_urls_from_formula(formula_content)

    if len(checksums) != len(distribution_urls):
        print('Error - unable to proceed with deploying to brew! The number of checksums does not match the number of URLs:')
        print('- found {} checksums'.format(len(checksums)))
        print('- found {} distribution URLs'.format(len(distribution_urls)))
        sys.exit(1)

    for (checksum, distribution_url) in zip(checksums, distribution_urls):
        print('Attempting to match the checksums of local distribution and Github distribution from "{}"...'.format(distribution_url))
        _, ext = os.path.splitext(distribution_url)
        filename = 'distribution-github' + ext
        sp.check_call([
            'curl',
            distribution_url,
            '--fail',
            '--location',
            '--output',
            filename
        ])
        if ext == '.zip':
            verify_zip_file(filename)
        checksum_of_distribution_github = hashlib.sha256(open(filename, 'rb').read()).hexdigest()
        if checksum != checksum_of_distribution_github:
            print('Error - unable to proceed with deploying to brew! The checksums do not match:')
            print('- The checksum of local distribution: {}'.format(checksum))
            print('- The checksum of Github distribution: {}'.format(checksum_of_distribution_github))
            sys.exit(1)
    print('All checksums matched. Proceeding with deploying to brew...')

    with open(os.path.join(tap_localpath, '{brew_folder}', formula_filename), 'w') as f:
        f.write(formula_content)
    sp.check_call(['git', 'add', '.'], cwd=tap_localpath)
    try:
        # the command returns 1 if there is a staged file. otherwise, it will return 0
        should_commit = sp.call(["git", "diff", "--staged", "--exit-code"], cwd=tap_localpath) == 1
        if should_commit:
            sp.check_call(['git', 'commit', '-m', 'Update the {} formula to {}'.format(formula_filename, version)], cwd=tap_localpath)
        else:
            print('Formula {} is already at version {}! there is nothing to commit.'.format(formula_filename, version_file))
    except sp.CalledProcessError as e:
        print('Error - unable to proceed with deploying to brew due to the following error:')
        raise e

    sp.check_call(['bash', '-c', 'git push ' + url_with_credential(tap_url, '$DEPLOY_BREW_TOKEN') + ' master'], cwd=tap_localpath)
    print("Done! Enjoy the beer.")
finally:
    shutil.rmtree(tap_localpath)
