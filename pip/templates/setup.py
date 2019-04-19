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

from setuptools import setup
from setuptools import find_packages
from os import walk
from os.path import join


def create_init_files(directory):
    for dirName, subdirList, fileList in walk(directory):
        if "__init__.py" not in fileList:
            open(join(dirName, "__init__.py"), "w").close()

packages = find_packages()
for package in packages:
    create_init_files(package)
packages = find_packages()

setup(
    name = "{name}",
    version = "{version}-snapshot",
    description = "{description}",
    long_description = open('README.md').read(),
    long_description_content_type="text/markdown",
    classifiers = {classifiers},
    keywords = "{keywords}",
    url = "{url}",
    author = "{author}",
    author_email = "{author_email}",
    license = "{license}",
    packages=packages,
    install_requires={install_requires},
    zip_safe=False,
)
