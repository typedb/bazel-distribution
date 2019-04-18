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
import glob
import os
import platform
import shutil
import subprocess as sp
import sys
import tarfile
import tempfile
import zipfile


GHR_BINARIES = {
    "Darwin": os.path.abspath("{ghr_osx_binary}"),
    "Linux": os.path.abspath("{ghr_linux_binary}"),
}

system = platform.system()
if system not in GHR_BINARIES:
    raise ValueError('Error - your platform ({}) is not supported. Try Linux or macOS instead.'.format(system))

# This ZipFile extends Python's ZipFile and fixes the lost permission issue
class ZipFile(zipfile.ZipFile):
    def extract(self, member, path=None, pwd=None):
        if not isinstance(member, zipfile.ZipInfo):
            member = self.getinfo(member)

        if path is None:
            path = os.getcwd()

        ret_val = self._extract_member(member, path, pwd)
        attr = member.external_attr >> 16
        os.chmod(ret_val, attr)
        return ret_val


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


if not os.getenv('DEPLOY_GITHUB_TOKEN'):
    print('Error - $DEPLOY_GITHUB_TOKEN must be defined')
    sys.exit(1)

if len(sys.argv) != 2:
    print('Error - needs an argument: <commit-id>')
    sys.exit(1)

archive = "{archive}"
has_release_description = bool(int("{has_release_description}"))
github_token = os.getenv('DEPLOY_GITHUB_TOKEN')
target_commit_id = sys.argv[1]
properties = parse_deployment_properties('deployment.properties')
github_organisation = properties['repo.github.organisation']
github_repository = properties['repo.github.repository']
ghr = GHR_BINARIES[system]

with open('VERSION') as version_file:
    github_tag = version_file.read().strip()

directory_to_upload = tempfile.mkdtemp()

if len(archive)>0:
    sp.call(['unzip', archive, '-d', directory_to_upload])
else:
    tempfile.mkdtemp(dir=directory_to_upload)
    # TODO: ideally, this should be fixed in ghr itself
    # Currently it does not allow supplying empty folders
    # However, it also filters out folders inside the folder you supply
    # So if we have a folder within a folder, both conditions are
    # satisfied and we're able to proceed

try:
    exit_code = sp.call([
        ghr,
        '-u', github_organisation,
        '-r', github_repository,
        '-b', open('release_description.txt').read() if has_release_description else '',
        '-c', target_commit_id,
        '-delete', '-draft', github_tag, # TODO: tag must reference the current commit
        directory_to_upload
    ], env={'GITHUB_TOKEN': github_token})
finally:
    shutil.rmtree(directory_to_upload)
sys.exit(exit_code)