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

#!/usr/bin/env bash

set -e


DEB_REPO_TYPE=$1
DEB_USERNAME="${DEPLOY_APT_USERNAME-notset}"
DEB_PASSWORD="${DEPLOY_APT_PASSWORD-notset}"

if [[ "$DEB_REPO_TYPE" != "snapshot" ]] && [[ "$DEB_REPO_TYPE" != "release" ]]; then
    echo "Error: first argument should be 'snapshot' or 'release', not '$DEB_REPO_TYPE'"
    exit 1
fi

if [[ "$DEB_USERNAME" == "notset" ]]; then
    echo "Error: username should be passed via \$DEPLOY_APT_USERNAME env variable"
    exit 1
fi

if [[ "$DEB_PASSWORD" == "notset" ]]; then
    echo "Error: password should be passed via \$DEPLOY_APT_PASSWORD env variable"
    exit 1
fi

# create a temporary file for preprocessing deployment.properties
DEPLOYMENT_PROPERTIES_STRIPPED_FILE=$(mktemp)
# awk in the next line strips out empty and comment lines
awk '!/^#/ && /./' deployment.properties > ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE}
DEB_URL=$(grep "repo.apt.$DEB_REPO_TYPE" ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE} | cut -d '=' -f 2)

http_status_code_from_upload=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X POST \
    -u $DEB_USERNAME:$DEB_PASSWORD -H "Content-Type: multipart/form-data" --data-binary "@package.deb" $DEB_URL)
if [[ ${http_status_code_from_upload} -ne 201 ]]; then
    echo "Error: The upload failed, got HTTP status code $http_status_code_from_upload"
    exit 1
fi

echo "Deployment completed"
