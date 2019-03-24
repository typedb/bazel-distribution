#!/usr/bin/env python

import json
import sys

_, preprocessed_template_path, workspace_refs_path, version_file_path, pom_path = sys.argv

with open(preprocessed_template_path, 'r') as template_file, \
        open(workspace_refs_path, 'r') as refs_file, \
        open(version_file_path, 'r') as version_file, \
        open(pom_path, 'w') as pom_file:

    refs = json.loads(refs_file.read().strip())
    template = template_file.read().strip()
    version = version_file.read().strip()

    pom = template
    for workspace in refs['commits']:
        pom = pom.replace(workspace, refs['commits'][workspace])
    for workspace in refs['tags']:
        pom = pom.replace(workspace, refs['tags'][workspace])

    pom_file.write(pom)