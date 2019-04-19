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

def github_dependencies_for_deployment():
    http_archive(
        name = "ghr_osx_zip",
        urls = ["https://github.com/tcnksm/ghr/releases/download/v0.10.2/ghr_v0.10.2_darwin_386.zip"],
        sha256 = "453fa48b6837f36ff32ccfe3f4f6ad7c131952c87370c38d18f83b6614c00bb3",
        strip_prefix = "ghr_v0.10.2_darwin_386",
        build_file_content = 'exports_files(["ghr"])'
    )
    http_archive(
        name = "ghr_linux_tar",
        urls = ["https://github.com/tcnksm/ghr/releases/download/v0.10.2/ghr_v0.10.2_linux_386.tar.gz"],
        sha256 = "214ec68b48516d2d2e627fbf4da1a4cc84d182de5945c63c07aea53c2b8cc166",
        strip_prefix = "ghr_v0.10.2_linux_386",
        build_file_content = 'exports_files(["ghr"])'
    )
