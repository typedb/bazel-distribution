package com.vaticle.bazel.distribution.platform.jvm

import java.util.Properties

private fun appleCodeSigningCredentialsOf(props: Properties): Config.AppleCodeSigning? {
    fun require(key: String): String {
        val value = props.getProperty(key)
        if (value.isNullOrBlank()) throw IllegalStateException("'$key' must be set if '$APPLE_CODE_SIGNING_CERTIFICATE_PATH' is set")
        return value
    }

    return when (APPLE_CODE_SIGNING_CERTIFICATE_PATH) {
        in props -> Config.AppleCodeSigning(
            appleID = require(APPLE_ID),
            appleIDPassword = require(APPLE_ID_PASSWORD),
            certificatePath = require(APPLE_CODE_SIGNING_CERTIFICATE_PATH),
            certificatePassword = require(APPLE_CODE_SIGNING_CERTIFICATE_PASSWORD)
        )
        else -> null
    }
}

data class Credentials(val appleCodeSigning: AppleCodeSigning) {
    data class AppleCodeSigning(
        val appleID: String, val appleIDPassword: String, val certificatePath: String, val certificatePassword: String
    )

    object Keys {
        const val APPLE_CODE_SIGNING_CERTIFICATE_PASSWORD = "appleCodeSigningCertificatePassword"
        const val APPLE_CODE_SIGNING_CERTIFICATE_PATH = "appleCodeSigningCertificatePath"
        const val APPLE_ID = "appleId"
        const val APPLE_ID_PASSWORD = "appleIdPassword"
    }
}
