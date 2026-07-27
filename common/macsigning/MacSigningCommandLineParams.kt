package com.typedb.bazel.distribution.common.macsigning

import picocli.CommandLine
import java.io.File

class MacSigningCommandLineParams {

    @CommandLine.Option(names = ["--config_path"], required = true)
    lateinit var configFile: File

    @CommandLine.Option(names = ["--src"], required = true)
    lateinit var src: File

    @CommandLine.Option(names = ["--cert"], required = true)
    lateinit var cert: File

    @CommandLine.Option(names = ["--cert_password"], required = true)
    lateinit var certPassword: String

    @CommandLine.Option(names = ["--distribution_xml"], required = true)
    lateinit var distributionXml: File

    @CommandLine.Option(names = ["--output"], required = true)
    lateinit var output: File

    @CommandLine.Option(names = ["--apple_id"])
    var appleID: String? = null

    @CommandLine.Option(names = ["--apple_id_password"])
    var appleIDPassword: String? = null

    @CommandLine.Option(names = ["--apple_team_id"])
    var appleTeamID: String? = null

    object Keys {
        const val APPLE_CODE_SIGNING_CERT_PASSWORD = "--cert_password"
        const val APPLE_ID = "--apple_id"
        const val APPLE_ID_PASSWORD = "--apple_id_password"
        const val APPLE_TEAM_ID = "--apple_team_id"
        const val CONFIG_PATH = "--config_path"
        const val CERT = "--cert"
        const val DISTRIBUTION_XML = "--distribution_xml"
        const val OUTPUT = "--output"
        const val SRC = "--src"
    }
}
