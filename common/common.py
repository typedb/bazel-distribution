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
import zipfile
import tarfile


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


def zip_repackage_with_version(original_zipfile, version):
    ext = 'zip'
    original_zip_basedir = os.path.basename(original_zipfile[:-len(ext) - 1])
    repackaged_zip_basedir = '{}-{}'.format(original_zip_basedir, version)
    repackaged_zipfile = repackaged_zip_basedir+'.'+ext
    with ZipFile(original_zipfile, 'r') as original_zip, \
            ZipFile(repackaged_zipfile, 'w', compression=zipfile.ZIP_DEFLATED) as repackaged_zip:
        for orig_info in sorted(original_zip.infolist(), key=lambda info: info.filename):
            repkg_name = orig_info.filename
            repkg_content = ''
            if not orig_info.filename.endswith('/'):
                repkg_content = original_zip.read(orig_info)
            else:
                repkg_name += '/'
            repkg_info = zipfile.ZipInfo(repkg_name.replace(original_zip_basedir, repackaged_zip_basedir))
            repkg_info.compress_type = zipfile.ZIP_DEFLATED
            repkg_info.external_attr = orig_info.external_attr
            repkg_info.date_time = orig_info.date_time
            repackaged_zip.writestr(repkg_info, repkg_content)

    return repackaged_zipfile


def tar_repackage_with_version(original_tarfile, version):
    ext = 'tar.gz'
    original_tar_basedir = os.path.basename(original_tarfile[:-len(ext) - 1])
    repackaged_tar_basedir = '{}-{}'.format(original_tar_basedir, version)
    repackaged_tarfile = repackaged_tar_basedir+'.'+ext
    with tarfile.open(original_tarfile, mode='r:gz') as original_tar, \
            tarfile.open(repackaged_tarfile, mode='w:gz') as repackaged_tar:
        for info in sorted(original_tar.getmembers(), key=lambda info: info.path):
            info.path = info.path.replace(original_tar_basedir, repackaged_tar_basedir, 1)
            info.mtime = 0
            content = original_tar.extractfile(info)
            repackaged_tar.addfile(info, content)
    return repackaged_tarfile
