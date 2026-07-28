def _rlocation(ctx, f):
    if f.short_path.startswith("../"):
        return f.short_path[3:]
    return ctx.workspace_name + "/" + f.short_path

def _keychain_setup_impl(ctx):
    passwords_args = " ".join(['--passwords="{}"'.format(p) for p in ctx.attr.passwords])
    trusted_apps_args = " ".join(['--trusted_apps="{}"'.format(a) for a in ctx.attr.trusted_apps])

    script = ctx.actions.declare_file(ctx.attr.name + ".sh")
    ctx.actions.write(
        output = script,
        content = """#!/usr/bin/env bash
set -euo pipefail
RUNFILES="${{RUNFILES_DIR:-${{BASH_SOURCE[0]}}.runfiles}}"
exec "$RUNFILES/{binary}" --signing_identities="$RUNFILES/{p12}" --keychain_name="{keychain_name}" --signing_identities_password_env="{signing_identities_password_env}" --partition_list="{partition_list}" {trusted_apps_args} {passwords_args}
""".format(
            binary = _rlocation(ctx, ctx.executable._keychain_setup_bin),
            p12 = _rlocation(ctx, ctx.file.signing_identities),
            keychain_name = ctx.attr.keychain_name,
            signing_identities_password_env = ctx.attr.signing_identities_password_env,
            partition_list = ctx.attr.partition_list,
            trusted_apps_args = trusted_apps_args,
            passwords_args = passwords_args,
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
        "passwords": attr.string_list(
            default = [],
            doc = "List of 'account_name:ENV_VAR_NAME' pairs; each env var is read at runtime and stored in the keychain under the given account name",
        ),
        "signing_identities_password_env": attr.string(
            default = "APPLE_SIGNING_IDENTITIES_PASSWORD",
            doc = "Name of the env var containing the password for the signing_identities .p12 file",
        ),
        "partition_list": attr.string(
            default = "apple-tool:,apple:,codesign:",
            doc = "Partition list passed to security set-key-partition-list; controls which tools can access the signing keys without prompting",
        ),
        "trusted_apps": attr.string_list(
            mandatory = True,
            doc = "Paths to apps granted access to the signing keys via -T flags on security import",
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
    if not ctx.attr.enable_anywhere and not ctx.attr.enable_current_user_home and not ctx.attr.enable_local_system:
        fail("At least one of 'enable_anywhere', 'enable_current_user_home', or 'enable_local_system' must be True")

    intermediate_pkg_name = ctx.attr.name + "-intermediate.pkg"
    install_location = ctx.attr.install_location if ctx.attr.install_location else "/usr/local/{IDENTIFIER}"

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
            "{ENABLE_ANYWHERE}": str(ctx.attr.enable_anywhere).lower(),
            "{ENABLE_CURRENT_USER_HOME}": str(ctx.attr.enable_current_user_home).lower(),
            "{ENABLE_LOCAL_SYSTEM}": str(ctx.attr.enable_local_system).lower(),
            "{ROOT_VOLUME_ONLY}": str(ctx.attr.enable_local_system and not ctx.attr.enable_current_user_home).lower(),
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

    postinstall_script = None
    if ctx.attr.symlinks:
        postinstall_script = ctx.actions.declare_file(ctx.attr.name + ".postinstall")
        ctx.actions.write(
            output = postinstall_script,
            content = "#!/bin/bash\n" + "\n".join([
                "ln -sf {} {}".format(s.split(":")[1], s.split(":")[0])
                for s in ctx.attr.symlinks
            ]),
            is_executable = True,
        )

    inputs = [ctx.file.src, ctx.file.entitlements, distribution_xml, version_file] + ([postinstall_script] if postinstall_script else [])

    pkg_filename = (ctx.attr.pkg_name if ctx.attr.pkg_name else ctx.attr.name) + ".pkg"
    output_pkg = ctx.actions.declare_file(pkg_filename)

    arguments = (
        ["--src={}".format(ctx.file.src.path)] +
        ["--distribution_xml={}".format(distribution_xml.path),
         "--output={}".format(output_pkg.path),
         "--application_cert_subject={}".format(ctx.attr.application_cert_subject),
         "--identifier={}".format(ctx.attr.identifier),
         "--install_location={}".format(install_location),
         "--version_file={}".format(version_file.path),
         "--installer_cert_subject={}".format(ctx.attr.installer_cert_subject),
         "--intermediate_pkg_name={}".format(intermediate_pkg_name),
         "--entitlements={}".format(ctx.file.entitlements.path),
         "--keychain_name={}".format(ctx.attr.keychain_name)] +
        ["--sign_binaries={}".format(b) for b in ctx.attr.sign_binaries] +
        (["--apple_id={}".format(ctx.attr.apple_id)] if ctx.attr.apple_id else []) +
        (["--apple_team_id={}".format(ctx.attr.apple_team_id)] if ctx.attr.apple_team_id else []) +
        (["--postinstall_script={}".format(postinstall_script.path)] if postinstall_script else []) +
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
        "enable_anywhere": attr.bool(
            default = False,
            doc = "Allow installation at any location in the Distribution.xml domains element",
        ),
        "enable_current_user_home": attr.bool(
            default = False,
            doc = "Allow installation in the current user's home directory in the Distribution.xml domains element",
        ),
        "enable_local_system": attr.bool(
            default = False,
            doc = "Allow installation on the local system volume in the Distribution.xml domains element",
        ),
        "identifier": attr.string(
            mandatory = True,
            doc = "Bundle identifier passed to pkgbuild (e.g. 'com.typedb.typedb')",
        ),
        "install_location": attr.string(
            default = "",
            doc = "Installation path passed to pkgbuild; supports {IDENTIFIER} and {VERSION} placeholders; defaults to '/usr/local/{IDENTIFIER}'",
        ),
        "installer_cert_subject": attr.string(
            mandatory = True,
            doc = "Developer ID Installer identity string for productsign (e.g. 'Developer ID Installer: Acme Ltd (XXXXXXXXXX)')",
        ),
        "keychain_name": attr.string(
            default = "macsigning.keychain",
            doc = "Name of the keychain to use for signing; must match the keychain_name used in the corresponding keychain_setup rule",
        ),
        "application_cert_subject": attr.string(
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
            doc = "If True, submit to Apple notarization and staple the ticket after productsign; requires apple_id and apple_team_id to be set, and the app-specific password to be stored in the keychain via keychain_setup. If notarization fails, set verbose, get submission-id, and `xcrun notarytool log` ",
        ),
        "symlinks": attr.string_list(
            default = [],
            doc = "Symlinks to create post-install, as 'link:target' pairs (e.g. '/usr/local/bin/typedb:/usr/local/typedb/bin/typedb')",
        ),
        "pkg_name": attr.string(
            default = "",
            doc = "Output filename (without .pkg extension); defaults to the rule name",
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
    doc = "Signs binaries inside a tar archive, packages them into a macOS installer .pkg, and optionally notarizes it. Requires the signing keychain to be set up beforehand via the keychain_setup rule.",
)
