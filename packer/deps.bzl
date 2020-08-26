load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

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

def deps():
    http_archive(
        name = "packer_osx",
        url = "https://releases.hashicorp.com/packer/1.4.0/packer_1.4.0_darwin_amd64.zip",
        sha256 = "475a2a63d37c5bbd27a4b836ffb1ac85d1288f4d55caf04fde3e31ca8e289773",
        build_file_content = 'exports_files(["packer"])'
    )

    http_archive(
        name = "packer_linux",
        url = "https://releases.hashicorp.com/packer/1.4.0/packer_1.4.0_linux_amd64.zip",
        sha256 = "7505e11ce05103f6c170c6d491efe3faea1fb49544db0278377160ffb72721e4",
        build_file_content = 'exports_files(["packer"])'
    )
