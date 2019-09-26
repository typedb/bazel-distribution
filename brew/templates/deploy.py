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
import hashlib
import os
import shutil
import subprocess as sp
import sys
import tempfile

# usual importing is not possible because
# this script and module with common functions
# are at different directory levels in sandbox
from runpy import run_path
parse_deployment_properties = run_path('common.py')['parse_deployment_properties']


def get_distribution_url_from_formula(content):
    url_line = next(filter(lambda l: l.lstrip().startswith('url'), content.split('\n')))
    url = url_line.strip().split(' ')[1].replace('"', '')
    return url


def url_with_credential(url, credential):
    scheme, rest = url.split('://')
    return scheme + '://"' + credential + '"@' + rest


def get_checksum():
    if os.path.isfile('checksum.sha256'):
        with open('checksum.sha256') as checksum_file:
            return checksum_file.read().strip().split(' ')[0]
    elif 'DEPLOY_BREW_CHECKSUM' in os.environ:
        return os.getenv('DEPLOY_BREW_CHECKSUM')
    else:
        raise ValueError('Error - checksum should either be defined '
                         'in checksum.sha256 file or '
                         '$DEPLOY_BREW_CHECKSUM env variable')


if not os.getenv('DEPLOY_BREW_TOKEN'):
    print('Error - $DEPLOY_BREW_TOKEN must be defined')
    sys.exit(1)


if len(sys.argv) != 2:
    print('Error - needs an argument: <snapshot|release>')
    sys.exit(1)


# configurations #
git_username = 'Grabl'
git_email = 'grabl@grakn.ai'
properties = parse_deployment_properties('deployment.properties')
formula_filename = os.path.basename(os.readlink('formula'))
with open('formula') as formula_file:
    formula_template = formula_file.read()
with open('VERSION') as version_file:
    version = version_file.read().strip()
tap_type = sys.argv[1]
tap_url = properties['repo.brew.{}'.format(tap_type)]

checksum_of_distribution_local = get_checksum()

tap_localpath = tempfile.mkdtemp()
try:
    print('Cloning brew tap: "{}"...'.format(tap_url))
    sp.check_call(['bash', '-c', 'git clone ' + url_with_credential(tap_url, '$DEPLOY_BREW_TOKEN') + ' ' + tap_localpath])
    sp.check_call(["git", "config", "user.email", git_email], cwd=tap_localpath)
    sp.check_call(["git", "config", "user.name", git_username], cwd=tap_localpath)
    sp.check_call(['mkdir', '-p', '{brew_folder}'], cwd=tap_localpath)
    formula_content = formula_template.replace('{version}', version).replace('{sha256}', checksum_of_distribution_local)
    distribution_url = get_distribution_url_from_formula(formula_content)
    print('Attempting to match the checksums of local distribution and Github distribution from "{}"...'.format(distribution_url))
    sp.check_call([
        'curl',
        distribution_url,
        '--location',
        '--output',
        'distribution-github.zip'
    ])
    checksum_of_distribution_github = hashlib.sha256(open('distribution-github.zip').read()).hexdigest()
    if checksum_of_distribution_local != checksum_of_distribution_github:
        print('Error - unable to proceed with deploying to brew! The checksums do not match:')
        print('- The checksum of local distribution: {}'.format(checksum_of_distribution_local))
        print('- The checksum of Github distribution: {}'.format(checksum_of_distribution_github))
        sys.exit(1)
    print('The checksums matched. Proceeding with deploying to brew...')
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
