#!/usr/bin/env python

from __future__ import print_function
import os
import sys
import subprocess as sp
import tempfile


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


if not os.getenv('GRABL_CREDENTIAL'):
    print('Error - $GRABL_CREDENTIAL must be defined')
    sys.exit(1)

if len(sys.argv) != 2:
    print('Error - needs an argument: <test|release>')
    sys.exit(1)


# configurations #
credential = os.getenv('GRABL_CREDENTIAL')
properties = parse_deployment_properties('deployment.properties')
formula_filename = os.path.basename(os.readlink('formula'))
with open('formula') as f:
    formula = f.read()
with open('VERSION') as v:
    version = v.read()
tap_type = sys.argv[1]
tap_url = properties['repo.brew.{}'.format(tap_type)]


tap_localpath = tempfile.mkdtemp() # TODO: delete once done
sp.check_call(['git', 'clone', tap_url, tap_localpath])
sp.check_call(['mkdir', '-p', 'Formula'], cwd=tap_localpath)
with open(os.path.join(tap_localpath, 'Formula', formula_filename), 'w') as f: # TODO: don't hardcode grakn-core.rb
    f.write(formula)
sp.check_call(['git', 'add', '.'], cwd=tap_localpath)
sp.check_call(['git', 'commit', '-m', 'Update the {} formula to {}'.format(formula_filename, version)], cwd=tap_localpath) # TODO: think of a clear msg

# TODO:
#  - make it more secure by not printing credential if command fails
#  - replace origin with credential + url
sp.check_call(['git', 'push', 'https://' + credential + '@github.com/lolski/homebrew-tap/', 'master'], cwd=tap_localpath)