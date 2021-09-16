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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def deps():

    http_archive(
        name = "ghr_osx_zip",
        urls = ["https://github.com/tcnksm/ghr/releases/download/v0.12.1/ghr_v0.12.1_darwin_amd64.zip"],
        sha256 = "b5d1379e519fc3b795f3b81e5404d427e0abd8837d9e249f483a72f999dd4f47",
        strip_prefix = "ghr_v0.12.1_darwin_amd64",
        build_file_content = 'exports_files(["ghr"])'
    )

    http_archive(
        name = "ghr_linux_tar",
        urls = ["https://github.com/tcnksm/ghr/releases/download/v0.12.1/ghr_v0.12.1_linux_amd64.tar.gz"],
        sha256 = "471c2eb1aee20dedffd00254f6c445abb5eb7d479bcae32c4210fdcf036b2dce",
        strip_prefix = "ghr_v0.12.1_linux_amd64",
        build_file_content = 'exports_files(["ghr"])'
    )

    http_archive(
        name = "ghr_windows_zip",
        urls = ["https://github.com/tcnksm/ghr/releases/download/v0.12.2/ghr_v0.12.2_windows_amd64.zip"],
        sha256 = "47a12017c38ea7d57da6eed319a3cda5ef91dd9c2b1ed4bdfacceb044b7c6c97",
        strip_prefix = "ghr_v0.12.2_windows_amd64",
        build_file_content = 'exports_files(["ghr.exe"])'
    )
