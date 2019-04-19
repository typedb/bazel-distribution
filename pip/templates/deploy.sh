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

PIP_REPO_TYPE="$1"
PIP_USERNAME="${DEPLOY_PIP_USERNAME-notset}"
PIP_PASSWORD="${DEPLOY_PIP_PASSWORD-notset}"

if [[ "$PIP_REPO_TYPE" != "release" ]] && [[ "$PIP_REPO_TYPE" != "snapshot" ]]; then
    echo "Error: first argument should be 'release' or 'snapshot', not '$PIP_REPO_TYPE'"
    exit 1
fi

if [[ "$PIP_USERNAME" == "notset" ]]; then
    echo "Error: username should be passed via \$DEPLOY_PIP_USERNAME env variable"
    exit 1
fi

if [[ "$PIP_PASSWORD" == "notset" ]]; then
    echo "Error: password should be passed via \$DEPLOY_PIP_PASSWORD env variable"
    exit 1
fi

# create a temporary file for preprocessing deployment.properties
DEPLOYMENT_PROPERTIES_STRIPPED_FILE=$(mktemp)
# awk in the next line strips out empty and comment lines
awk '!/^#/ && /./' deployment.properties > ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE}
PIP_REPOSITORY_URL=$(grep "repo.pypi.$PIP_REPO_TYPE" ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE} | cut -d '=' -f 2)

# needed for uploading the built package
TWINEPATH=$(dirname $(pwd)/external/*twine*/twine/)
# pkginfo package needed as dependency of twine
PKGINFO_PATH=$(dirname $(pwd)/external/*pkginfo*/pkginfo/)
# readme_renderer package needed as dependency of twine
README_RENDERER_PATH=$(dirname $(pwd)/external/*readme_renderer*/readme_renderer/)
# Pygments package needed as dependency of twine
PYGMENTS_PATH=$(dirname $(pwd)/external/*Pygments*/pygments/)
# requests package needed as dependency of twine
REQUESTS_PATH=$(dirname $(pwd)/external/*requests*/requests/)
# urllib3 package needed as dependency of requests
URLLIB3_PATH=$(dirname $(pwd)/external/*urllib3*/urllib3/)
# chardet package needed as dependency of requests
CHARDET_PATH=$(dirname $(pwd)/external/*chardet*/chardet/)
# certifi package needed as dependency of requests
CERTIFI_PATH=$(dirname $(pwd)/external/*certifi*/certifi/)
# idna package needed as dependency of requests
IDNA_PATH=$(dirname $(pwd)/external/*idna*/idna/)
# tqdm package needed as dependency of requests
TQDM_PATH=$(dirname $(pwd)/external/*tqdm*/tqdm/)
# requests-toolbelt package needed as dependency of requests
REQUESTS_TOOLBELT_PATH=$(dirname $(pwd)/external/*requests_toolbelt*/requests_toolbelt/)
# six package needed as dependency of readme-renderer
SIX_PATH="$(dirname $(pwd)/external/pypi__six_1_12_0/six.py)"
# docutils package needed as dependency of readme-renderer
DOCUTILS_PATH=$(dirname $(pwd)/external/*docutils*/docutils/)
# bleach package needed as dependency of readme-renderer
BLEACH_PATH=$(dirname $(pwd)/external/*bleach*/bleach/)
# webencodings package needed as dependency of readme-renderer
WEBENCODINGS_PATH=$(dirname $(pwd)/external/*webencodings*/webencodings/)

# needed for bdist_wheel
WHEELPATH=$(dirname $(pwd)/external/*wheel*/wheel/)
# updated 'setuptools' package needed for supporting Markdown in README
SETUPTOOLS_PATH=$(dirname $(pwd)/external/*setuptools*/setuptools/)

export PYTHONPATH="$TWINEPATH:$PKGINFO_PATH:$REQUESTS_PATH:$WEBENCODINGS_PATH:$SIX_PATH:$DOCUTILS_PATH:"\
"$BLEACH_PATH:$URLLIB3_PATH:$SIX_PATH:$README_RENDERER_PATH:$PYGMENTS_PATH:$CHARDET_PATH:"\
"$CERTIFI_PATH:$IDNA_PATH:$TQDM_PATH:$REQUESTS_TOOLBELT_PATH:$WHEELPATH:$SETUPTOOLS_PATH"

TWINE_BINARY="python $(pwd)/external/*twine*/twine/__main__.py"

if [[ "$PIP_REPO_TYPE" == "snapshot" ]]; then
    GIT_COMMIT_HASH="$(git -C ${BUILD_WORKSPACE_DIRECTORY} rev-parse HEAD)"
    sed -i.bak -e "s/-snapshot/-$GIT_COMMIT_HASH/g" setup.py && rm -f setup.py.bak
else
    sed -i.bak -e "s/-snapshot//g" setup.py && rm -f setup.py.bak
fi

cat > setup.cfg << EOF
[bdist_wheel]
universal = 1
EOF

# clean up previous distribution files
rm -fv dist/*
python setup.py sdist
python setup.py bdist_wheel
$TWINE_BINARY upload dist/* -u $PIP_USERNAME -p $PIP_PASSWORD --repository-url $PIP_REPOSITORY_URL
