package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.common.util.SystemUtil

class JVMPlatformAssembler(val options: Options) {
    fun assemble() {
        InputExtractor().extractAll()
        ImageBuilder().build()
        if (os == Mac) MacAppNotarizer().notarize()
        outputToArchive()
        log { "Successfully assembled ${options.application.name} ${SystemUtil.currentOS} image" }
    }

    fun log(verbose: Boolean = true, message: () -> String) {
        if (options.verbose) println(message())
    }

    private fun outputToArchive() {
        TODO()
    }

    private class InputExtractor {
        fun extractAll() {
            extractJDK()
            if (os == Windows) extractWiXToolset()
            findJPackage()
            extractSources()
            if (os == Mac) signSources()
        }

        fun extractJDK() {
            TODO()
        }

        fun extractWiXToolset() {
            TODO()
        }

        fun findJPackage() {
            TODO()
        }

        fun extractSources() {
            TODO()
        }

        fun signSources() {
            TODO()
        }
    }

    private class ImageBuilder {
        fun build() {
            TODO()
        }
    }

    private class MacAppNotarizer {
        fun notarize() {
            TODO()
        }
    }
}
