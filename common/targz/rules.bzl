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

load("@vaticle_bazel_distribution//common:java_deps.bzl", "java_deps")
load("@vaticle_bazel_distribution//common/zip:rules.bzl", "assemble_zip")

def assemble_targz(name, targets, additional_files, permissions, output_filename, **kwargs):
  assemble_zip(
      name = name + "__do_not_reference",
      targets = targets,
      additional_files = additional_files,
      permissions = permissions,
      output_filename = output_filename,
      **kwargs
  )

  native.genrule(
      name = name,
      cmd = "unzip -qq $(location :" + name + "__do_not_reference" + ") -d $(location :" + name + "__do_not_reference" + ")-unzipped && tar -czf $$(realpath $(OUTS)) -C $$(dirname $(location :" + name + "__do_not_reference" + "))/$$(basename $(location :" + name + "__do_not_reference" + ")-unzipped) .",
      outs = [ output_filename + ".tar.gz" ],
      srcs = [ name + "__do_not_reference" ],
      **kwargs
  )
