def _deploy_github_impl(ctx):
    _deploy_script = ctx.actions.declare_file("_deploy.py")

    files_to_deploy = []
    files_to_deploy.extend(ctx.files.targets)
    if ctx.file.target:
        files_to_deploy.append(ctx.file.target)

    ctx.actions.expand_template(
        template = ctx.file._deploy_script,
        output = _deploy_script,
        substitutions = {
            "{targets}": ",".join([file.short_path for file in files_to_deploy]),
            "{has_release_description}": str(int(bool(ctx.file.release_description)))
        }
    )
    files = [
        ctx.file.deployment_properties,
        ctx.file.version_file
    ] + ctx.files._ghr + files_to_deploy

    symlinks = {
        "deployment.properties": ctx.file.deployment_properties
    }

    if ctx.file.release_description:
        files.append(ctx.file.release_description)
        symlinks["release_description.txt"] = ctx.file.release_description

    return DefaultInfo(
        executable = _deploy_script,
        runfiles = ctx.runfiles(
            files = files,
            symlinks = symlinks
        ),
    )


deploy_github = rule(
    attrs = {
        "target": attr.label(
            allow_single_file = [".zip"],
            doc = "`distribution_zip` label to be deployed. Deprecated: use 'targets' attribute instead",
        ),
        "targets": attr.label_list(
            allow_files = [".zip", ".tar.gz"],
            doc = "`assemble_zip` or `assemble_targz` label to be deployed",
        ),
        "release_description": attr.label(
            allow_single_file = True,
            doc = "Description of GitHub release"
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
