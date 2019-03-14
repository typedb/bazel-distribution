def _deploy_brew_impl(ctx):
    ctx.actions.run_shell(
        inputs = [ctx.file._deployment_script_template, ctx.file.version_file],
        outputs = [ctx.outputs.deployment_script],
        command = "VERSION=`cat %s` && sed -e s/{brew_version}/$VERSION/g %s > %s" % (
            ctx.file.version_file.path, ctx.file._deployment_script_template.path, ctx.outputs.deployment_script.path)
    )

    return DefaultInfo(executable = ctx.outputs.deployment_script)

deploy_brew = rule(
    attrs = {
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing version string"
        ),
        "_deployment_script_template": attr.label(
            allow_single_file = True,
            default = "//brew/templates:deploy.py",
        ),
    },
    executable = True,
    outputs = {
          "deployment_script": "%{name}.sh",
    },
    implementation = _deploy_brew_impl
)


def _deploy_tap_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._deploy_tap_template,
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
                'checksum': ctx.file.checksum,
                'deployment.properties': ctx.file.deployment_properties,
                'formula': ctx.file.formula,
                'VERSION': ctx.file.version_file
            }
        ),
        executable = ctx.outputs.deployment_script
    )


deploy_tap = rule(
    attrs = {
        "_deploy_tap_template": attr.label(
            allow_single_file = True,
            default = "//brew/templates:deploy_tap.py"
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
    implementation = _deploy_tap_impl
)