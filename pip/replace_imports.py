#!/usr/bin/env python

import sys
_, input_fn, output_fn, original_package, output_package = sys.argv

with open(input_fn) as input_file:
    txt = input_file.read()
with open(output_fn, 'w') as output_file:
    original_package = 'from ' + original_package
    output_package = 'from ' + output_package
    output_file.write(txt.replace(original_package, output_package))
