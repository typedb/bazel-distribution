package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.platform.jvm.Shell.Command.Companion.arg
import org.zeroturnaround.exec.ProcessExecutor
import org.zeroturnaround.exec.ProcessResult
import java.nio.file.Path
import java.nio.file.Paths

class Shell(private val verbose: Boolean = false, private val printSensitiveData: Boolean = false) {
    fun execute(
        command: List<String>, baseDir: Path = Paths.get("."),
        env: Map<String, String> = mapOf(), outputIsSensitive: Boolean = false, throwOnError: Boolean = true
    ): ProcessResult {
        return execute(Command(*command.map { arg(it) }.toTypedArray()), baseDir, env, outputIsSensitive, throwOnError)
    }

    fun execute(
        command: Command, baseDir: Path = Paths.get("."),
        env: Map<String, String> = mapOf(), outputIsSensitive: Boolean = false, throwOnError: Boolean = true
    ): ProcessResult {
        val executor = ProcessExecutor(command.args.map { it.value }).apply {
            readOutput(true)
            redirectError(System.err)
            directory(baseDir.toFile())
            environment(env)
            if (shouldPrintOutput(outputIsSensitive)) redirectOutput(System.out)
            if (throwOnError) exitValueNormal()
        }

        return executor.execute().also {
            if (it.exitValue != 0 || verbose) println("Execution of $command finished with exit code '${it.exitValue}'")
        }
    }

    fun shouldPrintOutput(sensitive: Boolean): Boolean {
        return verbose && (!sensitive || printSensitiveData)
    }

    class Command(vararg args: Argument) {
        val args = args.toList()

        companion object {
            fun arg(value: String, printable: Boolean = true) = Argument(value, printable)
        }

        class Argument(val value: String, val printable: Boolean = true) {
            override fun toString(): String {
                return if (printable) value else "(hidden argument)"
            }
        }
    }

    object Programs {
        const val CODESIGN = "codesign"
        const val JAR = "jar"
        const val JPACKAGE = "jpackage"
        const val JPACKAGE_EXE = "jpackage.exe"
        const val OPENSSL = "openssl"
        const val SECURITY = "security"
        const val TAR = "tar"
    }

    object Extensions {
        const val DYLIB = "dylib"
        const val JAR = "jar"
        const val JNILIB = "jnilib"
    }
}
