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
    echo "Should pass <pypi|test> <pip-username> <pip-password> as arguments"
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
# needed for bdist_wheel
WHEELPATH=$(dirname $(pwd)/external/*wheel*/wheel/)
# updated 'setuptools' package needed for supporting Markdown in README
SETUPTOOLS_PATH=$(dirname $(pwd)/external/*setuptools*/setuptools/)

export PYTHONPATH="$TWINEPATH:$WHEELPATH:$SETUPTOOLS_PATH"
TWINE_BINARY="python $(pwd)/external/*twine*/twine/__main__.py"

# Replace with package root in rule
cd "$PKG_DIR"

# clean up previous distribution files
rm -fv dist/*
python setup.py sdist
python setup.py bdist_wheel
$TWINE_BINARY upload dist/* -u $PIP_USERNAME -p $PIP_PASSWORD --repository-url $PIP_REPOSITORY_URL
