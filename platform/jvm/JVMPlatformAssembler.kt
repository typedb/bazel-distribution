package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.common.OS.LINUX
import com.vaticle.bazel.distribution.common.OS.MAC
import com.vaticle.bazel.distribution.common.OS.WINDOWS
import com.vaticle.bazel.distribution.common.util.FileUtil.listFilesRecursively
import com.vaticle.bazel.distribution.common.util.SystemUtil.currentOS
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.CREATE_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.DEFAULT_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.DELETE_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.IMPORT
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.LIST_KEYCHAINS
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.LOGIN_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.SET_KEY_PARTITION_LIST
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.UNLOCK_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.USER
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.USR_BIN_CODESIGN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.VerifySignatureResult.Status
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.VerifySignatureResult.Status.SIGNED
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.InputFiles.Paths.JDK
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.InputFiles.Paths.WIX_TOOLSET
import com.vaticle.bazel.distribution.platform.jvm.Logging.LogLevel.DEBUG
import com.vaticle.bazel.distribution.platform.jvm.Logging.LogLevel.ERROR
import com.vaticle.bazel.distribution.platform.jvm.Logging.Logger
import com.vaticle.bazel.distribution.platform.jvm.Shell.Command.Companion.arg
import com.vaticle.bazel.distribution.platform.jvm.Shell.Extensions
import com.vaticle.bazel.distribution.platform.jvm.Shell.Extensions.DYLIB
import com.vaticle.bazel.distribution.platform.jvm.Shell.Extensions.JNILIB
import com.vaticle.bazel.distribution.platform.jvm.Shell.Programs.CODESIGN
import com.vaticle.bazel.distribution.platform.jvm.Shell.Programs.JAR
import com.vaticle.bazel.distribution.platform.jvm.Shell.Programs.JPACKAGE
import com.vaticle.bazel.distribution.platform.jvm.Shell.Programs.JPACKAGE_EXE
import com.vaticle.bazel.distribution.platform.jvm.Shell.Programs.SECURITY
import com.vaticle.bazel.distribution.platform.jvm.Shell.Programs.TAR
import org.zeroturnaround.exec.ProcessResult
import java.io.File
import java.io.FileInputStream
import java.nio.file.Files
import java.nio.file.Files.createDirectory
import java.nio.file.Path
import java.security.KeyStore
import kotlin.properties.Delegates

object JVMPlatformAssembler {
    private lateinit var options: Options
    var verbose by Delegates.notNull<Boolean>()
    lateinit var logger: Logger
    lateinit var shell: Shell

    fun assemble(options: Options) {
        verbose = options.verbose
        shell = Shell(verbose)
        val inputFiles = InputFiles(shell = shell, options = options.input).apply { extractAll() }
        PlatformImageBuilder.of(shell, logger, inputFiles, options.image).build()
        if (currentOS == MAC) MacAppNotarizer().notarize()
        outputToArchive()
        log { "Successfully assembled ${options.image.name} $currentOS image" }
    }

    private fun log(verbose: Boolean = true, message: () -> String) {
        if (!verbose || options.verbose) println(message())
    }

    private fun outputToArchive() {
        TODO()
    }

    private class InputFiles(private val shell: Shell, private val options: Options.Input) {
        lateinit var jpackage: File
        val version = File(options.versionFilePath)
        val srcPath: Path = Path.of("src")
        val macEntitlements = options.macEntitlementsPath?.let { File(it) }

        private object Paths {
            const val JDK = "jdk"
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
            Files.move(files[0].toPath(), srcPath)
        }
    }

    private sealed class PlatformImageBuilder(protected val ctx: Context) {
        fun build() {
            beforePack()
            pack()
            afterPack()
        }

        fun pack() {
            val version = ctx.inputFiles.version.readLines()[0]
            TODO()
        }

        open fun beforePack() {}

        open fun afterPack() {}

        class Context(val shell: Shell, val logger: Logger, val inputFiles: InputFiles, val options: Options.Image)

        companion object {
            fun of(shell: Shell, logger: Logger, inputFiles: InputFiles, options: Options.Image): PlatformImageBuilder {
                val ctx = Context(shell, logger, inputFiles, options)
                return when (currentOS) {
                    WINDOWS -> Windows(ctx)
                    MAC -> Mac(ctx)
                    LINUX -> Linux(ctx)
                }
            }
        }

        private class Mac(ctx: Context): PlatformImageBuilder(ctx) {
            val appleCodeSigner: AppleCodeSigner? = when (ctx.options.appleCodeSigningEnabled) {
                true -> AppleCodeSigner(
                    shell = ctx.shell, macEntitlements = requireNotNull(ctx.inputFiles.macEntitlements),
                    options = requireNotNull(ctx.options.appleCodeSigning)
                )
                false -> null
            }

            override fun beforePack() {
                if (ctx.options.appleCodeSigningEnabled) {
                    requireNotNull(appleCodeSigner)
                    appleCodeSigner.setupSigningIdentity()
                    // Some JARs contain unsigned `.jnilib` and `.dylib` files, which we can extract, sign and repackage
                    if (ctx.options.appleCodeSigning!!.signNativeLibsInDeps) {
                        appleCodeSigner.signUnsignedNativeLibs(ctx.inputFiles.srcPath.toFile())
                    }
                } else {
                    ctx.logger.debug {
                        "Apple code signing will not be performed because it disabled in the configuration " +
                                " (it should only be enabled when distributing an image for use on other machines)"
                    }
                }
            }
        }

        private class Linux(ctx: Context): PlatformImageBuilder(ctx) {

        }

        private class Windows(ctx: Context): PlatformImageBuilder(ctx) {

        }
    }

    private class AppleCodeSigner(private val shell: Shell, private val macEntitlements: File, private val options: Options.AppleCodeSigning) {
        lateinit var certSubject: String

        // TODO: copy the contents of this SO post into a PR comment at this line: https://stackoverflow.com/a/57912831/2902555
        fun setupSigningIdentity() {
            deleteExistingKeychainIfPresent()
            createKeychain()
            makeKeychainAccessible()
            importCodeSigningIdentity()
            makeCodeSigningIdentityAccessible()
            certSubject = findCertSubject()
        }

        private fun deleteExistingKeychainIfPresent() {
            val keychainListInfo = shell.execute(listOf(SECURITY, LIST_KEYCHAINS)).outputString()
            if (KEYCHAIN_NAME in keychainListInfo) shell.execute(listOf(SECURITY, DELETE_KEYCHAIN, KEYCHAIN_NAME))
        }

        private fun createKeychain() {
            shell.execute(
                Shell.Command(
                    arg(SECURITY), arg(CREATE_KEYCHAIN),
                    arg("-p"), arg(KEYCHAIN_PASSWORD, printable = false),
                    arg(KEYCHAIN_NAME)
                )
            )
        }

        private fun makeKeychainAccessible() {
            shell.execute(listOf(SECURITY, DEFAULT_KEYCHAIN, "-s", KEYCHAIN_NAME))
            shell.execute(listOf(SECURITY, LIST_KEYCHAINS, "-d", USER, "-s", LOGIN_KEYCHAIN, KEYCHAIN_NAME))
            shell.execute(
                Shell.Command(
                    arg(SECURITY), arg(UNLOCK_KEYCHAIN),
                    arg("-p"), arg(KEYCHAIN_PASSWORD, printable = false),
                    arg(KEYCHAIN_NAME)
                )
            )
        }

        private fun importCodeSigningIdentity() {
            shell.execute(
                Shell.Command(
                    arg(SECURITY), arg(IMPORT), arg(options.cert.path),
                    arg("-k"), arg(KEYCHAIN_NAME),
                    arg("-P"), arg(options.certPassword, printable = false),
                    arg("-T"), arg(USR_BIN_CODESIGN)
                )
            )
        }

        private fun makeCodeSigningIdentityAccessible() {
            shell.execute(
                Shell.Command(
                    arg(SECURITY), arg(SET_KEY_PARTITION_LIST),
                    arg("-S"), arg(KEY_PARTITION_LIST),
                    arg("-s"),
                    arg("-k"), arg(KEYCHAIN_PASSWORD, printable = false),
                    arg(KEYCHAIN_NAME)
                )
            )
        }

        private fun findCertSubject(): String {
            val keystore = KeyStore.getInstance("PKCS12")
            keystore.load(FileInputStream(options.cert.path), options.certPassword.toCharArray())
            return "banana"
//            val certContent = shell.execute(
//                Shell.Command(
//                    arg(OPENSSL), arg("pkcs12"),
//                    arg("-in"), arg(options.cert.path),
//                    arg("-nodes"),
//                    arg("-passin"), arg("pass:${options.certPassword}", printable = false)
//                ), outputIsSensitive = true
//            )
//            val commonName = PKCS1
        }

        fun signUnsignedNativeLibs(root: File) {
            for (jar in root.listFilesRecursively().filter {
                it.isFile && it.extension == Extensions.JAR && it.name.matches(requireNotNull(options.deepSignJarsRegex))
            }) {
                val tmpPath = Path.of("tmp")
                val tmpDir: File = tmpPath.toFile()
                createDirectory(tmpPath)
                shell.execute(listOf(JAR, "xf", "../${jar.path}"), baseDir = tmpPath).outputString()

                val nativeLibs = tmpDir.listFilesRecursively().filter { it.extension in listOf(JNILIB, DYLIB) }
                if (nativeLibs.isNotEmpty()) {
                    nativeLibs.forEach { signFile(it) }
                    jar.setWritable(true)
                    jar.delete()
                    shell.execute(listOf(JAR, "cMf", "../${jar.path}", "."), baseDir = tmpPath)
                }

                tmpDir.deleteRecursively()
            }
        }

        fun signFile(file: File, deep: Boolean = false, overwriteExisting: Boolean = false) {
            if (!overwriteExisting) {
                val verifySignatureResult = VerifySignatureResult(
                    shell.execute(listOf(CODESIGN, "-v", "--strict", file.path), throwOnError = false)
                )
                if (verifySignatureResult.status == SIGNED) return
                else if (verifySignatureResult.status == Status.ERROR) {
                    throw IllegalStateException("Command '$CODESIGN' failed with exit code " +
                            "${verifySignatureResult.exitValue} and output: ${verifySignatureResult.outputString()}")
                }
            }

            file.setWritable(true)
            val signCommand: MutableList<String> = mutableListOf(
                CODESIGN, "-s", certSubject,
                "-f",
                "--entitlements", macEntitlements.path,
                "--prefix", "com.vaticle.typedb.studio.",
                "--options", "runtime",
                "--timestamp",
                "--keychain", KEYCHAIN_NAME,
                file.path)
            if (deep) signCommand += "--deep"
            if (verbose) signCommand += "-vvv"
            shell.execute(signCommand)
        }

        companion object {
            const val KEYCHAIN_NAME = "jvm-platform-assembler.keychain"
            const val KEYCHAIN_PASSWORD = "jvm-platform-assembler"
            const val KEY_PARTITION_LIST = "apple-tool:,apple:,codesign:"
        }

        private object Security {
            const val CREATE_KEYCHAIN = "create-keychain"
            const val DEFAULT_KEYCHAIN = "default-keychain"
            const val DELETE_KEYCHAIN = "delete-keychain"
            const val IMPORT = "import"
            const val LIST_KEYCHAINS = "list-keychains"
            const val LOGIN_KEYCHAIN = "login.keychain"
            const val SET_KEY_PARTITION_LIST = "set-key-partition-list"
            const val UNLOCK_KEYCHAIN = "unlock-keychain"
            const val USER = "user"
            const val USR_BIN_CODESIGN = "/usr/bin/codesign"
        }

        private class VerifySignatureResult(private val codesignProcessResult: ProcessResult) {
            val status = Status.of(codesignProcessResult.exitValue)
            val exitValue: Int = codesignProcessResult.exitValue
            fun outputString(): String = codesignProcessResult.outputString()

            enum class Status {
                SIGNED,
                UNSIGNED,
                ERROR;

                companion object {
                    fun of(exitValue: Int): Status {
                        return when (exitValue) {
                            0 -> SIGNED
                            1 -> UNSIGNED
                            else -> ERROR
                        }
                    }
                }
            }
        }
    }

    private class MacAppNotarizer {
        fun notarize() {
            TODO()
        }
    }
}
