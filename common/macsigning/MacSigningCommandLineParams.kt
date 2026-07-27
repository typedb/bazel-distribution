package com.typedb.bazel.distribution.common.macsigning

import picocli.CommandLine
import java.io.File

class MacSigningCommandLineParams {
    @CommandLine.Option(names = ["--src"], required = true)
    lateinit var src: File

    @CommandLine.Option(names = ["--signing_identities"], required = true)
    lateinit var signingIdentities: File

    @CommandLine.Option(names = ["--distribution_xml"], required = true)
    lateinit var distributionXml: File

    @CommandLine.Option(names = ["--output"], required = true)
    lateinit var output: File

    @CommandLine.Option(names = ["--cert_subject"], required = true)
    lateinit var certSubject: String

    @CommandLine.Option(names = ["--identifier"], required = true)
    lateinit var identifier: String

    @CommandLine.Option(names = ["--install_location"], required = true)
    lateinit var installLocation: String

    @CommandLine.Option(names = ["--installer_cert_subject"], required = true)
    lateinit var installerCertSubject: String

    @CommandLine.Option(names = ["--intermediate_pkg_name"], required = true)
    lateinit var intermediatePkgName: String

    @CommandLine.Option(names = ["--entitlements"], required = true)
    lateinit var entitlements: File

    @CommandLine.Option(names = ["--sign_binaries"], arity = "0..*")
    var signBinaries: List<String> = emptyList()

    @CommandLine.Option(names = ["--notarize"])
    var notarize: Boolean = false

    @CommandLine.Option(names = ["--verbose"])
    var verbose: Boolean = false
}
