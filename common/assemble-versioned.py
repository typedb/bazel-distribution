#!/usr/bin/env python

import os
import shutil
import sys
import tarfile
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


def zip_repackage_with_version(original_zipfile, version, directory_to_upload):
    ext = 'zip'
    original_zip_basedir = original_zipfile[:-len(ext) - 1]
    repackaged_zip_basedir = '{}-{}'.format(original_zip_basedir, version)
    repackaged_zipfile = repackaged_zip_basedir+'.zip'
    with ZipFile(original_zipfile, 'r') as original_zip, \
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

    return repackaged_zipfile


def tar_repackage_with_version(original_archive, version, directory_to_upload):
    extension = 'tar.gz'
    original_archive_basedir = original_archive[:-len(extension) - 1]
    repackaged_archive_basedir = '{}-{}'.format(original_archive_basedir, version)
    tarfile.open(original_archive, mode='r:gz').extractall()
    os.rename(original_archive_basedir, repackaged_archive_basedir)
    repackaged_archive = shutil.make_archive(base_name=repackaged_archive_basedir, format='gztar', base_dir=repackaged_archive_basedir)


output_path = sys.argv[1]
version_path = sys.argv[2]
target_paths = sys.argv[3:]

version = '1.5.0' # open(version_path, 'r').read()

print('output = ' + str(output_path))
print('version = ' + str(version_path))
print('target = ' + str(target_paths))

print('pwd = {}'.format(os.getcwd()))
# print('directory = {}'.format(directory_to_upload))

with ZipFile(output_path, 'w', compression=zipfile.ZIP_DEFLATED) as output:
    for fl in target_paths:
        if fl.endswith('zip'):
            zip = zip_repackage_with_version(fl, version, '.')
            output.write(zip)
        elif fl.endswith('tar.gz'):
            tar_repackage_with_version(fl, version, '.')
        else:
            raise ValueError('This file is neither a zip nor a tar.gz: {}'.format(fl))
