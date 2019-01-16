def _deploy_deb_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._deployment_script,
        output = ctx.outputs.deployment_script,
        substitutions = {},
        is_executable = True
    )

    symlinks = {
        'package.deb': ctx.files.target[0],
        'deployment.properties': ctx.file.deployment_properties
    }

    return DefaultInfo(executable = ctx.outputs.deployment_script,
                       runfiles = ctx.runfiles(
                           files=[ctx.files.target[0], ctx.file.deployment_properties],
                           symlinks = symlinks))


deploy_deb = rule(
    attrs = {
        "target": attr.label(),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "//deb/templates:deploy.sh"
        )
    },
    outputs = {
        "deployment_script": "%{name}.sh",
    },
    implementation = _deploy_deb_impl,
    executable = True,
)