def _deploy_brew_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._deploy_brew_template,
        output = ctx.outputs.deployment_script,
        substitutions = {},
        is_executable = True
    )
    return DefaultInfo(
        runfiles = ctx.runfiles(
            files = [
                ctx.file.checksum,
                ctx.file.deployment_properties,
                ctx.file.formula,
                ctx.file.version_file
            ],
            symlinks = {
                'checksum.sha256': ctx.file.checksum,
                'deployment.properties': ctx.file.deployment_properties,
                'formula': ctx.file.formula,
                'VERSION': ctx.file.version_file
            }
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
            mandatory = True,
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