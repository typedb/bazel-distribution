#
# GRAKN.AI - THE KNOWLEDGE GRAPH
# Copyright (C) 2018 Grakn Labs Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def github_dependencies_for_deployment():
    http_file(
        name = "ghr_osx_zip",
        urls = ["https://github.com/tcnksm/ghr/releases/download/v0.10.2/ghr_v0.10.2_darwin_386.zip"]
    )
    http_file(
        name = "ghr_linux_tar",
        urls = ["https://github.com/tcnksm/ghr/releases/download/v0.10.2/ghr_v0.10.2_linux_386.tar.gz"]
    )
