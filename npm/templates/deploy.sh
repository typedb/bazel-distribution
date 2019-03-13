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

NPM_REPO_TYPE="${1-${DEPLOYMENT_REPO_TYPE-notset}}"
NPM_USERNAME="${2-${DEPLOYMENT_USERNAME-notset}}"
NPM_PASSWORD="${3-${DEPLOYMENT_PASSWORD-notset}}"
NPM_EMAIL="${4-${DEPLOYMENT_EMAIL-notset}}"

if [[ "$NPM_REPO_TYPE" != "npmjs" ]] && [[ "$NPM_REPO_TYPE" != "test" ]]; then
    echo "Error: first argument should be 'npmjs|test', not '$NPM_REPO_TYPE'"
    exit 1
fi

if [[ "$NPM_USERNAME" == "notset" ]]; then
    echo "Error: username should be either passed via cmdline or \$DEPLOYMENT_USERNAME env variable"
    exit 1
fi

if [[ "$NPM_PASSWORD" == "notset" ]]; then
    echo "Error: password should be either passed via cmdline or \$DEPLOYMENT_PASSWORD env variable"
    exit 1
fi

if [[ "$NPM_EMAIL" == "notset" ]]; then
    echo "Error: email should be either passed via cmdline or \$DEPLOYMENT_EMAIL env variable"
    exit 1
fi

# create a temporary file for preprocessing deployment.properties
DEPLOYMENT_PROPERTIES_STRIPPED_FILE=$(mktemp)
# awk in the next line strips out empty and comment lines
awk '!/^#/ && /./' deployment.properties > ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE}
NPM_REPOSITORY_URL=$(grep "repo.npm.$NPM_REPO_TYPE" ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE} | cut -d '=' -f 2)

GIT_COMMIT_HASH="$(git -C ${BUILD_WORKSPACE_DIRECTORY} rev-parse HEAD)"

export PATH="$(dirname $(readlink external/nodejs/bin/nodejs/bin/npm)):$PATH"
export VERSION=$(echo {version}|sed -e "s/SNAPSHOT/${GIT_COMMIT_HASH}/g")
cd "./$BAZEL_PACKAGE_NAME/$BAZEL_TARGET_NAME"

chmod a+w .
sed -i.bak -e "s/0.0.0-development/$VERSION/g" package.json && rm -f package.json.bak

# Log in to `npm`
/usr/bin/expect <<EOD
spawn npm adduser --registry=$NPM_REPOSITORY_URL
expect {
  "Username:" {send "$NPM_USERNAME\r"; exp_continue}
  "Password:" {send "$NPM_PASSWORD\r"; exp_continue}
  "Email: (this IS public)" {send "$NPM_EMAIL\r"; exp_continue}
}
EOD

npm publish --registry=$NPM_REPOSITORY_URL
