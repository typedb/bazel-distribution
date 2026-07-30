package com.typedb.bazel.distribution.common.shell

import com.typedb.bazel.distribution.common.shell.Shell.Command.Companion.arg
import com.typedb.bazel.distribution.common.Logging.Logger
import org.zeroturnaround.exec.ProcessExecutor
import org.zeroturnaround.exec.ProcessResult
import java.nio.file.Path
import java.nio.file.Paths
import java.time.Duration
import java.util.concurrent.TimeUnit

class Shell(private val logger: Logger, private val verbose: Boolean = false, private val printSensitiveData: Boolean = false) {
    fun execute(
        command: List<String>, baseDir: Path = Paths.get("."),
        env: Map<String, String> = mapOf(), outputIsSensitive: Boolean = false, throwOnError: Boolean = true,
        timeout: Duration? = null,
    ): ProcessResult {
        return execute(Command(*command.map { arg(it) }.toTypedArray()), baseDir, env, outputIsSensitive, throwOnError, timeout)
    }

    fun execute(
        command: Command, baseDir: Path = Paths.get("."),
        env: Map<String, String> = mapOf(), outputIsSensitive: Boolean = false, throwOnError: Boolean = true,
        timeout: Duration? = null,
    ): ProcessResult {
        val executor = ProcessExecutor(command.args.map { it.value }).apply {
            readOutput(true)
            redirectError(System.err)
            directory(baseDir.toFile())
            environment(env)
            if (shouldPrintOutput(outputIsSensitive)) redirectOutput(System.out)
            if (timeout != null) timeout(timeout.toMillis(), TimeUnit.MILLISECONDS)
        }

        return executor.execute().also {
            val message = "Execution of $command finished with exit code '${it.exitValue}'"
            if (it.exitValue != 0 && throwOnError) throw IllegalStateException(message)
            else if (verbose) logger.debug { "Execution of $command finished with exit code '${it.exitValue}'" }
        }
    }

    private fun shouldPrintOutput(sensitive: Boolean): Boolean {
        return verbose && (!sensitive || printSensitiveData)
    }

    class Command(val args: List<Argument>) {
        constructor(vararg args: Argument): this(args.toList())

        override fun toString(): String {
            return args.toString()
        }

        companion object {
            fun arg(value: String, printable: Boolean = true) = Argument(value, printable)
        }

        class Argument(val value: String, private val printable: Boolean = true) {
            override fun toString(): String {
                return if (printable) value else "(hidden)"
            }
        }
    }
}
