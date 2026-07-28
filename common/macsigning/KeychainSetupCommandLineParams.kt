package com.typedb.bazel.distribution.common.macsigning

import picocli.CommandLine
import java.io.File

class KeychainSetupCommandLineParams {
    @CommandLine.Option(names = ["--signing_identities"], required = true)
    lateinit var signingIdentities: File

    @CommandLine.Option(names = ["--keychain_name"], required = true)
    lateinit var keychainName: String

    @CommandLine.Option(names = ["--passwords"], arity = "0..*")
    var passwords: List<String> = emptyList()

    @CommandLine.Option(names = ["--signing_identities_password_env"], required = true)
    lateinit var signingIdentitiesPasswordEnv: String

    @CommandLine.Option(names = ["--partition_list"], required = true)
    lateinit var partitionList: String

    @CommandLine.Option(names = ["--trusted_apps"], required = true, arity = "1..*")
    lateinit var trustedApps: List<String>
}
