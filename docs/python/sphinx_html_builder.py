#
# Copyright (C) 2022 Vaticle
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
import sys

from sphinx.cmd.build import main
from sphinx.ext import apidoc

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', help="Output directory")
    parser.add_argument('--package', help="Package directory")
    parser.add_argument('--source_dir', help="Sphinx source directory")
    args = parser.parse_args()

    apidoc.main(["-o", args.source_dir, args.package])
    sys.exit(main(["-M", "html", args.source_dir, args.output]))
