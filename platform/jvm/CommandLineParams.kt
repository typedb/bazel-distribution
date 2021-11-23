package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_CODE_SIGN
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_CODE_SIGNING_CERT_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_CODE_SIGNING_CERT_PATH
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.CONFIG_PATH
import picocli.CommandLine
import java.io.File

class CommandLineParams {

    @CommandLine.Option(names = [CONFIG_PATH], required = true)
    lateinit var configPath: File

    @CommandLine.Option(names = [APPLE_CODE_SIGN])
    var appleCodeSign: Boolean = false

    @CommandLine.Option(names = [APPLE_ID])
    lateinit var appleID: String

    @CommandLine.Option(names = [APPLE_ID_PASSWORD])
    lateinit var appleIDPassword: String

    @CommandLine.Option(names = [APPLE_CODE_SIGNING_CERT_PATH])
    lateinit var appleCodeSigningCertPath: File

    @CommandLine.Option(names = [APPLE_CODE_SIGNING_CERT_PASSWORD])
    lateinit var appleCodeSigningCertPassword: String

    object Keys {
        const val APPLE_CODE_SIGN = "--apple_code_sign"
        const val APPLE_CODE_SIGNING_CERT_PASSWORD = "--apple_code_signing_cert_password"
        const val APPLE_CODE_SIGNING_CERT_PATH = "--apple_code_signing_cert_path"
        const val APPLE_ID = "--apple_id"
        const val APPLE_ID_PASSWORD = "--apple_id_password"
        const val CONFIG_PATH = "--config_path"
    }
}
