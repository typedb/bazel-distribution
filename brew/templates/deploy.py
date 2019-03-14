#!/usr/bin/env python

from __future__ import print_function
import os
import shutil
import subprocess as sp
import sys
import tempfile
import urllib


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
properties = parse_deployment_properties('deployment.properties')
formula_filename = os.path.basename(os.readlink('formula'))
with open('formula') as formula_file:
    formula_template = formula_file.read()
with open('VERSION') as v:
    version = v.read().strip()
tap_type = sys.argv[1]
tap_url = properties['repo.brew.{}'.format(tap_type)]
checksum_of_distribution_local = open('checksum.sha256').read().strip().split(' ')[0]

tap_localpath = tempfile.mkdtemp()
try:
    print('Cloning brew tap: "{}"...'.format(tap_url))
    sp.check_call(['git', 'clone', tap_url, tap_localpath])
    sp.check_call(['mkdir', '-p', 'Formula'], cwd=tap_localpath)
    formula_file = open(os.path.join(tap_localpath, 'Formula', formula_filename), 'w')
    formula_content = formula_template.replace('{version}', version).replace('{sha256}', checksum_of_distribution_local)
    url_line = filter(lambda l: l.lstrip().startswith('url'), formula_content.split('\n'))[0]
    url = url_line.strip().split(' ')[1].replace('"', '')
    print('Attempting to verify that the checksum of local distribution and {} match...'.format(url))
    urllib.urlretrieve(url, 'distribution-github.zip')
    checksum_of_distribution_github = sp.check_output(['shasum', '-a', '256', 'distribution-github.zip']).split(' ')[0]
    if checksum_of_distribution_local != checksum_of_distribution_github:
        print('Error - checksum mismatch between local distribution (sha256 = {}) and "{}" (sha256 = {}).'
              .format(checksum_of_distribution_local, url, checksum_of_distribution_github))
        sys.exit(1)
    print('Checksum matched. Proceeding with updating brew tap...')
    formula_file.write(formula_content)
    sp.check_call(['git', 'add', '.'], cwd=tap_localpath)
    sp.check_call(['git', 'commit', '-m', 'Update the {} formula to {}'.format(formula_filename, version)], cwd=tap_localpath)
    sp.check_call(['bash', '-c', 'git push https://"$GRABL_CREDENTIAL"@github.com/lolski/homebrew-tap master'], cwd=tap_localpath)
    print("Done! That'll be five bucks.")
finally:
    shutil.rmtree(tap_localpath)