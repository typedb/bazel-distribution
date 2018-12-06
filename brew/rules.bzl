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