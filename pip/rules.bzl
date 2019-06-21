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

def _py_replace_imports_impl(ctx):
    outputs = []
    for file in ctx.files.src:
        relativeFileName = file.short_path
        if not file.short_path.startswith('../'):
            relativeFileName = relativeFileName.replace(ctx.attr.src.label.package + '/', '')
        else:
            _, workspaceName = ctx.attr.src.label.workspace_root.split('/')
            relativeFileName = relativeFileName.replace(workspaceName + '/', '')
        outputFileName = relativeFileName.replace(ctx.attr.src.label.name, ctx.attr.name)
        outputFile = ctx.actions.declare_file(outputFileName)
        outputs.append(outputFile)
        ctx.actions.run_shell(
            inputs  = [file],
    	    outputs = [outputFile],
            tools = [ctx.file._replace_imports_script],
    		command = "python %s %s %s %s %s" % (
                ctx.file._replace_imports_script.path, file.path, outputFile.path,
                ctx.attr.original_package, ctx.attr.output_package)
        )

    return DefaultInfo(files = depset(outputs))


def _deploy_pip_impl(ctx):
  if ctx.file.long_description_file.basename != "README.md":
      fail("long_description_file should be called README.md")

  # Final 'setup.py' is generated in 2 steps
  preprocessed_setup_py = ctx.actions.declare_file("_setup.py")

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
          "{install_requires}": str(ctx.attr.install_requires),
          "{long_description_file}": ctx.file.long_description_file.path
      },
  )

  # Step 2: fill in {pip_version} from version_file
  ctx.actions.run_shell(
      inputs = [preprocessed_setup_py, ctx.file.version_file],
      outputs = [ctx.outputs.setup_py],
      command = "VERSION=`cat %s` && sed -e s/{version}/$VERSION/g %s > %s" % (
          ctx.file.version_file.path, preprocessed_setup_py.path, ctx.outputs.setup_py.path)
  )

  # Generate deployment script
  ctx.actions.expand_template(
      template = ctx.file._deployment_script_template,
      output = ctx.outputs.deployment_script,
      substitutions = {},
      is_executable = True
  )

  all_python_files = []
  for dep in ctx.attr.deps:
    all_python_files.extend(dep.data_runfiles.files.to_list())
    all_python_files.extend(dep.default_runfiles.files.to_list())

  return DefaultInfo(executable = ctx.outputs.deployment_script,
                     runfiles = ctx.runfiles(
                         files = [
                            ctx.file.deployment_properties,
                            ctx.outputs.setup_py,
                            ctx.file.long_description_file
                         ] + all_python_files,
                         symlinks = {
                             "deployment.properties": ctx.file.deployment_properties
                         }).merge(ctx.attr.target.default_runfiles))

py_replace_imports = rule(
	attrs = {
		"src": attr.label(
            mandatory = True,
		),
        "original_package": attr.string(
            default = "",
            doc = "Package in original sources"
        ),
        "output_package": attr.string(
            default = "",
            doc = "Package of output sources"
        ),
        "_replace_imports_script": attr.label(
            allow_single_file = True,
            default = "//pip:replace_imports.py",
        )
	},
	implementation = _py_replace_imports_impl,
    doc = "Replace imports in Python sources"
)

deploy_pip = rule(
  attrs = {
    "target": attr.label(
        mandatory = True,
        doc = "`py_library` label to be included in the package",
    ),
    "version_file": attr.label(
        allow_single_file = True,
        mandatory = True,
        doc = "File containing version string"
    ),
    "deployment_properties": attr.label(
        allow_single_file = True,
        mandatory = True,
        doc = "File containing Python pip repository url by `repo.pypi` key"
    ),
    "package_name": attr.string(
        mandatory = True,
        doc = "A string with Python pip package name"
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
    "install_requires": attr.string_list(
        mandatory = True,
        doc = "A list of strings which are names of required packages for this one"
    ),
    "deps": attr.label_list(
        mandatory = True
    ),
    "_setup_py_template": attr.label(
        allow_single_file = True,
        default = "//pip/templates:setup.py",
    ),
    "_deployment_script_template": attr.label(
        allow_single_file = True,
        default = "//pip/templates:deploy.sh",
    )
  },
  executable = True,
  outputs = {
      "deployment_script": "%{name}.sh",
      "setup_py": "setup.py",
  },
  implementation = _deploy_pip_impl,
  doc = "Deploy package into PyPI repository"
)

