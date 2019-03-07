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

if [[ $# -ne 3 ]]; then
    echo "Should pass <test> <rpm-username> <rpm-password> as arguments"
    exit 1
fi

RPM_PKG="{RPM_PKG}"
RPM_REPO_TYPE="$1"
RPM_USERNAME="$2"
RPM_PASSWORD="$3"

if [[ "$RPM_REPO_TYPE" != "test" ]]; then
    echo "Error: first argument should be 'test', not '$RPM_REPO_TYPE'"
    exit 1
fi

# create a temporary file for preprocessing deployment.properties
DEPLOYMENT_PROPERTIES_STRIPPED_FILE=$(mktemp)
# awk in the next line strips out empty and comment lines
awk '!/^#/ && /./' deployment.properties > ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE}
RPM_URL=$(grep "rpm.repository-url.$RPM_REPO_TYPE" ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE} | cut -d '=' -f 2)

http_status_code_from_upload=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -X PUT -u $RPM_USERNAME:$RPM_PASSWORD --upload-file package.rpm $RPM_URL/$RPM_PKG/)
if [[ ${http_status_code_from_upload} -ne 200 ]]; then
    echo "Error: The upload failed, got HTTP status code $http_status_code_from_upload"
    exit 1
fi

echo "Deployment completed"
