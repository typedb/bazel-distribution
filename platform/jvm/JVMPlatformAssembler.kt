package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.Keys.APPLE_CODE_SIGN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.Keys.APPLE_CODE_SIGNING_CERT_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.Keys.APPLE_CODE_SIGNING_CERT_PATH
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.Keys.APPLE_ID
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.Keys.APPLE_ID_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.Keys.CONFIG_PATH
import picocli.CommandLine
import java.io.File
import java.util.concurrent.Callable

@CommandLine.Command
class JVMPlatformAssembler : Callable<Unit> {

    @CommandLine.Option(names = [CONFIG_PATH], required = true)
    lateinit var configPath: String

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

    override fun call() {
        if (appleCodeSign) {
            require(APPLE_ID, appleID)
            require(APPLE_ID_PASSWORD, appleIDPassword)
            require(APPLE_CODE_SIGNING_CERT_PATH, appleCodeSigningCertPath)
            require(APPLE_CODE_SIGNING_CERT_PASSWORD, appleCodeSigningCertPassword)
        }
    }

    private fun <T> require(key: String, value: T) {
        if (value == null || value is String && value.isBlank()) {
            throw IllegalStateException("'$key' must be set if '$APPLE_CODE_SIGNING_CERT_PATH' is set")
        }
    }

    private object Keys {
        const val APPLE_CODE_SIGN = "--apple_code_sign"
        const val APPLE_CODE_SIGNING_CERT_PASSWORD = "--apple_code_signing_cert_password"
        const val APPLE_CODE_SIGNING_CERT_PATH = "--apple_code_signing_cert_path"
        const val APPLE_ID = "--apple_id"
        const val APPLE_ID_PASSWORD = "--apple_id_password"
        const val CONFIG_PATH = "--config_path"
    }
}
