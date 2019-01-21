#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2018 Grakn Labs Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

#!/usr/bin/env python

from __future__ import print_function
import sys
import os
import shutil
import platform
import glob
import subprocess
import tempfile

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
properties = parse_deployment_properties('deployment.properties')
github_repository = properties['github.repository']

if len(sys.argv) != 3:
    print("Error - needs two arguments: <github-username> <github-token>")
    sys.exit(1)

_, github_user, github_token = sys.argv

with open('VERSION') as version_file:
    distribution_version = version_file.read().strip()
    github_tag = 'v{}'.format(distribution_version)

system = platform.system()
tempdir = tempfile.mkdtemp()
if system == 'Darwin':
    ghr = glob.glob('external/ghr_osx_zip/file/*.zip')
    if len(ghr) != 1:
        print('There should be exactly one zip archive containing `ghr`')
        sys.exit(1)
    subprocess.call(['unzip', ghr[0], '-d', tempdir])
    ghr = glob.glob(os.path.join(tempdir, '**/ghr'))[0]
elif system == 'Linux':
    ghr = glob.glob('external/ghr_linux_tar/file/*.tar.gz')
    if len(ghr) != 1:
        print('There should be exactly one tar archive containing `ghr`')
        sys.exit(1)
    subprocess.call(['tar', '-xf', ghr[0], '-C', tempdir])
    ghr = glob.glob(os.path.join(tempdir, '**/ghr'))[0]
else:
    print('Error - your platform ({}) is not supported. Try Linux or macOS instead.'.format(system))
    sys.exit(1)

moved_zipfile=os.path.join(tempdir, 'grakn-core-all.zip')

shutil.copy(os.path.join('dist', 'grakn-core-all.zip'), moved_zipfile)
subprocess.call([
    ghr,
    '-t', github_token,
    '-u', github_user,
    '-r', github_repository,
    '-delete', '-draft', github_tag,
    moved_zipfile
])
