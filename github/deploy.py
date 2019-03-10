#!/usr/bin/env python

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
github_organisation = properties['repo.github.organisation']
github_repository = properties['repo.github.repository']

if len(sys.argv) != 2:
    print("Error - needs an argument: <github-token>")
    sys.exit(1)

_, github_token = sys.argv

with open('VERSION') as version_file:
    distribution_version = version_file.read().strip()
    github_tag = 'v{}'.format(distribution_version)

system = platform.system()
tempdir = tempfile.mkdtemp()
if system == 'Darwin':
    subprocess.call(['unzip', 'external/ghr_osx_zip/file/downloaded', '-d', tempdir])
    ghr = glob.glob(os.path.join(tempdir, '**/ghr'))[0]
elif system == 'Linux':
    subprocess.call(['tar', '-xf', 'external/ghr_linux_tar/file/downloaded', '-C', tempdir])
    ghr = glob.glob(os.path.join(tempdir, '**/ghr'))[0]
else:
    print('Error - your platform ({}) is not supported. Try Linux or macOS instead.'.format(system))
    sys.exit(1)

moved_zipfile = os.path.join(tempdir, 'grakn-core-all.zip')

shutil.copy(os.path.join('grakn-core-all.zip'), moved_zipfile)
subprocess.call([
    ghr,
    '-t', github_token,
    '-u', github_organisation,
    '-r', github_repository,
    '-delete', '-draft', github_tag,
    moved_zipfile
])