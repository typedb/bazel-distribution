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

load("//packer:rules.bzl", "assemble_packer")
load("//common:generate_json_config.bzl", "generate_json_config")

def assemble_azure(name,
                   image_name,
                   resource_group_name,
                   install,
                   image_publisher="Canonical",
                   image_offer="0001-com-ubuntu-server-focal",
                   image_sku="20_04-lts",
                   files=None):
    """Assemble files for GCP deployment

    Args:
        name: A unique name for this target.
        image_name: name of deployed image
        resource_group_name: name of the resource group to place image in
        install: Bazel label for install file
        files: Files to include into Azure deployment
    """
    if not files:
        files = {}
    install_fn = Label(install).name
    generated_config_target_name = name + "__do_not_reference_config"
    generate_json_config(
        name = generated_config_target_name,
        template = "@graknlabs_bazel_distribution//azure:packer.template.json",
        substitutions = {
            "{image_name}": image_name,
            "{resource_group_name}": resource_group_name,
            "{install}": install_fn,
            "{image_publisher}": image_publisher,
            "{image_offer}": image_offer,
            "{image_sku}": image_sku,
        }
    )
    files[install] = install_fn
    assemble_packer(
        name = name,
        config = generated_config_target_name,
        files = files
    )
