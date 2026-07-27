def _rlocation(ctx, f):
    if f.short_path.startswith("../"):
        return f.short_path[3:]
    return ctx.workspace_name + "/" + f.short_path

def _keychain_setup_impl(ctx):
    optional_args = ""
    if ctx.attr.apple_id:
        optional_args += ' --apple_id="{}"'.format(ctx.attr.apple_id)
    if ctx.attr.apple_team_id:
        optional_args += ' --apple_team_id="{}"'.format(ctx.attr.apple_team_id)

    script = ctx.actions.declare_file(ctx.attr.name + ".sh")
    ctx.actions.write(
        output = script,
        content = """#!/usr/bin/env bash
set -euo pipefail
RUNFILES="${{RUNFILES_DIR:-${{BASH_SOURCE[0]}}.runfiles}}"
exec "$RUNFILES/{binary}" --signing_identities="$RUNFILES/{p12}" --keychain_name="{keychain_name}"{optional_args}
""".format(
            binary = _rlocation(ctx, ctx.executable._keychain_setup_bin),
            p12 = _rlocation(ctx, ctx.file.signing_identities),
            keychain_name = ctx.attr.keychain_name,
            optional_args = optional_args,
        ),
        is_executable = True,
    )
    runfiles = ctx.runfiles(files = [ctx.file.signing_identities]).merge(
        ctx.attr._keychain_setup_bin[DefaultInfo].default_runfiles,
    )
    return DefaultInfo(executable = script, runfiles = runfiles)

keychain_setup = rule(
    implementation = _keychain_setup_impl,
    executable = True,
    attrs = {
        "signing_identities": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "PKCS12 (.p12) file containing the signing identities; password read from APPLE_SIGNING_IDENTITIES_PASSWORD env var at runtime",
        ),
        "keychain_name": attr.string(
            default = "macsigning.keychain",
            doc = "Name of the keychain to create; must match the keychain_name used in the corresponding mac_pkg_installer rule",
        ),
        "apple_id": attr.string(
            default = "",
            doc = "Apple ID for notarization (e.g. 'user@example.com'); if set with apple_team_id, notarization credentials are stored in the keychain; password read from APPLE_ID_PASSWORD env var",
        ),
        "apple_team_id": attr.string(
            default = "",
            doc = "Apple Team ID for notarization (e.g. 'XXXXXXXXXX')",
        ),
        "_keychain_setup_bin": attr.label(
            default = "@typedb_bazel_distribution//common/macsigning:keychain-setup",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Runnable target that creates and unlocks the macsigning keychain. Run this before bazel build targets that use mac_pkg_installer.",
)

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

    inputs = [ctx.file.src, ctx.file.entitlements, distribution_xml, version_file]

    output_pkg = ctx.outputs.pkg

    arguments = (
        ["--src={}".format(ctx.file.src.path)] +
        ["--distribution_xml={}".format(distribution_xml.path),
         "--output={}".format(output_pkg.path),
         "--cert_subject={}".format(ctx.attr.cert_subject),
         "--identifier={}".format(ctx.attr.identifier),
         "--install_location={}".format(ctx.attr.install_location),
         "--installer_cert_subject={}".format(ctx.attr.installer_cert_subject),
         "--intermediate_pkg_name={}".format(intermediate_pkg_name),
         "--entitlements={}".format(ctx.file.entitlements.path),
         "--keychain_name={}".format(ctx.attr.keychain_name)] +
        ["--sign_binaries={}".format(b) for b in ctx.attr.sign_binaries] +
        (["--apple_id={}".format(ctx.attr.apple_id)] if ctx.attr.apple_id else []) +
        (["--apple_team_id={}".format(ctx.attr.apple_team_id)] if ctx.attr.apple_team_id else []) +
        (["--notarize"] if ctx.attr.notarize else []) +
        (["--verbose"] if ctx.attr.verbose else [])
    )

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
            default = "/usr/local",
            doc = "Installation path passed to pkgbuild (e.g. '/Applications/typedb'); defaults to '/usr/local'",
        ),
        "installer_cert_subject": attr.string(
            mandatory = True,
            doc = "Developer ID Installer identity string for productsign (e.g. 'Developer ID Installer: Acme Ltd (XXXXXXXXXX)')",
        ),
        "keychain_name": attr.string(
            default = "macsigning.keychain",
            doc = "Name of the keychain to use for signing; must match the keychain_name used in the corresponding keychain_setup rule",
        ),
        "cert_subject": attr.string(
            mandatory = True,
            doc = "Developer ID Application identity string for codesign (e.g. 'Developer ID Application: Acme Ltd (XXXXXXXXXX)')",
        ),
        "distribution_template": attr.label(
            allow_single_file = True,
            default = "@typedb_bazel_distribution//common/macsigning:distribution_template.xml",
            doc = "Distribution.xml template; supports {IDENTIFIER}, {PKG_FILENAME}, {HOST_ARCHITECTURE}, and {VERSION} placeholders",
        ),
        "apple_id": attr.string(
            default = "",
            doc = "Apple ID (email) for notarization; required when notarize = True",
        ),
        "apple_team_id": attr.string(
            default = "",
            doc = "Apple Team ID for notarization; required when notarize = True",
        ),
        "notarize": attr.bool(
            default = False,
            doc = "If True, submit to Apple notarization and staple the ticket after productsign; requires apple_id and apple_team_id to be set, and APPLE_ID_PASSWORD to be stored in the keychain via keychain_setup",
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
    doc = """Signs binaries inside a tar archive, packages them into a macOS installer .pkg, and optionally notarizes it.

Requires the following env vars to be forwarded to the build action via --action_env (e.g. in .bazelrc):
  APPLE_SIGNING_IDENTITIES_PASSWORD  -- password for the signing_identities .p12 file
  APPLE_ID                           -- Apple ID for notarization (only if notarize = True)
  APPLE_ID_PASSWORD                  -- app-specific password for notarization (only if notarize = True)
  APPLE_TEAM_ID                      -- Apple team ID for notarization (only if notarize = True)
""",
)
