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
import os
import stat

import sys
import zipfile
import tarfile

_, tgz_fn, zip_fn = sys.argv


with tarfile.open(tgz_fn, mode='r:gz') as tgz:
    with zipfile.ZipFile(zip_fn, 'w', compression=zipfile.ZIP_DEFLATED) as zip:
        for tarinfo in sorted(tgz.getmembers(), key=lambda x: x.name):
            f = ''
            is_dir = tarinfo.isdir()
            name = tarinfo.name
            if not is_dir:
                f = tgz.extractfile(tarinfo).read()
            else:
                name += '/'
            zi = zipfile.ZipInfo(name)
            zi.compress_type = zipfile.ZIP_DEFLATED
            zi.external_attr = tarinfo.mode << 16
            if not is_dir:
                # Mark regular files with S_IFREG so
                # permissions are preserved when unpacking
                # in macOS's Finder
                zi.external_attr |= (stat.S_IFREG << 16)
            zip.writestr(zi, f)
