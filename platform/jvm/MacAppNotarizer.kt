package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.ALTOOL
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.FILE
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.NOTARIZATION_INFO
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.NOTARIZE_APP
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.PRIMARY_BUNDLE_ID
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.STAPLE
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.STAPLER
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.Args.USERNAME
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.NotarizationInfoResult.Status.APPROVED
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.NotarizationInfoResult.Status.PENDING
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.NotarizationInfoResult.Status.REJECTED
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.StatusPoller.LOG_FILE_URL
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.StatusPoller.MAX_RETRIES
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.StatusPoller.POLL_INTERVAL_MS
import com.vaticle.bazel.distribution.platform.jvm.MacAppNotarizer.StatusPoller.STATUS_MESSAGE_PACKAGE_APPROVED
import java.nio.file.Path

class MacAppNotarizer(private val options: Options.AppleCodeSigning, private val dmgName: String, private val dmgPath: Path) {
    fun notarize() {
        val requestUUID = parseNotarizeResult(JVMPlatformAssembler.shell.execute(notarizeCommand()).outputString())
        JVMPlatformAssembler.logger.debug { "Notarization request UUID: $requestUUID" }
        waitForPackageApproval(requestUUID)
        markPackageAsApproved()
    }

    private fun notarizeCommand(): Shell.Command {
        // TODO: xcrun altool --notarize-app is deprecated in Xcode 13: see
        //       https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow?preferredLanguage=occ
        return Shell.Command(
            Shell.Command.arg(Shell.Programs.XCRUN), Shell.Command.arg(ALTOOL), Shell.Command.arg(NOTARIZE_APP),
            Shell.Command.arg(PRIMARY_BUNDLE_ID), Shell.Command.arg(options.macAppID),
            Shell.Command.arg(USERNAME), Shell.Command.arg(options.appleID, printable = false),
            Shell.Command.arg(PASSWORD), Shell.Command.arg(options.appleIDPassword, printable = false),
            Shell.Command.arg(FILE), Shell.Command.arg(dmgPath.toString())
        )
    }

    private fun parseNotarizeResult(value: String): String {
        return Regex("RequestUUID = ([a-z0-9\\-]{36})").find(value)?.groupValues?.get(1)
            ?: throw IllegalStateException("Notarization failed: the response $value from " +
                    "'xcrun altool --notarize-app' does not contain a valid RequestUUID")
    }

    private fun waitForPackageApproval(requestUUID: String) {
        var retries = 0
        while (retries < MAX_RETRIES) {
            Thread.sleep(POLL_INTERVAL_MS)
            val notarizeResult = NotarizationInfoResult.of(
                JVMPlatformAssembler.shell.execute(notarizationInfoCommand(requestUUID)).outputString()
            )
            when (notarizeResult.status) {
                PENDING -> retries++
                APPROVED -> {
                    JVMPlatformAssembler.logger.debug { "$dmgName was APPROVED by the Apple notarization service" }
                    return
                }
                REJECTED -> {
                    throw IllegalStateException("$dmgName was REJECTED by the Apple notarization service\n${notarizeResult.rawText}")
                }
            }
        }
        throw IllegalStateException("Timed out while waiting for $dmgName to be scanned by the Apple notarization service; the bundle is still in PENDING status (RequestUUID = $requestUUID)")
    }

    private fun notarizationInfoCommand(requestUUID: String): Shell.Command {
        return Shell.Command(
            Shell.Command.arg(Shell.Programs.XCRUN), Shell.Command.arg(ALTOOL), Shell.Command.arg(NOTARIZATION_INFO),
            Shell.Command.arg(requestUUID),
            Shell.Command.arg(USERNAME), Shell.Command.arg(options.appleID, printable = false),
            Shell.Command.arg(PASSWORD), Shell.Command.arg(options.appleIDPassword, printable = false)
        )
    }

    private fun markPackageAsApproved() {
        JVMPlatformAssembler.shell.execute(listOf(Shell.Programs.XCRUN, STAPLER, STAPLE, dmgPath.toString()))
    }

    private data class NotarizationInfoResult(val status: Status, val rawText: String) {
        enum class Status {
            PENDING,
            APPROVED,
            REJECTED
        }

        companion object {
            fun of(info: String): NotarizationInfoResult {
                return when {
                    STATUS_MESSAGE_PACKAGE_APPROVED in info -> {
                        NotarizationInfoResult(status = APPROVED, rawText = info)
                    }
                    LOG_FILE_URL in info -> {
                        // Apple log file takes time to build, so it's possible to see "Package Declined" before a
                        // LogFileURL is available. It's useful to read the log file, so we wait for it to be generated.
                        NotarizationInfoResult(status = REJECTED, rawText = info)
                    }
                    else -> {
                        NotarizationInfoResult(status = PENDING, rawText = info)
                    }
                }
            }
        }
    }

    private object Args {
        const val ALTOOL = "altool"
        const val FILE = "--file"
        const val NOTARIZATION_INFO = "--notarization-info"
        const val NOTARIZE_APP = "--notarize-app"
        const val PASSWORD = "--password"
        const val PRIMARY_BUNDLE_ID = "--primary-bundle-id"
        const val STAPLE = "staple"
        const val STAPLER = "stapler"
        const val USERNAME = "--username"
    }

    private object StatusPoller {
        const val LOG_FILE_URL = "LogFileURL"
        const val MAX_RETRIES = 30
        const val POLL_INTERVAL_MS = 30000L
        const val STATUS_MESSAGE_PACKAGE_APPROVED = "Status Message: Package Approved"
    }
}
