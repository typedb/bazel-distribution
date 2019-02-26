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
    echo "Should pass <pypi|test|tpypi> <pip-username> <pip-password> as arguments"
    exit 1
fi

PIP_REPO_TYPE="$1"
PIP_USERNAME="$2"
PIP_PASSWORD="$3"

if [[ "$PIP_REPO_TYPE" != "pypi" ]] && [[ "$PIP_REPO_TYPE" != "test" ]]; then
    echo "Error: first argument should be 'pypi' or 'test', not '$PIP_REPO_TYPE'"
    exit 1
fi

# create a temporary file for preprocessing deployment.properties
DEPLOYMENT_PROPERTIES_STRIPPED_FILE=$(mktemp)
# awk in the next line strips out empty and comment lines
awk '!/^#/ && /./' deployment.properties > ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE}
PIP_REPOSITORY_URL=$(grep "pip.repository-url.$PIP_REPO_TYPE" ${DEPLOYMENT_PROPERTIES_STRIPPED_FILE} | cut -d '=' -f 2)

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

GIT_COMMIT_HASH="$(git -C ${BUILD_WORKSPACE_DIRECTORY} rev-parse HEAD)"
sed -i.bak -e "s/SNAPSHOT/$GIT_COMMIT_HASH/g" setup.py && rm -f setup.py.bak

# clean up previous distribution files
rm -fv dist/*
python setup.py sdist
python setup.py bdist_wheel
$TWINE_BINARY upload dist/* -u $PIP_USERNAME -p $PIP_PASSWORD --repository-url $PIP_REPOSITORY_URL
