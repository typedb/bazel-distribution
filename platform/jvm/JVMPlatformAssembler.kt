package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.common.Logging.Logger
import com.vaticle.bazel.distribution.common.OS.LINUX
import com.vaticle.bazel.distribution.common.OS.MAC
import com.vaticle.bazel.distribution.common.OS.WINDOWS
import com.vaticle.bazel.distribution.common.shell.Shell
import com.vaticle.bazel.distribution.common.util.FileUtil.listFilesRecursively
import com.vaticle.bazel.distribution.common.util.SystemUtil.currentOS
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.InputFiles.Paths.JDK
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.InputFiles.Paths.SRC
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.InputFiles.Paths.WIX_TOOLSET
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.APP_IMAGE
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.APP_VERSION
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.COPYRIGHT
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.DESCRIPTION
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.DEST
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.ICON
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.INPUT
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.LICENSE_FILE
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.LINUX_APP_CATEGORY
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.LINUX_MENU_GROUP
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.LINUX_SHORTCUT
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.MAIN_CLASS
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.MAIN_JAR
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.NAME
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.TYPE
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.VENDOR
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.VERBOSE
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.WIN_MENU
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.WIN_MENU_GROUP
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.JPackageArgs.WIN_SHORTCUT
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.PlatformImageBuilder.Windows.Env.PATH
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Programs.JAR
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Programs.JPACKAGE
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Programs.JPACKAGE_EXE
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Programs.TAR
import java.io.File
import java.lang.System.getenv
import java.nio.file.Files
import java.nio.file.Files.createDirectory
import java.nio.file.Path
import kotlin.properties.Delegates

object JVMPlatformAssembler {
    private lateinit var options: Options
    var verbose by Delegates.notNull<Boolean>()
    lateinit var logger: Logger
    lateinit var shell: Shell
    private lateinit var inputFiles: InputFiles
    private val distDir = File("dist")

    fun init(options: Options) {
        this.options = options
        verbose = options.logging.verbose
        shell = Shell(logger, verbose, options.logging.logSensitiveData)
    }

    fun assemble() {
        inputFiles = InputFiles(shell = shell, options = options.input).apply { extractAll() }
        PlatformImageBuilder.forCurrentOS().build()
        outputToArchive()
        logger.debug { "Successfully assembled ${options.image.name} $currentOS image" }
    }

    private fun outputToArchive() {
        shell.execute(
            command = listOf(JAR, "cMf", Path.of("..", options.output.archivePath).toString(), "."),
            baseDir = distDir.toPath()
        )
    }

    private class InputFiles(private val shell: Shell, private val options: Options.Input) {
        lateinit var jpackage: File
        val version = File(options.versionFilePath)
        val srcDir = File(SRC)
        val icon = options.iconPath?.let { File(it) }
        val license = options.licensePath?.let { File(it) }
        val macEntitlements = options.macEntitlementsPath?.let { File(it) }
        val wixToolset = if (options.windowsWiXToolsetPath != null) File(WIX_TOOLSET) else null

        private object Paths {
            const val JDK = "jdk"
            const val SRC = "src"
            const val WIX_TOOLSET = "wixtoolset"
        }

        fun extractAll() {
            extractJDK()
            jpackage = findJPackage()
            if (currentOS == WINDOWS) extractWiXToolset()
            extractSources()
        }

        fun extractJDK() {
            createDirectory(Path.of(JDK))
            when (currentOS) {
                MAC, LINUX -> shell.execute(listOf(TAR, "-xf", options.jdkPath, "-C", JDK))
                WINDOWS -> shell.execute(command = listOf(JAR, "xf", Path.of("..", options.jdkPath).toString()), baseDir = Path.of(JDK))
            }
        }

        fun extractWiXToolset() {
            createDirectory(Path.of(WIX_TOOLSET))
            shell.execute(command = listOf(JAR, "xf", Path.of("..", options.windowsWiXToolsetPath).toString()), baseDir = Path.of(WIX_TOOLSET))
        }

        fun findJPackage(): File {
            val name = if (currentOS == WINDOWS) JPACKAGE_EXE else JPACKAGE
            return File(JDK).listFilesRecursively().firstOrNull { it.name == name }
                ?: throw IllegalStateException("Could not locate '$name' in the provided JDK")
        }

        fun extractSources() {
            val tempDir = "src-temp"
            createDirectory(Path.of(tempDir))
            shell.execute(command = listOf(JAR, "xf", Path.of("..", options.sourceFilename).toString()), baseDir = Path.of(tempDir))
            // Emulate the behaviour of `tar -xf --strip-components=1`
            val files = File(tempDir).listFiles()
            assert(files!!.size == 1)
            assert(files[0].isDirectory)
            Files.move(files[0].toPath(), srcDir.toPath())
            File(tempDir).deleteRecursively()
        }
    }

    private sealed class PlatformImageBuilder {
        protected lateinit var version: String
        protected val shortVersion: String; get() = version.split("-")[0] // e.g: 2.0.0-alpha5 -> 2.0.0

        fun build() {
            version = readVersionFile()
            beforePack()
            pack()
            setPackageFilename()
            afterPack()
        }

        private fun readVersionFile(): String {
            return inputFiles.version.readLines()[0]
        }

        protected open fun beforePack() {}

        protected open fun pack() {
            shell.execute(
                command = listOf(inputFiles.jpackage.path) + packArgsCommon() + packArgsPlatform(),
                env = packEnv()
            )
        }

        private fun setPackageFilename() {
            distDir.listFiles()!![0].let {
                it.renameTo(
                    File(it.path.replace(options.image.name, options.image.filename).replace(shortVersion, version))
                )
            }
        }

        protected open fun packEnv(): Map<String, String> {
            return mapOf()
        }

        private fun packArgsCommon(): List<String> {
            return mutableListOf(
                NAME, options.image.name,
                APP_VERSION, shortVersion,
                INPUT, inputFiles.srcDir.path,
                MAIN_JAR, Path.of(options.input.jarsPath, options.launcher.mainJarPath).toString(),
                MAIN_CLASS, options.launcher.mainClass,
                DEST, distDir.path
            ).apply {
                if (verbose) this += VERBOSE
                options.image.description?.let { this += listOf(DESCRIPTION, it) }
                options.image.vendor?.let { this += listOf(VENDOR, it) }
                options.image.copyright?.let { this += listOf(COPYRIGHT, it) }
                inputFiles.icon?.let { this += listOf(ICON, it.path) }
            }
        }

        protected abstract fun packArgsPlatform(): List<String>

        protected fun licenseArgs(): List<String> {
            return inputFiles.license?.let { listOf(LICENSE_FILE, it.path) } ?: emptyList()
        }

        protected open fun afterPack() {}

        companion object {
            fun forCurrentOS(): PlatformImageBuilder {
                return when (currentOS) {
                    WINDOWS -> Windows()
                    MAC -> Mac()
                    LINUX -> Linux()
                }
            }
        }

        private class Mac: PlatformImageBuilder() {
            val appleCodeSigner: AppleCodeSigner? = when (options.image.appleCodeSigningEnabled) {
                true -> AppleCodeSigner(
                    shell = shell, macEntitlements = requireNotNull(inputFiles.macEntitlements),
                    options = requireNotNull(options.image.appleCodeSigning)
                )
                false -> null
            }
            val appImagePath: Path; get() = Path.of(distDir.path, "${options.image.name}.app")

            override fun beforePack() {
                if (options.image.appleCodeSigningEnabled && options.image.appleCodeSigning!!.signNativeLibsInDeps) {
                    appleCodeSigner!!.init()
                    appleCodeSigner.signUnsignedNativeLibs(inputFiles.srcDir)
                }
            }

            override fun pack() {
                // We need to sign the package in order for it to be distributable to other Mac machines.
                // NOTE: the jpackage tool does have code signing options (--mac-sign, etc.), but they don't seem to
                // work. We work around this by creating an app image, signing it, and repackaging it as a DMG.
                super.pack()
                signAppImageIfSigningEnabled()
                convertPackageToDMG()
                signDMGIfSigningEnabled()
            }

            override fun afterPack() {
                when (val codeSigningOptions = options.image.appleCodeSigning) {
                    null -> logger.debug { "Skipping notarizing step: Apple code signing is not enabled" }
                    else -> {
                        val dmgFilename = "${options.image.filename}-$version.dmg"
                        MacAppNotarizer(
                            options = codeSigningOptions,
                            dmgFilename = dmgFilename,
                            dmgPath = Path.of(distDir.path, dmgFilename)
                        ).notarize()
                    }
                }
            }

            override fun packArgsPlatform(): List<String> {
                return listOf(TYPE, "app-image") // license file (if exists) is added later, at the DMG creation stage
            }

            private fun signAppImageIfSigningEnabled() {
                if (options.image.appleCodeSigningEnabled) {
                    if (!appleCodeSigner!!.initialised) appleCodeSigner.init()
                    appleCodeSigner.signAppImage(appImagePath, options.image.name)
                } else {
                    logger.debug {
                        "Apple code signing will not be performed because it disabled in the configuration " +
                                " (it should only be enabled when distributing an image for use on other machines)"
                    }
                }
            }

            private fun signDMGIfSigningEnabled() {
                if (options.image.appleCodeSigningEnabled) {
                    appleCodeSigner!!.signFile(Path.of(distDir.path, "${options.image.name}-$shortVersion.dmg").toFile())
                }
            }

            private fun convertPackageToDMG() {
                shell.execute(
                    mutableListOf(
                        inputFiles.jpackage.path,
                        NAME, options.image.name,
                        APP_VERSION, shortVersion,
                        TYPE, "dmg",
                        APP_IMAGE, appImagePath.toString(),
                        DEST, distDir.path
                    ).apply {
                        this += licenseArgs()
                        options.image.description?.let { this += listOf(DESCRIPTION, it) }
                        options.image.vendor?.let { this += listOf(VENDOR, it) }
                        options.image.copyright?.let { this += listOf(COPYRIGHT, it) }
                    }
                )
                // Delete the app image (.app), so the output directory is left with just the DMG
                appImagePath.toFile().deleteRecursively()
            }
        }

        private class Linux: PlatformImageBuilder() {
            override fun packArgsPlatform(): List<String> {
                return mutableListOf(TYPE, "deb").apply {
                    this += licenseArgs()
                    if (options.launcher.createShortcut) this += LINUX_SHORTCUT
                    options.launcher.linux.menuGroup?.let { this += listOf(LINUX_MENU_GROUP, it) }
                    options.launcher.linux.appCategory?.let { this += listOf(LINUX_APP_CATEGORY, it) }
                }
            }
        }

        private class Windows: PlatformImageBuilder() {
            override fun packArgsPlatform(): List<String> {
                return mutableListOf(TYPE, "exe").apply {
                    this += licenseArgs()
                    if (options.launcher.createShortcut) this += WIN_SHORTCUT
                    options.launcher.windows.menuGroup?.let {
                        this += listOf(
                            WIN_MENU,
                            WIN_MENU_GROUP, it
                        )
                    }
                }
            }

            override fun packEnv(): Map<String, String> {
                if (inputFiles.wixToolset == null) {
                    throw IllegalStateException("The WiX toolset is required to build on Windows, but is not present in the input files!")
                }
                val systemPath = getenv(PATH) ?: ""
                return mapOf(PATH to "${inputFiles.wixToolset!!.absolutePath};$systemPath")
            }

            private object Env {
                const val PATH = "PATH"
            }
        }

        private object JPackageArgs {
            const val APP_IMAGE = "--app-image"
            const val APP_VERSION = "--app-version"
            const val COPYRIGHT = "--copyright"
            const val DESCRIPTION = "--description"
            const val DEST = "--dest"
            const val ICON = "--icon"
            const val INPUT = "--input"
            const val LICENSE_FILE = "--license-file"
            const val LINUX_APP_CATEGORY = "--linux-app-category"
            const val LINUX_MENU_GROUP = "--linux-menu-group"
            const val LINUX_SHORTCUT = "--linux-shortcut"
            const val MAIN_CLASS = "--main-class"
            const val MAIN_JAR = "--main-jar"
            const val NAME = "--name"
            const val TYPE = "--type"
            const val VENDOR = "--vendor"
            const val VERBOSE = "--verbose"
            const val WIN_MENU = "--win-menu"
            const val WIN_MENU_GROUP = "--win-menu-group"
            const val WIN_SHORTCUT = "--win-shortcut"
        }
    }
}
