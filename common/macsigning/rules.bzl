def _mac_pkg_installer_impl(ctx):
    intermediate_pkg_name = ctx.attr.name + "-intermediate.pkg"

    # Generate Distribution.xml by substituting placeholders in the template
    distribution_xml = ctx.actions.declare_file(ctx.attr.name + ".Distribution.xml")
    ctx.actions.expand_template(
        template = ctx.file.distribution_template,
        output = distribution_xml,
        substitutions = {
            "{IDENTIFIER}": ctx.attr.identifier,
            "{PKG_FILENAME}": intermediate_pkg_name,
        },
    )

    config = "identifier: {}\n".format(ctx.attr.identifier)
    config += "installLocation: {}\n".format(ctx.attr.install_location)
    config += "installerCertSubject: {}\n".format(ctx.attr.installer_cert_subject)
    config += "intermediatePkgName: {}\n".format(intermediate_pkg_name)
    config += "notarize: {}\n".format(str(ctx.attr.notarize).lower())
    config += "verbose: {}\n".format(str(ctx.attr.verbose).lower())

    if ctx.attr.sign_binaries:
        config += "signBinaries: {}\n".format(",".join(ctx.attr.sign_binaries))

    if ctx.file.entitlements:
        config += "entitlements: {}\n".format(ctx.file.entitlements.path)

    config_file = ctx.actions.declare_file(ctx.attr.name + "__config.properties")
    ctx.actions.run_shell(
        inputs = [],
        outputs = [config_file],
        command = "printf '%s' '{}' > {}".format(config, config_file.path),
    )

    inputs = [ctx.file.src, ctx.file.cert, distribution_xml, config_file]
    if ctx.file.entitlements:
        inputs.append(ctx.file.entitlements)

    output_pkg = ctx.outputs.pkg

    if "APPLE_CODE_SIGNING_CERT_PASSWORD" not in ctx.var:
        fail("Variable APPLE_CODE_SIGNING_CERT_PASSWORD must be set (pass via --define=APPLE_CODE_SIGNING_CERT_PASSWORD=...)")

    arguments = [
        "--config_path={}".format(config_file.path),
        "--src={}".format(ctx.file.src.path),
        "--cert={}".format(ctx.file.cert.path),
        "--cert_password={}".format(ctx.var["APPLE_CODE_SIGNING_CERT_PASSWORD"]),
        "--distribution_xml={}".format(distribution_xml.path),
        "--output={}".format(output_pkg.path),
    ]

    if ctx.attr.notarize:
        for var in ["APPLE_ID", "APPLE_ID_PASSWORD", "APPLE_TEAM_ID"]:
            if var not in ctx.var:
                fail("Variable {} must be set when notarize=True (pass via --define={}=...)".format(var, var))
        arguments += [
            "--apple_id={}".format(ctx.var["APPLE_ID"]),
            "--apple_id_password={}".format(ctx.var["APPLE_ID_PASSWORD"]),
            "--apple_team_id={}".format(ctx.var["APPLE_TEAM_ID"]),
        ]

    ctx.actions.run(
        inputs = inputs,
        outputs = [output_pkg],
        executable = ctx.executable._macsigning_bin,
        arguments = arguments,
        progress_message = "Building signed macOS installer for {}".format(ctx.attr.name),
    )

    return DefaultInfo(files = depset([output_pkg]))


mac_pkg_installer = rule(
    implementation = _mac_pkg_installer_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "A .tar or .tar.gz archive whose contents form the package root (extracted with --strip-components=1)",
        ),
        "sign_binaries": attr.string_list(
            default = [],
            doc = "Paths relative to the src archive root to codesign before packaging",
        ),
        "entitlements": attr.label(
            allow_single_file = True,
            doc = "Optional entitlements .plist file passed to codesign for each binary in sign_binaries",
        ),
        "identifier": attr.string(
            mandatory = True,
            doc = "Bundle identifier passed to pkgbuild (e.g. 'com.typedb.typedb')",
        ),
        "install_location": attr.string(
            mandatory = True,
            doc = "Installation path passed to pkgbuild (e.g. '/Applications/typedb')",
        ),
        "installer_cert_subject": attr.string(
            mandatory = True,
            doc = "Developer ID Installer identity string for productsign (e.g. 'Developer ID Installer: Acme Ltd (XXXXXXXXXX)')",
        ),
        "cert": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Developer ID Application certificate (.p12) for codesigning the binaries",
        ),
        "distribution_template": attr.label(
            allow_single_file = True,
            default = "@typedb_bazel_distribution//common/macsigning:distribution_template.xml",
            doc = "Distribution.xml template; supports {IDENTIFIER} and {PKG_FILENAME} placeholders",
        ),
        "notarize": attr.bool(
            default = False,
            doc = "If True, submit to Apple notarization and staple the ticket after productsign",
        ),
        "verbose": attr.bool(
            default = False,
            doc = "Enable verbose output",
        ),
        "_macsigning_bin": attr.label(
            default = "@typedb_bazel_distribution//common/macsigning:macsigning-bin",
            executable = True,
            cfg = "exec",
        ),
    },
    outputs = {
        "pkg": "%{name}.pkg",
    },
    doc = "Signs binaries inside a tar archive, packages them into a macOS installer .pkg, and optionally notarizes it.",
)
