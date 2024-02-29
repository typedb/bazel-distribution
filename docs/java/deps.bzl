#
# Copyright (C) 2022 Vaticle
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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def deps():
    # Bazel Common Libraries (with javadoc)
    http_archive(
        name = "google_bazel_common",
        sha256 = "e982cc2e4c9a7d664e77d97a99debb3d18261e6ac6ea5bc4d8f453a521fdf1cf",
        strip_prefix = "bazel-common-78cc73600ddfa62f953652625abd7c6f1656cfac",
        urls = ["https://github.com/google/bazel-common/archive/78cc73600ddfa62f953652625abd7c6f1656cfac.zip"],
    )
