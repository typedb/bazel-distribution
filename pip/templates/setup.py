from setuptools import setup
from setuptools import find_packages
from os import walk
from os.path import join


def create_init_files(directory):
    for dirName, subdirList, fileList in walk(directory):
        if "__init__.py" not in fileList:
            open(join(dirName, "__init__.py"), "w").close()

packages = find_packages()
for package in packages:
    create_init_files(package)
packages = find_packages()

setup(
    name = "{name}",
    version = "{version}-snapshot",
    description = "{description}",
    long_description = open('README.md').read(),
    long_description_content_type="text/markdown",
    classifiers = {classifiers},
    keywords = "{keywords}",
    url = "{url}",
    author = "{author}",
    author_email = "{author_email}",
    license = "{license}",
    packages=packages,
    install_requires={install_requires},
    zip_safe=False,
)
