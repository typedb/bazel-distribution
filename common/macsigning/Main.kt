package com.typedb.bazel.distribution.common.macsigning

import picocli.CommandLine

fun main(args: Array<String>) {
    val params = MacSigningCommandLineParams()
    CommandLine(params).parseArgs(*args)
    MacSigningTool(params).run()
}
