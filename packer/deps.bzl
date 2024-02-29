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
        url = "https://releases.hashicorp.com/packer/1.7.4/packer_1.7.4_darwin_amd64.zip",
        sha256 = "f3faf9dce0cebdfc7abfcf70511c6230e0c0a5c499ca3478def81549ded91b20",
        build_file_content = 'exports_files(["packer"])'
    )

    http_archive(
        name = "packer_linux",
        url = "https://releases.hashicorp.com/packer/1.7.4/packer_1.7.4_linux_amd64.zip",
        sha256 = "3660064a56a174a6da5c37ee6b36107098c6b37e35cc84feb2f7f7519081b1b0",
        build_file_content = 'exports_files(["packer"])'
    )
