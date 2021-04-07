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
import tempfile
import tarfile
import platform
import subprocess as sp
import shutil

PACKER_BINARIES = {
    "Darwin": os.path.abspath("{packer_osx_binary}"),
    "Linux": os.path.abspath("{packer_linux_binary}"),
}

system = platform.system()

if system not in PACKER_BINARIES:
    raise ValueError('Packer does not have binary for {}'.format(system))

TARGET_TAR_LOCATION = "{target_tar}"

target_temp_dir = tempfile.mkdtemp('deploy_packer')
with tarfile.open(TARGET_TAR_LOCATION, 'r') as target_tar:
    target_tar.extractall(target_temp_dir)

args = [
    PACKER_BINARIES[system],
    'build',
]
if "{force}":
    args.append("-force")
args.append('config.json')
sp.check_call(args, cwd=target_temp_dir)

shutil.rmtree(target_temp_dir)
