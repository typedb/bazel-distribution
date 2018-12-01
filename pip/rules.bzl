def _py_replace_imports_impl(ctx):
    outputs = []
    for file in ctx.files.src:
        relativeFileName = file.short_path.replace(
            ctx.attr.src.label.package + '/', '')
        outputFileName = relativeFileName.replace(ctx.attr.original_name, ctx.attr.output_name)
        outputFile = ctx.actions.declare_file(outputFileName)
        outputs.append(outputFile)
        ctx.actions.run_shell(
            inputs  = [file],
    	    outputs = [outputFile],
            tools = [ctx.file._replacer_script],
    		command = "python %s %s %s %s %s" % (
                ctx.file._replacer_script.path, file.path, outputFile.path,
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
      command = "VERSION=`cat %s` && sed -e s/{pip_version}/$VERSION/g %s > %s" % (
          ctx.file.version_file.path, preprocessed_setup_py.path, ctx.outputs.setup_py.path)
  )

  # Generate deployment script
  ctx.actions.expand_template(
      template = ctx.file._deployment_script_template,
      output = ctx.outputs.deployment_script,
      substitutions = {
          "$PKG_DIR": ctx.attr.target.label.package
      },
      is_executable = True
  )

  return DefaultInfo(executable = ctx.outputs.deployment_script,
                     runfiles = ctx.runfiles(
                         files = [
                            ctx.file.deployment_properties,
                            ctx.outputs.setup_py,
                            ctx.file.long_description_file
                         ],
                         symlinks = {
                             "deployment.properties": ctx.file.deployment_properties
                         }).merge(ctx.attr.target.default_runfiles))

py_replace_imports = rule(
	attrs = {
		"src": attr.label(
            mandatory = True,
		),
        "original_name": attr.string(
            mandatory = True,
        ),
        "output_name": attr.string(
            mandatory = True,
        ),
        "original_package": attr.string(
            default = ""
        ),
        "output_package": attr.string(
            default = ""
        ),
        "_replacer_script": attr.label(
            allow_single_file = True,
            default = "//pip:replacer.py",
        )
	},
	implementation = _py_replace_imports_impl
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
        doc = "File containing Python pip repository url by `pip.repository-url` key"
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
    "_setup_py_template": attr.label(
        allow_single_file = True,
        default = "//pip:setup_template.py",
    ),
    "_deployment_script_template": attr.label(
        allow_single_file = True,
        default = "//pip:deploy.sh",
    )
  },
  executable = True,
  outputs = {
      "deployment_script": "%{name}.sh",
      "setup_py": "setup.py",
  },
  implementation = _deploy_pip_impl
)

