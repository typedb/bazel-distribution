package com.typedb.bazel.distribution.platform.jvm

object ShellArgs {
    object Programs {
        const val CODESIGN = "codesign"
        const val JAR = "jar"
        const val JPACKAGE = "jpackage"
        const val JPACKAGE_EXE = "jpackage.exe"
        const val SECURITY = "security"
        const val TAR = "tar"
        const val XCRUN = "xcrun"
    }

    object Extensions {
        const val DYLIB = "dylib"
        const val JAR = "jar"
        const val JNILIB = "jnilib"
    }
}
