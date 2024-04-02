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

import subprocess
import sys
import os

def unpack_args(_, arg1):
    return arg1

if len(sys.argv) < 2:
    raise ValueError("Should pass <snapshot|release> as arguments")

repo_type = unpack_args(*sys.argv)

nuget_repositories = {
    "snapshot": "{snapshot_url}",
    "release": "{release_url}",
}
target_repo_url = nuget_repositories[repo_type]

api_key = os.getenv('DEPLOY_NUGET_API_KEY')

if not api_key:
    raise ValueError('Error: API key should be passed via $DEPLOY_NUGET_API_KEY env variable')

print(f"Executing nuget push for {nupkg_paths}...")
subprocess.check_call(f"{dotnet_runtime_path} nuget push {nupkg_paths} -k {api_key} -s {target_repo_url}", shell=True)

print("Done executing nuget push!")
