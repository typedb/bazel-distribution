#!/usr/bin/env python

from __future__ import print_function

import hashlib
import sys
import tempfile
import subprocess as sp
from operator import attrgetter
from xml.etree import ElementTree

import os
print(os.getcwd())

MAVEN_REPO_KEY_PREFIX = 'repo.maven.'


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


def sha1(fn):
    return hashlib.sha1(open(fn).read()).hexdigest()


def md5(fn):
    return hashlib.md5(open(fn).read()).hexdigest()


def upload(url, username, password, local_fn, remote_fn):
    upload_status_code = sp.check_output([
        'curl', '--silent', '--output', '/dev/stderr',
        '--write-out', '%{http_code}',
        '-u', '{}:{}'.format(username, password),
        '--upload-file', local_fn,
        url + remote_fn
    ]).strip()

    if upload_status_code != '201':
        raise Exception('upload of {} failed, got HTTP status code {}'.format(
            local_fn, upload_status_code))


jar_path = "$JAR_PATH"
pom_file_path = "$POM_PATH"

pom_file_tree = ElementTree.parse(pom_file_path)
group_id, artifact_id, version = list(map(attrgetter('text'),
                                          pom_file_tree.getroot()[1:4]))


properties = parse_deployment_properties('external/graknlabs_build_tools/deployment.properties')
valid_keys = [x.replace(MAVEN_REPO_KEY_PREFIX, '') for x in properties if x.startswith(MAVEN_REPO_KEY_PREFIX)]


if len(sys.argv) != 5:
    raise ValueError('Should pass <snapshot|release> <maven-username> <maven-password> as arguments')

_, maven_repo_type, version, maven_username, maven_password = sys.argv

if maven_repo_type not in valid_keys:
    raise ValueError("first argument should be one of {}, not {}".format(valid_keys, maven_repo_type))

maven_url = properties[MAVEN_REPO_KEY_PREFIX + maven_repo_type]

filename_base = '{coordinates}/{artifact}/{version}/{artifact}-{version}'.format(
    coordinates=group_id.replace('.', '/'), version=version, artifact=artifact_id)

upload(maven_url, maven_username, maven_password, jar_path, filename_base + '.jar')

with open(pom_file_path, 'r') as pom_original, tempfile.NamedTemporaryFile(delete=True) as pom_updated:
    updated = pom_original.read().replace('{pom_version}', version)
    pom_updated.write(updated)
    pom_updated.flush()
    upload(maven_url, maven_username, maven_password, pom_updated.name, filename_base + '.pom')

with tempfile.NamedTemporaryFile(delete=True) as pom_md5:
    pom_md5.write(md5(pom_file_path))
    pom_md5.flush()
    upload(maven_url, maven_username, maven_password, pom_md5.name, filename_base + '.pom.md5')

with tempfile.NamedTemporaryFile(delete=True) as pom_sha1:
    pom_sha1.write(sha1(pom_file_path))
    pom_sha1.flush()
    upload(maven_url, maven_username, maven_password, pom_sha1.name, filename_base + '.pom.sha1')

with tempfile.NamedTemporaryFile(delete=True) as jar_md5:
    jar_md5.write(md5(jar_path))
    jar_md5.flush()
    upload(maven_url, maven_username, maven_password, jar_md5.name, filename_base + '.jar.md5')

with tempfile.NamedTemporaryFile(delete=True) as jar_sha1:
    jar_sha1.write(sha1(jar_path))
    jar_sha1.flush()
    upload(maven_url, maven_username, maven_password, jar_sha1.name, filename_base + '.jar.sha1')
