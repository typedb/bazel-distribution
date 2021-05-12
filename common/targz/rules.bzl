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

load("@vaticle_bazel_distribution//common/java_deps:rules.bzl", "java_deps")
load("@vaticle_bazel_distribution//common/zip:rules.bzl", "assemble_zip")

def assemble_targz(name,
                   output_filename = None,
                   targets = [],
                   additional_files = {},
                   empty_directories = [],
                   permissions = {},
                   append_version = True,
                   visibility = ["//visibility:private"],
                   tags = []):
  if output_filename == None:
      output_filename = name
  assemble_zip(
      name = name + "__do_not_reference",
      output_filename = output_filename,
      targets = targets,
      additional_files = additional_files,
      empty_directories = empty_directories,
      permissions = permissions,
      append_version = append_version,
      visibility = visibility,
      tags = tags
  )

  native.genrule(
      name = name,
      cmd = "$(location @vaticle_bazel_distribution//common/targz:repackage) $(location :" + name + "__do_not_reference" + ") $(OUTS)",
      outs = [ output_filename + ".tar.gz" ],
      srcs = [ name + "__do_not_reference" ],
      tools = ["@vaticle_bazel_distribution//common/targz:repackage"], # genrule is evaluated in the context of the calling repository, therefore the path must stay absolute.
      visibility = visibility,
      tags = tags
  )


        name = "{}__do_not_reference__targz_0".format(name),
        deps = targets,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
        tags = tags,

        name="{}__do_not_reference__targz".format(name),
        deps = targets,
        extension = "tar.gz",
        files = additional_files,
        empty_dirs = empty_directories,
        modes = permissions,
