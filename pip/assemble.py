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
import tempfile
from setuptools.sandbox import run_setup


def onerror(func, path, exc_info):
    """
    Error handler for ``shutil.rmtree``.

    If the error is due to an access error (read only file)
    it attempts to add write permission and then retries.

    If the error is for another reason it re-raises the error.

    Usage : ``shutil.rmtree(path, onerror=onerror)``
    """
    import stat
    # Is the error an access error?
    if not os.access(path, os.W_OK):
        os.chmod(path, stat.S_IWUSR)
        func(path)
    else:
        raise


def create_init_files(directory):
    from os import walk
    from os.path import join
    for dirName, subdirList, fileList in walk(directory):
        if "__init__.py" not in fileList:
            open(join(dirName, "__init__.py"), "w").close()


# def split_path(path: str) -> list[str]:
#     head, tail = os.path.split(path)
#     dirs = [tail]
#     while head:
#         head, tail = os.path.split(head)
#         dirs.append(tail)
#     return dirs[::-1]


parser = argparse.ArgumentParser()
parser.add_argument('--output_sdist', help="Output targz archive")
parser.add_argument('--output_wheel', help="Output wheel archive")
parser.add_argument('--setup_py', help="setup.py")
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

for f in args.files + args.data_files:
    fn = f
    # We need to move generated files from `bazel-out/.../bin/python` to the package directory
    fn = re.sub(r"bazel-out[/\\][^/\\]*[/\\]bin[/\\]python[/\\](typedb[/\\])(.*)", r"\1\2", fn)
    # Remove python version suffix from the file name
    fn = re.sub(r"(.*)" + args.suffix + r"(\..*)", r"\1\2", fn)

    for _imp in args.imports:
        match = _imp.match(fn)
        if match:
            fn = match.group('fn')
            break
    # We do not need other files from `bazel-out`
    if not fn.startswith("bazel-out"):
        # Remove `python` from the beginning of the path
        fn = re.sub(r"(python[/\\]|)(.*)", r"\2", fn)
        try:
            e = os.path.join(pkg_dir, os.path.dirname(fn))
            os.makedirs(e)
        except OSError:
            # directory already exists
            pass
        shutil.copy(f, os.path.join(pkg_dir, fn))

# MANIFEST.in is needed for data files that are not included in version control
if args.data_files:
    manifest_in_path = os.path.join(pkg_dir, 'MANIFEST.in')
    with open(manifest_in_path, 'w') as manifest_in:
        for f in args.data_files:
            # We need to move generated files from `bazel-out/.../bin/python/typedb` to the package directory
            f = re.sub(r"bazel-out[/\\][^/\\]*[/\\]bin[/\\]python[/\\](typedb[/\\])(.*)", r"\1\2", f)
            # Remove python version suffix from the file name
            f = re.sub(r"(.*)" + args.suffix + r"(\..*)", r"\1\2", f)
            # We do not need other files from `bazel-out`
            if not f.startswith("bazel-out"):
                manifest_in.write("include {}\n".format(f))

setup_py = os.path.join(pkg_dir, f'setup{args.suffix}.py')
setup_py_final = os.path.join(pkg_dir, f'setup.py')
readme = os.path.join(pkg_dir, f'README{args.suffix}.md')

with open(args.setup_py) as setup_py_template:
    install_requires = []
    with open(args.requirements_file) as requirements_file:
        for line in requirements_file.readlines():
            if not line.startswith('#') and not line.startswith('--') and line.strip() != '':
                install_requires.append(line.strip())
    with open(setup_py, 'w') as setup_py_file:
        setup_py_file.write(
            setup_py_template.read().replace("INSTALL_REQUIRES_PLACEHOLDER", str(install_requires))
        )

os.rename(setup_py, setup_py_final)
shutil.copy(args.readme, readme)

# change directory into new package root
os.chdir(pkg_dir)

# ensure every folder is a Python package
create_init_files(pkg_dir)

# pack sources
run_setup(setup_py_final, ['sdist', 'bdist_wheel'])

sdist_archives = glob.glob('dist/*.tar.gz')
if len(sdist_archives) != 1:
    raise Exception('archive expected was not produced by sdist')

wheel_archives = glob.glob('dist/*.whl')
if len(wheel_archives) != 1:
    raise Exception('archive expected was not produced by bdist_wheel')

shutil.copy(sdist_archives[0], args.output_sdist)
shutil.copy(wheel_archives[0], args.output_wheel)
shutil.rmtree(pkg_dir, onerror=onerror)
