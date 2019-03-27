def _deploy_brew_impl(ctx):
    if ctx.attr.type == "brew":
        brew_formula_folder = "Formula"
    elif ctx.attr.type == "cask":
        brew_formula_folder = "Casks"

    ctx.actions.expand_template(
        template = ctx.file._deploy_brew_template,
        output = ctx.outputs.deployment_script,
        substitutions = {
            "{brew_folder}": brew_formula_folder
        },
        is_executable = True
    )
    files = [
        ctx.file.deployment_properties,
        ctx.file.formula,
        ctx.file.version_file
    ]

    symlinks = {
        'deployment.properties': ctx.file.deployment_properties,
        'formula': ctx.file.formula,
        'VERSION': ctx.file.version_file
    }

    if ctx.file.checksum:
        files.append(ctx.file.checksum)
        symlinks['checksum.sha256'] = ctx.file.checksum

    return DefaultInfo(
        runfiles = ctx.runfiles(
            files = files,
            symlinks = symlinks
        ),
        executable = ctx.outputs.deployment_script
    )


deploy_brew = rule(
    attrs = {
        "_deploy_brew_template": attr.label(
            allow_single_file = True,
            default = "//brew/templates:deploy.py"
        ),
        "checksum": attr.label(
            allow_single_file = True,
        ),
        "type": attr.string(
            values = ["brew", "cask"],
            default = "brew"
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "formula": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The brew formula definition"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True
        )
    },
    executable = True,
    outputs = {
        "deployment_script": "%{name}.py"
    },
    implementation = _deploy_brew_impl
)