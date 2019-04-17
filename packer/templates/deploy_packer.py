#!/usr/bin/env python

import os
import tempfile
import tarfile
import platform
import subprocess as sp
import shutil

PACKER_BINARIES = {
    "Darwin": os.path.abspath("{packer_osx_binary}"),
    "Linux": os.path.abspath("{packer_linux_binary}"),
}

system = platform.system()

if system not in PACKER_BINARIES:
    raise ValueError('Packer does not have binary for {}'.format(system))

TARGET_TAR_LOCATION = "{target_tar}"

target_temp_dir = tempfile.mkdtemp('deploy_packer')
with tarfile.open(TARGET_TAR_LOCATION, 'r') as target_tar:
    target_tar.extractall(target_temp_dir)

sp.check_call([
    PACKER_BINARIES[system],
    'build',
    'config.json'
], cwd=target_temp_dir)

shutil.rmtree(target_temp_dir)
