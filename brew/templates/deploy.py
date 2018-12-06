#!/usr/bin/env python

from __future__ import print_function
import os
import subprocess
import sys

VERSION = '{brew_version}'
URL = 'https://github.com/graknlabs/grakn/releases/download/{brew_version}/grakn-core-{brew_version}.zip'
URL_ARG = '--url={}'.format(URL)


def check_call(cmd, exec_msg=None, error_msg='Error: command execution failed'):
    try:
        if not exec_msg:
            exec_msg = 'Executing command: {}'.format(cmd)
        print(exec_msg)
        subprocess.check_call(cmd, stdout=open(os.devnull, 'w'), stderr=subprocess.STDOUT)
    except OSError:
        print('Error: command does not seem to be installed')
    except subprocess.CalledProcessError:
        print(error_msg)
        sys.exit(1)


check_call(['curl', '-f', URL],
           'Verifying file by URL exists {}'.format(URL),
           'Error: deployed zip with version {} does not exist'.format(VERSION))

check_call(['brew', 'bump-formula-pr', URL_ARG],
           'Calling brew bump-formula-pr',
           'Error: brew failed')
