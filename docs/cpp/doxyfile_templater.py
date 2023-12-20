import re
from sys import argv

with open(argv[1], 'r') as f: contents = f.read()
with open(argv[2], 'r') as f:
    for replacement in f:
        replace = replacement.split("=", 2)
        regex_str = '^' + replace[0].strip() + '\\s*=.*$'
        compiled = re.compile(regex_str, re.MULTILINE)
        contents = compiled.sub(replacement, contents)

with open(argv[3], 'w') as f: f.write(contents)
