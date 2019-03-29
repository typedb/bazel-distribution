#!/usr/bin/env python

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

from __future__ import print_function
import glob
import os
import platform
import shutil
import subprocess as sp
import sys
import tarfile
import tempfile
import zipfile


# This ZipFile extends Python's ZipFile and fixes the lost permission issue
class ZipFile(zipfile.ZipFile):
    def extract(self, member, path=None, pwd=None):
        if not isinstance(member, zipfile.ZipInfo):
            member = self.getinfo(member)

        if path is None:
            path = os.getcwd()

        ret_val = self._extract_member(member, path, pwd)
        attr = member.external_attr >> 16
        os.chmod(ret_val, attr)
        return ret_val


def parse_deployment_properties(fn):
    deployment_properties = {}
    with open(fn) as deployment_properties_file:
        for line in deployment_properties_file.readlines():
            if line.startswith('#'):
                # skip comments
                pass
            elif '=' in line:
                k, v = line.split('=')
                deployment_properties[k] = v.strip()
    return deployment_properties


def get_github_token():
    if 'DEPLOY_GITHUB_TOKEN' in os.environ:
        return os.getenv('DEPLOY_GITHUB_TOKEN')
    else:
        raise ValueError('Error: token should be passed via $DEPLOY_GITHUB_TOKEN env variable')


def ghr_extract():
    system = platform.system()
    tempdir = tempfile.mkdtemp()

    if system == 'Darwin':
        ZipFile('external/ghr_osx_zip/file/downloaded', 'r').extractall(tempdir)
        ghr = glob.glob(os.path.join(tempdir, '**/ghr'))[0]
    elif system == 'Linux':
        tarfile.open('external/ghr_linux_tar/file/downloaded', mode='r:gz').extractall(tempdir)
        ghr = glob.glob(os.path.join(tempdir, '**/ghr'))[0]
    else:
        raise ValueError('Error - your platform ({}) is not supported. Try Linux or macOS instead.'.format(system))

    return ghr


def zip_repackage_with_version(original_zipfile, version, directory_to_upload):
    ext = 'zip'
    original_zip_basedir = original_zipfile[:-len(ext) - 1]
    repackaged_zip_basedir = '{}-{}'.format(original_zip_basedir, version)
    repackaged_zipfile = repackaged_zip_basedir+'.zip'
    with ZipFile(original_zipfile, 'r') as original_zip,\
            ZipFile(repackaged_zipfile, 'w', compression=zipfile.ZIP_DEFLATED) as repackaged_zip:
        for orig in sorted(original_zip.infolist()):
            f = ''
            name = './' + os.path.normpath(os.path.join(orig.filename))
            if not orig.filename.endswith('/'):
                f = original_zip.read(orig)
            else:
                name += '/'
            repkg = zipfile.ZipInfo(name)
            repkg.compress_type = zipfile.ZIP_DEFLATED
            repkg.external_attr = orig.external_attr
            repkg.date_time = orig.date_time
            repackaged_zip.writestr(repkg, f)

    shutil.copy(repackaged_zipfile, os.path.join(directory_to_upload, os.path.basename(repackaged_zipfile)))


def tar_repackage_with_version(original_archive, version, directory_to_upload):
    extension = 'tar.gz'
    original_archive_basedir = original_archive[:-len(extension) - 1]
    repackaged_archive_basedir = '{}-{}'.format(original_archive_basedir, version)
    tarfile.open(original_archive, mode='r:gz').extractall()
    os.rename(original_archive_basedir, repackaged_archive_basedir)
    repackaged_archive = shutil.make_archive(base_name=repackaged_archive_basedir, format='gztar', base_dir=repackaged_archive_basedir)
    shutil.copy(repackaged_archive, os.path.join(directory_to_upload, os.path.basename(repackaged_archive)))
    shutil.rmtree(repackaged_archive_basedir)


targets = [] if not "{targets}" else "{targets}".split(',')
has_release_description = bool(int("{has_release_description}"))

github_token = get_github_token()
properties = parse_deployment_properties('deployment.properties')
github_organisation = properties['repo.github.organisation']
github_repository = properties['repo.github.repository']
ghr = ghr_extract()

with open('VERSION') as version_file:
    distribution_version = version_file.read().strip()
    github_tag = 'v{}'.format(distribution_version)

directory_to_upload = tempfile.mkdtemp()

# TODO: remove
print('pwd = {}'.format(os.getcwd()))
print('directory = {}'.format(directory_to_upload))

# TODO: ideally, this should be fixed in ghr itself
# Currently it does not allow supplying empty folders
# However, it also filters out folders inside the folder you supply
# So if we have a folder within a folder, both conditions are
# satisfied and we're able to proceed
dummy_directory = tempfile.mkdtemp(dir=directory_to_upload)

for fl in targets:
    if fl.endswith('zip'):
        zip_repackage_with_version(fl, distribution_version, directory_to_upload)
    elif fl.endswith('tar.gz'):
        tar_repackage_with_version(fl, distribution_version, directory_to_upload)
    else:
        raise ValueError('This file is neither a zip nor a tar.gz: {}'.format(fl))

try:
    exit_code = sp.call([
        ghr,
        '-u', github_organisation,
        '-r', github_repository,
        '-b', open('release_description.txt').read() if has_release_description else '',
        '-delete', '-draft', github_tag,
        directory_to_upload
    ], env={'GITHUB_TOKEN': github_token})
finally:
    shutil.rmtree(directory_to_upload)

sys.exit(exit_code)