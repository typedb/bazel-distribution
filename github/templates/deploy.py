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
import argparse
import os
import platform
import shutil
import subprocess as sp
import sys
import tempfile
import zipfile


GHR_BINARIES = {
    "Darwin": os.path.abspath("{ghr_binary_mac}"),
    "Linux": os.path.abspath("{ghr_binary_linux}"),
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


if not os.getenv('DEPLOY_GITHUB_TOKEN'):
    print('Error - $DEPLOY_GITHUB_TOKEN must be defined')
    sys.exit(1)

parser = argparse.ArgumentParser()
parser.add_argument('commit_id')
parser.add_argument('--archive', help="Archive to deploy")
args = parser.parse_args()

if args.archive and not os.path.isfile(args.archive):
    raise Exception("argument supplied in --archive is not a file")

archive = "{archive}" or args.archive

github_organisation =  "{organisation}"
github_repository = "{repository}"
title = "{title}"
title_append_version = {title_append_version}
release_description = {release_description}
draft = {draft}
github_token = os.getenv('DEPLOY_GITHUB_TOKEN')
target_commit_id = args.commit_id
ghr = GHR_BINARIES[system]

with open('VERSION') as version_file:
    github_tag = version_file.read().strip()

if title and title_append_version:
    title += " {}".format(github_tag)

directory_to_upload = tempfile.mkdtemp()

if archive:
    sp.call(['unzip', archive, '-d', directory_to_upload])
else:
    tempfile.mkdtemp(dir=directory_to_upload)
    # TODO: ideally, this should be fixed in ghr itself
    # Currently it does not allow supplying empty folders
    # However, it also filters out folders inside the folder you supply
    # So if we have a folder within a folder, both conditions are
    # satisfied and we're able to proceed

try:
    cmd = [
        ghr,
        '-u', github_organisation,
        '-r', github_repository,
        '-n', title,
        '-b', open('release_description.txt').read() if release_description else '',
        '-c', target_commit_id,
    ]
    cmd += [ '-delete', '-draft', github_tag ] if draft else [ '-delete', github_tag ]
    cmd += [ directory_to_upload ]
    exit_code = sp.call(cmd, env={'GITHUB_TOKEN': github_token})
finally:
    shutil.rmtree(directory_to_upload)
sys.exit(exit_code)
