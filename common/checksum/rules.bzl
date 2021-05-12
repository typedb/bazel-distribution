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

def _checksum(ctx):
    ctx.actions.run_shell(
        inputs = [ctx.file.archive],
        outputs = [ctx.outputs.checksum_file],
        command = 'mkdir tmp; unzip {} -d tmp; shasum -a 256 tmp/* > {}; rm -rf tmp/'.format(ctx.file.archive.path, ctx.outputs.checksum_file.path)
    )

checksum = rule(
    attrs = {
        'archive': attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "Archive to compute checksum of"
        )
    },
    outputs = {
        'checksum_file': '%{name}.sha256'
    },
    implementation = _checksum,
    doc = "Computes SHA256 checksum of file"
)
