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
import tarfile
import platform
import json

import sys
import os


WINDOWS = "windows"


def tarfile_remove_mtime(info):
    info.mtime = 0
    return info


_, moves_file_location, distribution_tgz_location, version_file_location = sys.argv
with open(moves_file_location) as moves_file:
    moves = json.load(moves_file)

with open(version_file_location) as version_file:
    version = version_file.read().strip()

with tarfile.open(distribution_tgz_location, 'w:gz', dereference=True) as tgz:
    for fn, arcfn in sorted(moves.items()):
        path = "\\\\?\\" + os.path.abspath(fn) if platform.system() == WINDOWS else fn
        tgz.add(path, arcfn.replace('{pom_version}', version), filter=tarfile_remove_mtime)
