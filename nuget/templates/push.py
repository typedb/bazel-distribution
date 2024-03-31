#!/usr/bin/env python3

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
import hashlib
import json
import os
import shutil
import subprocess as sp
import sys
import tempfile
import zipfile

print("Executing nuget push for {nupkg_path}...")

# sp.check_call([
#     '{dotnet_runtime_path}',
#     'nuget',
#     'push',
#     '{nupkg_path}',
#     '-k',
#     '{api_key}',
#     '-s',
#     '{target_repo_url}'])
sp.check_call('{dotnet_runtime_path} nuget push {nupkg_path} -k {api_key} -s {target_repo_url}', shell=True)

print("Done executing nuget push!")
