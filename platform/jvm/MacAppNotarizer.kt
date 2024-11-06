package com.typedb.bazel.distribution.platform.jvm

import com.typedb.bazel.distribution.common.shell.Shell
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
import com.typedb.bazel.distribution.platform.jvm.MacAppNotarizer.Args.WAIT
import com.typedb.bazel.distribution.platform.jvm.ShellArgs.Programs.XCRUN
import java.nio.file.Path

class MacAppNotarizer(private val dmgPath: Path) {
    fun notarize(appleCodeSigning: Options.AppleCodeSigning) {
        shell.execute(notarizeCommand(appleCodeSigning)).outputString()
        markPackageAsApproved()
    }

    private fun notarizeCommand(appleCodeSigning: Options.AppleCodeSigning): Shell.Command {
        return Shell.Command(
                Shell.Command.arg(XCRUN), Shell.Command.arg(NOTARYTOOL), Shell.Command.arg(SUBMIT),
                Shell.Command.arg(APPLE_ID), Shell.Command.arg(appleCodeSigning.appleID),
                Shell.Command.arg(PASSWORD), Shell.Command.arg(appleCodeSigning.appleIDPassword, printable = false),
                Shell.Command.arg(TEAM_ID), Shell.Command.arg(appleCodeSigning.appleTeamID, printable = false),
                Shell.Command.arg(WAIT), Shell.Command.arg(TIMEOUT), Shell.Command.arg(ONE_HOUR),
                Shell.Command.arg(dmgPath.toString()),
        )
    }

    private fun markPackageAsApproved() {
        shell.execute(listOf(XCRUN, STAPLER, STAPLE, dmgPath.toString()))
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
        const val WAIT = "--wait"
    }
}
