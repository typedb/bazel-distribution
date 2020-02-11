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


def assemble_gcp(name,
                 project_id,
                 install,
                 zone,
                 image_name,
                 files,
                 image_licenses=None,
                 source_image_family="ubuntu-1604-lts"):
    """Assemble files for GCP deployment

    Args:
        name: A unique name for this target.
        project_id: Google project id
        install: Bazel label for install file
        zone: GCP zone to deploy image to
        image_name: name of deployed image
        files: Files to include into GCP deployment
        image_licenses: licenses to attach to deployed image
        source_image_family: Family of GCP base image
    """
    install_fn = Label(install).name
    generated_config_target_name = name + "__do_not_reference_config"
    generate_json_config(
        name = generated_config_target_name,
        template = "@graknlabs_bazel_distribution//gcp:packer.template.json",
        substitutions = {
            "{project_id}": project_id,
            "{zone}": zone,
            "{image_name}": image_name,
            "{image_licenses}": "[\"{}\"]".format(image_licenses) if image_licenses else "[]",
            "{install}": install_fn,
            "{source_image_family}": source_image_family,
        }
    )
    files[install] = install_fn
    assemble_packer(
        name = name,
        config = generated_config_target_name,
        files = files
    )
