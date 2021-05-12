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


import os
import sys
import zipfile

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


output_path = sys.argv[1]
version_path = sys.argv[2]
target_paths = sys.argv[3:]

version = open(version_path, 'r').read().strip()

with ZipFile(output_path, 'w', compression=zipfile.ZIP_STORED) as output:
    for target in sorted(target_paths):
        if target.endswith('zip') or target.endswith('tar.gz'):
            path_components = os.path.basename(target).split('.')
            original_zip_basedir = path_components[0]
            extension = '.'.join(path_components[1:])
            repackaged_archive_fn = '{}-{}.{}'.format(original_zip_basedir, version, extension)
            output.write(target, repackaged_archive_fn)
        else:
            raise ValueError('This file is neither a zip nor a tar.gz: {}'.format(target))
