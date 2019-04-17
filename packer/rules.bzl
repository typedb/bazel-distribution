load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

def assemble_packer(name,
                    config,
                    files = {}):
    _files = {
        config: "config.json"
    }
    for k, v in files.items():
        _files[k] = "files/" + v
    pkg_tar(
        name = name,
        extension = "packer.tar",
        files = _files
    )

def _deploy_packer_impl(ctx):
    deployment_script = ctx.actions.declare_file("deploy_packer.py")

    ctx.actions.expand_template(
        template = ctx.file._deployment_script_template,
        output = deployment_script,
        substitutions = {
            "{packer_osx_binary}": ctx.files._packer[0].path,
            "{packer_linux_binary}": ctx.files._packer[1].path,
            "{target_tar}": ctx.file.target.short_path
        },
        is_executable = True
    )

    return DefaultInfo(
        executable = deployment_script,
        runfiles = ctx.runfiles(files = [ctx.file.target] + ctx.files._packer)
    )

deploy_packer = rule(
    attrs = {
        "target": attr.label(
            mandatory = False,
            allow_single_file = [".packer.tar"],
            doc = "Distribution to be deployed.",
        ),
        "_deployment_script_template": attr.label(
            allow_single_file = True,
            default = "@graknlabs_bazel_distribution//packer/templates:deploy_packer.py",
        ),
        "_packer": attr.label_list(
            allow_files = True,
            default = ["@packer_osx//:packer", "@packer_linux//:packer"]
        ),
    },
    executable = True,
    implementation = _deploy_packer_impl
)
