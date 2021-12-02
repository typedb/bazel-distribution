package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.platform.jvm.Logging.LogLevel.DEBUG

object Logging {
    class Logger(private val logLevel: LogLevel) {
        fun debug(message: () -> String) {
            if (logLevel == DEBUG) println(message())
        }
    }

    enum class LogLevel {
        DEBUG,
        ERROR,
    }
}
