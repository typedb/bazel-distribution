package com.typedb.bazel.distribution.common.macsigning

import picocli.CommandLine

fun main(args: Array<String>) {
    val params = KeychainSetupCommandLineParams()
    CommandLine(params).parseArgs(*args)
    KeychainSetupTool(params.signingIdentities, params.keychainName, params.passwords).run()
}
