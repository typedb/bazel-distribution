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

    @CommandLine.Option(names = ["--installer_cert"], required = true)
    lateinit var installerCert: File

    @CommandLine.Option(names = ["--distribution_xml"], required = true)
    lateinit var distributionXml: File

    @CommandLine.Option(names = ["--output"], required = true)
    lateinit var output: File
}
