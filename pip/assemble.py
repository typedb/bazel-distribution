#!/usr/bin/env python3

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

import argparse
import glob
import os
import re
import shutil
import sys
import tempfile
from typing import List

from setuptools.sandbox import run_setup


def create_init_files(directory):
    from os import walk
    from os.path import join
    for dirName, subdirList, fileList in walk(directory):
        if "__init__.py" not in fileList:
            open(join(dirName, "__init__.py"), "w").close()


def split_path(path: str) -> List[str]:
    head, tail = os.path.split(path)
    dirs = [tail]
    while head:
        head, tail = os.path.split(head)
        dirs.append(tail)
    return dirs[::-1]


def remove_file_suffix(file: str, suffix: str) -> str:
    if len(suffix) == 0:
        return file
    path, ext = os.path.splitext(file)
    if path.endswith(suffix):
        path = path[:-len(suffix)]
    return path + ext


parser = argparse.ArgumentParser()
parser.add_argument('--output_sdist', help="Output targz archive")
parser.add_argument('--output_wheel', help="Output wheel archive")
parser.add_argument('--package_root', help="bazel package root")
parser.add_argument('--setup_py_template', help="setup.py")
parser.add_argument('--requirements_file', help="install_requires")
parser.add_argument('--readme', help="README file")
parser.add_argument('--files', nargs='+', help='Python files to pack into archive')
parser.add_argument('--data_files', nargs='+', default=[], help='Data files to pack into archive')
parser.add_argument('--imports', nargs='+', help='Folders considered to be source code roots')
parser.add_argument('--suffix', help="Suffix that has to be removed from the filenames")

args = parser.parse_args()

# absolutize the path
args.output_sdist = os.path.abspath(args.output_sdist)
args.output_wheel = os.path.abspath(args.output_wheel)
# turn imports into regex patterns
args.imports = list(map(
    lambda imp: re.compile('(?:.*){}[/]?(?P<fn>.*)'.format(imp)),
    args.imports or []
))

# new package root
pkg_dir = tempfile.mkdtemp()

if not args.files:
    raise Exception("Cannot create an archive without any files")

package_root = split_path(args.package_root)

for input_file in args.files + args.data_files:
    packaged_file = input_file

    # We need to move generated files from `bazel-out/.../bin/{package_root}` to the package directory
    if packaged_file.startswith("bazel-out"):
        packaged_file = os.path.join(*split_path(packaged_file)[3:])
        if not packaged_file.startswith(args.package_root):
            # We don't need other files from `bazel-out`
            continue
    if packaged_file.startswith(args.package_root):
        packaged_file = os.path.join(*split_path(packaged_file)[len(package_root):])

    # Remove python version suffix from the file name
    packaged_file = remove_file_suffix(packaged_file, args.suffix)

    for _imp in args.imports:
        match = _imp.match(packaged_file)
        if match:
            packaged_file = match.group('fn')
            break

    try:
        e = os.path.join(pkg_dir, os.path.dirname(packaged_file))
        os.makedirs(e)
    except OSError:
        # directory already exists
        pass
    shutil.copy(input_file, os.path.join(pkg_dir, packaged_file))

# MANIFEST.in is needed for data files that are not included in version control
if args.data_files:
    manifest_in_path = os.path.join(pkg_dir, 'MANIFEST.in')
    with open(manifest_in_path, 'w') as manifest_in:
        for data_file in args.data_files:
            # We need to move generated files from `bazel-out/.../bin/{package_root}` to the package directory
            if data_file.startswith("bazel-out"):
                data_file = os.path.join(*split_path(data_file)[3:])
                if not data_file.startswith(args.package_root):
                    # We don't need other files from `bazel-out`
                    continue
            if data_file.startswith(args.package_root):
                data_file = os.path.join(*split_path(data_file)[len(package_root):])
            # Remove python version suffix from the file name
            data_file = remove_file_suffix(data_file, args.suffix)
            manifest_in.write("include {}\n".format(data_file))

setup_py = os.path.join(pkg_dir, 'setup.py')
readme = os.path.join(pkg_dir, 'README.md')

with open(args.setup_py_template) as setup_py_template:
    install_requires = []
    with open(args.requirements_file) as requirements_file:
        for line in requirements_file.readlines():
            if not line.startswith('#') and not line.startswith('--') and line.strip() != '':
                install_requires.append(line.strip())
    with open(setup_py, 'w') as setup_py_file:
        setup_py_file.write(
            setup_py_template.read().replace("INSTALL_REQUIRES_PLACEHOLDER", str(install_requires))
        )

shutil.copy(args.readme, readme)

# change directory into new package root
os.chdir(pkg_dir)

# ensure every folder is a Python package
create_init_files(pkg_dir)

# pack sources
run_setup(setup_py, ['sdist', 'bdist_wheel'])

sdist_archives = glob.glob('dist/*.tar.gz')
if len(sdist_archives) != 1:
    raise Exception('archive expected was not produced by sdist')

wheel_archives = glob.glob('dist/*.whl')
if len(wheel_archives) != 1:
    raise Exception('archive expected was not produced by bdist_wheel')

shutil.copy(sdist_archives[0], args.output_sdist)
shutil.copy(wheel_archives[0], args.output_wheel)

# Ignore permission errors (for Windows)
try:
    shutil.rmtree(pkg_dir)
except PermissionError as err:
    sys.stderr.write(f"WARNING: unable to delete temporary package directory {pkg_dir}: {str(err)}\n")
