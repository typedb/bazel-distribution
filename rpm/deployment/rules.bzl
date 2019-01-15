RpmInfo = provider(
    fields = {
        "package_name": "RPM package name"
    }
)

def _deploy_rpm_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._deployment_script,
        output = ctx.outputs.deployment_script,
        substitutions = {
            "{RPM_PKG}": ctx.attr.target[RpmInfo].package_name
        },
        is_executable = True
    )

    symlinks = {
        'package.rpm': ctx.files.target[0],
        'deployment.properties': ctx.file.deployment_properties
    }

    return DefaultInfo(executable = ctx.outputs.deployment_script,
                       runfiles = ctx.runfiles(
                           files=[ctx.files.target[0], ctx.file.deployment_properties],
                           symlinks = symlinks))

def _collect_attr(target, ctx):
    spec_filename = ctx.rule.attr.spec_file.label.name
    package_name = spec_filename.replace('.spec', '')
    return RpmInfo(package_name=package_name)


collect_attr = aspect(
    implementation = _collect_attr
)


deploy_rpm = rule(
    attrs = {
        "target": attr.label(
            aspects = [collect_attr]
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True
        ),
        "_deployment_script": attr.label(
            allow_single_file = True,
            default = "//rpm/templates:deploy.sh"
        )
    },
    outputs = {
        "deployment_script": "%{name}.sh",
    },
    implementation = _deploy_rpm_impl,
    executable = True,
)