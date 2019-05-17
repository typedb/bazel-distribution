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
import common


output_path = sys.argv[1]
version_path = sys.argv[2]
target_paths = sys.argv[3:]

version = open(version_path, 'r').read().strip()

with common.ZipFile(output_path, 'w', compression=zipfile.ZIP_DEFLATED) as output:
    for target in sorted(target_paths):
        if target.endswith('zip'):
            zip = common.zip_repackage_with_version(target, version)
            output.write(zip, os.path.basename(zip))
        elif target.endswith('tar.gz'):
            tar = common.tar_repackage_with_version(target, version)
            output.write(tar, os.path.basename(tar))
        else:
            raise ValueError('This file is neither a zip nor a tar.gz: {}'.format(target))
