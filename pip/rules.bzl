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

load("@vaticle_bazel_distribution_pip//:requirements.bzl", vaticle_bazel_distribution_requirement = "requirement")


def _python_repackage_impl(ctx):
    outputs = []
    actions = []
    for file in ctx.files.src:
        path = file.short_path

        if path.startswith('../'):
            # when built from a foreign workspace,
            # filename starts with ../<workspace_name>/
            path = path.replace(
                '../{}/'.format(ctx.attr.src.label.workspace_name),
                ''
            )

        # trim bazel package and target name
        path = path.replace(
            '{}/{}/'.format(ctx.attr.src.label.package, ctx.attr.src.label.name),
            ''
        )

        # prepend Python package prefix
        path = '{}/{}'.format(ctx.attr.py_package_add_prefix, path)

        actions.append({
            'file': file,
            'output_path': path,
        })

    for action in actions:
        args = ctx.actions.args()
        outputFile = ctx.actions.declare_file(action['output_path'])

        args.add('--src', action['file'].path)
        args.add('--dest', outputFile.path)
        args.add('--pkgs', ",".join(ctx.attr.src_packages))
        args.add('--prefix', ctx.attr.py_package_add_prefix)

        ctx.actions.run(
            inputs = [action['file']],
            outputs = [outputFile],
            arguments = [args],
            executable = ctx.executable._repackage_script
        )
        outputs.append(outputFile)

    return DefaultInfo(files = depset(outputs))


PyDeploymentInfo = provider(
    fields = {
        'package': 'package to deploy',
        'wheel': 'wheel file to deploy',
        'version_file': 'file with package version'
    }
)


def _assemble_pip_impl(ctx):
    args = ctx.actions.args()

    python_source_files = []

    imports = []
    for file in ctx.attr.target[PyInfo].imports.to_list():
        if 'pypi' not in file:
            imports.append(file)

    for file in ctx.attr.target[PyInfo].transitive_sources.to_list():
        if 'pypi' not in file.path and 'external' not in file.path:
            python_source_files.append(file)

    data_files = []
    for file in ctx.attr.target[DefaultInfo].data_runfiles.files.to_list():
        if 'pypi' not in file.path and 'external' not in file.path and file.extension != "py":
            data_files.append(file)

    if ctx.attr.python_requires.startswith(">2.") or ctx.attr.python_requires.startswith("=2."):
        fail("This rule only supports Python 3.x, was given 'python_requires = " + ctx.attr.python_requires + "'.")

    args.add_all('--files', python_source_files)
    args.add_all('--data_files', data_files)
    args.add('--output_sdist', ctx.outputs.pip_package.path)
    args.add('--output_wheel', ctx.outputs.pip_wheel.path)
    args.add('--package_root', ctx.build_file_path.rsplit('/', 1)[0])
    args.add('--readme', ctx.file.long_description_file.path)
    args.add('--suffix', ctx.attr.suffix)

    # Final 'setup.py' is generated in 2 steps
    setup_py = ctx.actions.declare_file("setup" + ctx.attr.suffix + ".py")
    preprocessed_setup_py = ctx.actions.declare_file("_setup" + ctx.attr.suffix + ".py")

    # Step 1: fill in everything except version
    ctx.actions.expand_template(
      template = ctx.file._setup_py_template,
      output = preprocessed_setup_py,
      substitutions = {
          "{name}": ctx.attr.package_name,
          "{description}": ctx.attr.description,
          "{classifiers}": str(ctx.attr.classifiers),
          "{keywords}": " ".join(ctx.attr.keywords),
          "{url}": ctx.attr.url,
          "{author}": ctx.attr.author,
          "{author_email}": ctx.attr.author_email,
          "{license}": ctx.attr.license,
          "{long_description_file}": ctx.file.long_description_file.path,
          "{python_requires}": ctx.attr.python_requires,
          "{suffix}": ctx.attr.suffix,
      },
    )

    if not ctx.attr.version_file:
        version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
        version = ctx.var.get('version', '0.0.0')

        if len(version) == 40:
            # this is a commit SHA, most likely
            version = "0.0.0+{}".format(version)
        elif '-rc' in version:
            version = version.replace('-rc', 'rc')

        ctx.actions.run_shell(
            inputs = [],
            outputs = [version_file],
            command = "echo {} > {}".format(version, version_file.path)
        )
    else:
        version_file = ctx.file.version_file

    # Step 2: fill in {pip_version} from version_file
    ctx.actions.run_shell(
      inputs = [preprocessed_setup_py, version_file],
      outputs = [setup_py],
      command = "VERSION=`cat %s` && sed -e s/{version}/$VERSION/g %s > %s" % (
          version_file.path, preprocessed_setup_py.path, setup_py.path)
    )

    args.add("--requirements_file", ctx.file.requirements_file.path)
    args.add("--setup_py_template", setup_py.path)
    args.add_all("--imports", imports)

    ctx.actions.run(
        inputs = [version_file, setup_py, ctx.file.long_description_file, ctx.file.requirements_file] + python_source_files + data_files,
        outputs = [ctx.outputs.pip_package, ctx.outputs.pip_wheel],
        arguments = [args],
        executable = ctx.executable._assemble_script,
    )

    return [PyDeploymentInfo(package=ctx.outputs.pip_package, wheel=ctx.outputs.pip_wheel, version_file=version_file)]


def _deploy_pip_impl(ctx):
    deployment_script = ctx.actions.declare_file(ctx.attr.deploy_script_name)

    ctx.actions.expand_template(
        template = ctx.file._deploy_script_template,
        output = deployment_script,
        substitutions = {
            "{source_package}": ctx.attr.target[PyDeploymentInfo].package.short_path,
            "{wheel_package}": ctx.attr.target[PyDeploymentInfo].wheel.short_path,
            "{version_file}": ctx.attr.target[PyDeploymentInfo].version_file.short_path,
            "{pypirc_repository}": ctx.attr.pypirc_repository,
            "{snapshot}": ctx.attr.snapshot,
            "{release}": ctx.attr.release,
            "{distribution_tag}": ctx.attr.distribution_tag,
            "{suffix}": ctx.attr.suffix,
        }
    )

    all_python_files = []
    for dep in ctx.attr._deps:
        all_python_files.extend(dep.data_runfiles.files.to_list())
        all_python_files.extend(dep.default_runfiles.files.to_list())

    return DefaultInfo(
        executable = deployment_script,
        runfiles = ctx.runfiles(
                files=[ctx.attr.target[PyDeploymentInfo].package, ctx.attr.target[PyDeploymentInfo].wheel, ctx.attr.target[PyDeploymentInfo].version_file] + all_python_files
            )
        )


python_repackage = rule(
    attrs = {
        "src": attr.label(
            mandatory = True,
            doc = "Python source files"
        ),
        "src_packages": attr.string_list(
            mandatory = True,
            doc = "Package name whose import paths should be prefixed"
        ),
        "py_package_add_prefix": attr.string(
            mandatory = True,
            doc = "The prefix to add"
        ),
        "_repackage_script": attr.label(
            default = "//pip:repackage",
            executable = True,
            cfg = "host"
        )

    },
    implementation = _python_repackage_impl,
)


assemble_pip = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            doc = "`py_library` label to be included in the package",
        ),
        "version_file": attr.label(
            allow_single_file = True,
            doc = """
            File containing version string.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """
        ),
        "package_name": attr.string(
            mandatory = True,
            doc = "A string with Python pip package name"
        ),
        "suffix": attr.string(
            default = "",
            doc = "A suffix that has to be removed from the filenames",
        ),
        "description": attr.string(
            mandatory = True,
            doc="A string with the short description of the package",
        ),
        "long_description_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "A label with the long description of the package. Usually a README or README.rst file"
        ),
        "classifiers": attr.string_list(
            mandatory = True,
            doc = "A list of strings, containing Python package classifiers"
        ),
        "keywords": attr.string_list(
            mandatory = True,
            doc = "A list of strings, containing keywords"
        ),
        "url": attr.string(
            mandatory = True,
            doc = "A homepage for the project"
        ),
        "author": attr.string(
            mandatory = True,
            doc = "Details about the author"
        ),
        "author_email": attr.string(
            mandatory = True,
            doc = "The email for the author"
        ),
        "license": attr.string(
            mandatory = True,
            doc = "The type of license to use"
        ),
        "requirements_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "A file with the list of required packages for this one",
        ),
        "python_requires": attr.string(
            default = ">0",
            doc = "If your project only runs on certain Python versions, setting the python_requires argument to the appropriate PEP 440 version specifier string will prevent pip from installing the project on other Python versions.",
        ),
        "_setup_py_template": attr.label(
            allow_single_file = True,
            default = "//pip/templates:setup.py",
        ),
        "_assemble_script": attr.label(
            default = "//pip:assemble",
            executable = True,
            cfg = "host"
        ),
    },
    implementation = _assemble_pip_impl,
    outputs = {
        "pip_package": "%{package_name}%{suffix}.tar.gz",
        "pip_wheel": "%{package_name}%{suffix}.whl"
    },
)


_deploy_pip = rule(
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [PyDeploymentInfo],
            doc = "`assemble_pip` label to be included in the package",
        ),
        "snapshot": attr.string(
            default = "",
            doc = "Snapshot repository URL to deploy pip artifact to"
        ),
        "release": attr.string(
            default = "",
            doc = "Release repository URL to deploy pip artifact to"
        ),
        "pypirc_repository": attr.string(
            default = "",
            doc = "Repository name in the .pypirc profile to deploy to"
        ),
        "distribution_tag": attr.string(
            mandatory = True,
            doc = "Specify tag for the package name. Format: {python tag}-{abi tag}-{platform tag} (PEP 425)",
        ),
        "suffix": attr.string(
            mandatory = True,
            doc = "Python version suffix to be used in the package name",
        ),
        "_deploy_script_template": attr.label(
            allow_single_file = True,
            default = "//pip/templates:deploy.py",
        ),
        "deploy_script_name": attr.string(
            mandatory = True,
            doc = 'Name of instantiated deployment script'
        ),
        "_deps": attr.label_list(
            default = [
                vaticle_bazel_distribution_requirement("twine"),
                vaticle_bazel_distribution_requirement("setuptools"),
                vaticle_bazel_distribution_requirement("wheel"),
                vaticle_bazel_distribution_requirement("requests"),
                vaticle_bazel_distribution_requirement("urllib3"),
                vaticle_bazel_distribution_requirement("chardet"),
                vaticle_bazel_distribution_requirement("certifi"),
                vaticle_bazel_distribution_requirement("idna"),
                vaticle_bazel_distribution_requirement("tqdm"),
                vaticle_bazel_distribution_requirement("requests_toolbelt"),
                vaticle_bazel_distribution_requirement("pkginfo"),
                vaticle_bazel_distribution_requirement("readme_renderer"),
                vaticle_bazel_distribution_requirement("Pygments"),
                vaticle_bazel_distribution_requirement("docutils"),
                vaticle_bazel_distribution_requirement("bleach"),
                vaticle_bazel_distribution_requirement("webencodings"),
                vaticle_bazel_distribution_requirement("packaging")
            ]
        )
    },
    executable = True,
    implementation = _deploy_pip_impl,
    doc = """
        Deploy python target to one of multiple provided repositories.

        This rule can be provided with either a `pypirc` repository name to deploy to,
        or an explicit 'snapshot' or 'release' repository URL to deploy to.

        The `pypirc` must be in the expected location for twine deployment. Typically it is in `$HOME/.pypirc`.

        To deploy to one of these repositories, select it using an argument:
        ```bazel run //:some-deploy-pip -- [pypirc|snapshot|release]```
        """
)


def deploy_pip(name, target, snapshot = "", release = "", pypirc_repository = "", suffix = "", distribution_tag = "py3-none-any"):
    if (snapshot and release and pypirc_repository):
        fail("Only one 'snapshot and release' or 'pypirc_repository' may be set")
    if (not snapshot and not release and not pypirc_repository):
        fail("At least one 'snapshot and release' or 'pypirc_repository' must be set")
    if (snapshot and not release):
        fail("'release' repository param must be set if 'snapshot' repository is configured")
    if (not snapshot and release):
        fail("'snapshot' repository param must be set if 'release' repository is configured")

    deploy_script_target_name = name + "__deploy"
    deploy_script_name = deploy_script_target_name + "-deploy.py"
    _deploy_pip(
        name = deploy_script_target_name,
        deploy_script_name = deploy_script_name,
        target = target,
        snapshot = snapshot,
        release = release,
        pypirc_repository = pypirc_repository,
        suffix = suffix,
        distribution_tag = distribution_tag,
    )

    native.py_binary(
        name = name,
        srcs = [deploy_script_target_name],
        main = deploy_script_name,
    )
