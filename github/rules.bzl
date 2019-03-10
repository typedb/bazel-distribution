def _deploy_github_impl(ctx):
    _deploy_script = ctx.actions.declare_file("_deploy.py")
    ctx.actions.expand_template(
        template = ctx.file._deploy_script,
        output = _deploy_script,
        substitutions = {}
    )
    return DefaultInfo(
        executable = _deploy_script,
        runfiles = ctx.runfiles(files = [
            ctx.file.target, ctx.file.deployment_properties,
            ctx.file.version_file
        ] + ctx.files._ghr)
    )


deploy_github = rule(
    attrs = {
        "target": attr.label(
            allow_single_file = [".zip"],
            mandatory = True,
            doc = "`distribution_zip` label to be deployed",
        ),
        "deployment_properties": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing `repo.github.organisation` and `repo.github.repository` keys"
        ),
        "version_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "File containing version string"
        ),
        "_deploy_script": attr.label(
            allow_single_file = True,
            default = "//github:deploy.py",
        ),
        "_ghr": attr.label_list(
            default = ["@ghr_osx_zip//file:file", "@ghr_linux_tar//file:file"]
        )
    },
    implementation = _deploy_github_impl,
    executable = True
)
