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
    echo "Error: username should be either passed via cmdline or \$DEPLOYMENT_USERNAME env variable"
    exit 1
fi

if [[ "$DEB_PASSWORD" == "notset" ]]; then
    echo "Error: password should be either passed via cmdline or \$DEPLOYMENT_PASSWORD env variable"
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
