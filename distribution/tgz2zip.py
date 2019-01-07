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
import os
import sys
import zipfile
import tarfile

_, tgz_fn, zip_fn, prefix = sys.argv

with tarfile.open(tgz_fn, mode='r') as tgz:
    with zipfile.ZipFile(zip_fn, 'w', compression=zipfile.ZIP_DEFLATED) as zip:
        for tarinfo in tgz.getmembers():
            f = ''
            name = './' + os.path.normpath(os.path.join(prefix, tarinfo.name))
            if not tarinfo.isdir():
                f = tgz.extractfile(tarinfo).read()
            else:
                name += '/'
            zi = zipfile.ZipInfo(name)
            zi.compress_type = zipfile.ZIP_DEFLATED
            zi.external_attr = tarinfo.mode << 16
            zip.writestr(zi, f)

