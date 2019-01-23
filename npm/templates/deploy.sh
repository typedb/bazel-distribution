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

set -ex

if [[ $# -ne 3 ]]; then
    echo "Should pass <npm-username> <npm-password> <npm-email> as arguments"
    exit 1
fi

NPM_USERNAME="$1"
NPM_PASSWORD="$2"
NPM_EMAIL="$3"

# create a temporary file for preprocessing deployment.properties
DEPLOYMENT_PROPERTIES_STRIPPED_FILE=$(mktemp)
# awk in the next line strips out empty and comment lines
awk '!/^#/ && /./' deployment.properties > ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE}
NPM_REPOSITORY_URL=$(grep "npm.repository-url" ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE} | cut -d '=' -f 2)

export PATH="$(dirname $(readlink external/nodejs/bin/nodejs/bin/npm)):$PATH"
export VERSION="{version}"
cd "./$BAZEL_PACKAGE_NAME/$BAZEL_TARGET_NAME"

chmod a+w .
sed -i '' "s/0.0.0-development/$VERSION/g" package.json

# Log in to `npm`
/usr/bin/expect <<EOD
spawn npm adduser --registry=$NPM_REPOSITORY_URL
expect {
  "Username:" {send "$NPM_USERNAME\r"; exp_continue}
  "Password:" {send "$NPM_PASSWORD\r"; exp_continue}
  "Email: (this IS public)" {send "$NPM_EMAIL\r"; exp_continue}
}
EOD

# Use *without* packing instead because
npm publish
