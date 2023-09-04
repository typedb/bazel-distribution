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
from setuptools import find_namespace_packages

packages = find_namespace_packages()

with open('README.md') as f:
    readme = f.read()

setup(
    name = "{name}",
    version = "{version}",
    description = "{description}",
    long_description = readme,
    long_description_content_type="text/markdown",
    classifiers = {classifiers},
    keywords = "{keywords}",
    url = "{url}",
    author = "{author}",
    author_email = "{author_email}",
    license = "{license}",
    packages=packages,
    include_package_data = True,
    install_requires=INSTALL_REQUIRES_PLACEHOLDER,
    zip_safe=False,
    python_requires="{python_requires}",
    setup_requires=["wheel"]
)
