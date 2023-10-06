package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.common.shell.Shell
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Companion.KEYCHAIN_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.logger
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.shell
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.APPLE_ID
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.KEYCHAIN_PROFILE
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.NOTARYTOOL
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.ONE_HOUR
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.STAPLE
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.STAPLER
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.STORE_CREDENTIALS
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.SUBMIT
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.TIMEOUT
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.WAIT
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Programs.XCRUN
import java.nio.file.Path

class MacAppNotarizer(private val dmgPath: Path) {
    fun notarize(appleCodeSigning: Options.AppleCodeSigning) {
        shell.execute(notarytoolKeystoreCommand(appleCodeSigning.appleID))
        val requestUUID = parseNotarizeResult(shell.execute(notarizeCommand()).outputString())
        logger.debug { "Notarization request UUID: $requestUUID" }
        markPackageAsApproved()
    }

    private fun notarytoolKeystoreCommand(appleID: String): Shell.Command {
        return Shell.Command(
                Shell.Command.arg(XCRUN), Shell.Command.arg(NOTARYTOOL),
                Shell.Command.arg(STORE_CREDENTIALS), Shell.Command.arg(KEYCHAIN_PASSWORD, printable = false),
                Shell.Command.arg(APPLE_ID), Shell.Command.arg(appleID)
        )
    }

    private fun notarizeCommand(): Shell.Command {
        return Shell.Command(
                Shell.Command.arg(XCRUN), Shell.Command.arg(NOTARYTOOL), Shell.Command.arg(SUBMIT),
                Shell.Command.arg(KEYCHAIN_PROFILE), Shell.Command.arg(KEYCHAIN_PASSWORD, printable = false),
                Shell.Command.arg(WAIT), Shell.Command.arg(TIMEOUT), Shell.Command.arg(ONE_HOUR),
                Shell.Command.arg(dmgPath.toString()),
        )
    }

    private fun parseNotarizeResult(value: String): String {
        return Regex("RequestUUID = ([a-z0-9\\-]{36})").find(value)?.groupValues?.get(1)
                ?: throw IllegalStateException("Notarization failed: the response $value from " +
                        "'xcrun altool --notarize-app' does not contain a valid RequestUUID")
    }

    private fun markPackageAsApproved() {
        shell.execute(listOf(XCRUN, STAPLER, STAPLE, dmgPath.toString()))
    }

    private object Args {
        const val APPLE_ID = "--apple-id"
        const val KEYCHAIN_PROFILE = "--keychain-profile"
        const val NOTARYTOOL = "notarytool"
        const val ONE_HOUR = "1h"
        const val STAPLE = "staple"
        const val STAPLER = "stapler"
        const val STORE_CREDENTIALS = "store-credentials"
        const val SUBMIT = "submit"
        const val TIMEOUT = "--timeout"
        const val WAIT = "--wait"
    }
}
