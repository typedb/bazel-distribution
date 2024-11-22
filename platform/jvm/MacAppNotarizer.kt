package com.typedb.bazel.distribution.platform.jvm

import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.Logging.LogLevel.DEBUG
import com.typedb.bazel.distribution.common.Logging.LogLevel.ERROR
import com.typedb.bazel.distribution.common.Logging.Logger
import com.typedb.bazel.distribution.common.shell.Shell
import com.typedb.bazel.distribution.common.shell.Shell.Command.Companion.arg
import com.typedb.bazel.distribution.platform.jvm.JVMPlatformAssembler.shell
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.APPLE_ID
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.NOTARYTOOL
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.ONE_HOUR
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.PASSWORD
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.STAPLE
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.STAPLER
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.SUBMIT
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.TEAM_ID
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.TIMEOUT
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.VERBOSE
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.WAIT
import com.typedb.bazel.distribution.platform.jvm.ShellArgs.Programs.XCRUN
import java.nio.file.Path

class MacAppNotarizer(
    private val dmgPath: Path, appleCodeSigning: Options.AppleCodeSigning, private val logging: Options.Logging
) {
    private val logger = Logger(logLevel = if (logging.verbose) DEBUG else ERROR)

    fun notarize() {
        shell.execute(notarizeCommand).outputString()
        logger.debug { "\nUse `xcrun notarytool log <submission-id>` to view further information about this notarization\n" }
        markPackageAsApproved()
    }

    private val notarizeCommand = Shell.Command(listOfNotNull(
        arg(XCRUN), arg(NOTARYTOOL), arg(SUBMIT),
        if (logging.verbose) arg(VERBOSE) else null,
        arg(APPLE_ID), arg(appleCodeSigning.appleID),
        arg(PASSWORD), arg(appleCodeSigning.appleIDPassword, printable = false),
        arg(TEAM_ID), arg(appleCodeSigning.appleTeamID, printable = false),
        arg(WAIT), arg(TIMEOUT), arg(ONE_HOUR),
        arg(dmgPath.toString()),
    ))

    private fun markPackageAsApproved() {
        shell.execute(listOfNotNull(XCRUN, STAPLER, STAPLE, if (logging.verbose) VERBOSE else null, dmgPath.toString()))
    }

    private object Args {
        const val APPLE_ID = "--apple-id"
        const val NOTARYTOOL = "notarytool"
        const val ONE_HOUR = "1h"
        const val STAPLE = "staple"
        const val STAPLER = "stapler"
        const val PASSWORD = "--password"
        const val SUBMIT = "submit"
        const val TIMEOUT = "--timeout"
        const val TEAM_ID = "--team-id"
        const val VERBOSE = "-v"
        const val WAIT = "--wait"
    }
}
