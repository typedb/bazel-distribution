package com.typedb.bazel.distribution.common.macsigning

import picocli.CommandLine
import java.io.File

class KeychainSetupCommandLineParams {
    @CommandLine.Option(names = ["--signing_identities"], required = true)
    lateinit var signingIdentities: File

    @CommandLine.Option(names = ["--keychain_name"], required = true)
    lateinit var keychainName: String

    @CommandLine.Option(names = ["--apple_id"])
    var appleId: String? = null

    @CommandLine.Option(names = ["--apple_team_id"])
    var appleTeamId: String? = null
}
