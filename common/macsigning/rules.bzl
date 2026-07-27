def _mac_pkg_installer_impl(ctx):
    intermediate_pkg_name = ctx.attr.name + "-intermediate.pkg"

    # Resolve version: ctx.var overrides version_file
    if "version" in ctx.var:
        version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
        version = ctx.var["version"]
        if len(version) == 40:
            version = "0.0.0-{}".format(version)
        ctx.actions.run_shell(
            inputs = [],
            outputs = [version_file],
            command = "printf '%s' '{}' > {}".format(version, version_file.path),
        )
    elif ctx.attr.version_file:
        version_file = ctx.file.version_file
    else:
        fail("Either 'version_file' must be set or the 'version' Bazel variable must be defined (--define=version=...)")

    # Generate Distribution.xml: expand_template for the static placeholders, then
    # a shell action to substitute {VERSION} from the version file.
    partial_distribution_xml = ctx.actions.declare_file(ctx.attr.name + ".Distribution.partial.xml")
    ctx.actions.expand_template(
        template = ctx.file.distribution_template,
        output = partial_distribution_xml,
        substitutions = {
            "{IDENTIFIER}": ctx.attr.identifier,
            "{PKG_FILENAME}": intermediate_pkg_name,
            "{HOST_ARCHITECTURE}": ctx.attr.host_architecture,
        },
    )

    distribution_xml = ctx.actions.declare_file(ctx.attr.name + ".Distribution.xml")
    ctx.actions.run_shell(
        inputs = [partial_distribution_xml, version_file],
        outputs = [distribution_xml],
        command = "sed \"s/{{VERSION}}/$(cat {} | tr -d '[:space:]')/g\" {} > {}".format(
            version_file.path, partial_distribution_xml.path, distribution_xml.path,
        ),
    )

    config = "certSubject: {}\n".format(ctx.attr.cert_subject)
    config += "identifier: {}\n".format(ctx.attr.identifier)
    config += "installLocation: {}\n".format(ctx.attr.install_location)
    config += "installerCertSubject: {}\n".format(ctx.attr.installer_cert_subject)
    config += "intermediatePkgName: {}\n".format(intermediate_pkg_name)
    config += "notarize: {}\n".format(str(ctx.attr.notarize).lower())
    config += "verbose: {}\n".format(str(ctx.attr.verbose).lower())

    if ctx.attr.sign_binaries:
        config += "signBinaries: {}\n".format(",".join(ctx.attr.sign_binaries))

    config += "entitlements: {}\n".format(ctx.file.entitlements.path)

    config_file = ctx.actions.declare_file(ctx.attr.name + "__config.properties")
    ctx.actions.run_shell(
        inputs = [],
        outputs = [config_file],
        command = "printf '%s' '{}' > {}".format(config, config_file.path),
    )

    inputs = [ctx.file.src, ctx.file.cert, ctx.file.installer_cert, ctx.file.entitlements, distribution_xml, config_file, version_file]

    output_pkg = ctx.outputs.pkg

    arguments = [
        "--config_path={}".format(config_file.path),
        "--src={}".format(ctx.file.src.path),
        "--cert={}".format(ctx.file.cert.path),
        "--installer_cert={}".format(ctx.file.installer_cert.path),
        "--distribution_xml={}".format(distribution_xml.path),
        "--output={}".format(output_pkg.path),
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
        "version_file": attr.label(
            allow_single_file = True,
            doc = "File containing the version string. Overridden by the 'version' Bazel variable (--define=version=...) if set",
        ),
        "sign_binaries": attr.string_list(
            default = [],
            doc = "Paths relative to the src archive root to codesign before packaging",
        ),
        "entitlements": attr.label(
            allow_single_file = True,
            default = "@typedb_bazel_distribution//common/macsigning:default_entitlements.plist",
            doc = "Entitlements .plist passed to codesign for each binary in sign_binaries; defaults to a minimal hardened-runtime plist with no exceptions",
        ),
        "host_architecture": attr.string(
            mandatory = True,
            doc = "Target CPU architecture for the installer (e.g. 'arm64' or 'x86_64'); written into the Distribution.xml hostArchitectures field",
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
        "cert_subject": attr.string(
            mandatory = True,
            doc = "Developer ID Application identity string for codesign (e.g. 'Developer ID Application: Acme Ltd (XXXXXXXXXX)'); must match the CN in cert",
        ),
        "installer_cert": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Developer ID Installer certificate (.p12) for productsign; password read from APPLE_INSTALLER_CERT_PASSWORD env var",
        ),
        "distribution_template": attr.label(
            allow_single_file = True,
            default = "@typedb_bazel_distribution//common/macsigning:distribution_template.xml",
            doc = "Distribution.xml template; supports {IDENTIFIER}, {PKG_FILENAME}, {HOST_ARCHITECTURE}, and {VERSION} placeholders",
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
