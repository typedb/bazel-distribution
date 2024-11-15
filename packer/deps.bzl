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

def packer_osx():
    http_archive(
        name = "packer_osx",
        build_file_content = 'exports_files(["packer"])',
        url = "https://releases.hashicorp.com/packer/1.8.3/packer_1.8.3_darwin_amd64.zip",
        sha256 = "ef1ceaaafcdada65bdbb45793ad6eedbc7c368d415864776b9d3fa26fb30b896"
    )

def packer_linux():
    http_archive(
        name = "packer_linux",
        build_file_content = 'exports_files(["packer"])',
        url = "https://releases.hashicorp.com/packer/1.8.3/packer_1.8.3_linux_amd64.zip",
        sha256 = "0587f7815ed79589cd9c2b754c82115731c8d0b8fd3b746fe40055d969facba5"
    )
