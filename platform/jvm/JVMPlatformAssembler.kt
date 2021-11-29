package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.common.OS.LINUX
import com.vaticle.bazel.distribution.common.OS.MAC
import com.vaticle.bazel.distribution.common.OS.WINDOWS
import com.vaticle.bazel.distribution.common.util.FileUtil.listFilesRecursively
import com.vaticle.bazel.distribution.common.util.SystemUtil.currentOS
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.CN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.CREATE_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.DEFAULT_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.DELETE_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.IMPORT
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.LIST_KEYCHAINS
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.LOGIN_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.PKCS12
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.SET_KEY_PARTITION_LIST
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.UNLOCK_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.USER
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.Security.USR_BIN_CODESIGN
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.VerifySignatureResult.Status
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.AppleCodeSigner.VerifySignatureResult.Status.SIGNED
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.InputFiles.Paths.JDK
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.InputFiles.Paths.WIX_TOOLSET
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
import java.lang.System.getenv
import java.nio.file.Files
import java.nio.file.Files.createDirectory
import java.nio.file.Path
import java.security.KeyStore
import java.security.cert.Certificate
import java.security.cert.X509Certificate
import javax.naming.ldap.LdapName
import javax.naming.ldap.Rdn
import kotlin.properties.Delegates

object JVMPlatformAssembler {
    private lateinit var options: Options
    var verbose by Delegates.notNull<Boolean>()
    lateinit var logger: Logger
    lateinit var shell: Shell
    private lateinit var inputFiles: InputFiles

    fun assemble(options: Options) {
        verbose = options.verbose
        shell = Shell(verbose)
        inputFiles = InputFiles(shell = shell, options = options.input).apply { extractAll() }
        PlatformImageBuilder.forCurrentOS().build()
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
        val srcDir = File("src")
        val icon = options.iconPath?.let { File(it) }
        val license = options.licensePath?.let { File(it) }
        val macEntitlements = options.macEntitlementsPath?.let { File(it) }
        val wixToolset = options.windowsWiXToolsetPath?.let { File(it) }

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
            Files.move(files[0].toPath(), srcDir.toPath())
        }
    }

    private sealed class PlatformImageBuilder {
        private lateinit var version: String
        private val shortVersion: String; get() = version.split("-")[0] // e.g: 2.0.0-alpha5 -> 2.0.0
        protected val distDir = File("dist")

        fun build() {
            version = readVersionFile()
            beforePack()
            pack()
            afterPack()
            setImageFilename() // this step should rename the image to applicationFilename
        }

        private fun readVersionFile(): String {
            return inputFiles.version.readLines()[0]
        }

        open fun beforePack() {}

        open fun pack() {
            shell.execute(
                command = listOf(inputFiles.jpackage.path) + packArgsCommon() + packArgsPlatform(),
                env = packEnv()
            )
        }

        protected open fun packEnv(): Map<String, String> {
            return mapOf()
        }

        private fun packArgsCommon(): List<String> {
            return mutableListOf(
                inputFiles.jpackage.path,
                NAME, options.image.name,
                APP_VERSION, shortVersion,
                INPUT, inputFiles.srcDir.path,
                MAIN_JAR, options.launcher.mainJar,
                MAIN_CLASS, options.launcher.mainClass,
                DEST, distDir.path
            ).apply {
                if (verbose) this += VERBOSE
                options.image.description?.let { this += listOf(DESCRIPTION, it) }
                options.image.vendor?.let { this += listOf(VENDOR, it) }
                options.image.copyright?.let { this += listOf(COPYRIGHT, it) }
                inputFiles.icon?.let { this += listOf(ICON, it.path) }
                inputFiles.license?.let { this += listOf(LICENSE_FILE, it.path) }
            }
        }

        abstract fun packArgsPlatform(): List<String>

        protected fun licenseArgs(): List<String> {
            return inputFiles.license?.let { listOf(LICENSE_FILE, it.path) } ?: emptyList()
        }

        open fun afterPack() {}

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

            override fun beforePack() {
                if (options.image.appleCodeSigningEnabled && options.image.appleCodeSigning!!.signNativeLibsInDeps) {
                    appleCodeSigner!!.init()
                    appleCodeSigner.signUnsignedNativeLibs(inputFiles.srcDir)
                }
            }

            override fun pack() {
                super.pack()
                if (options.image.appleCodeSigningEnabled) {
                    if (!appleCodeSigner!!.initialised) appleCodeSigner.init()
                    appleCodeSigner.signAppImage(Path.of(distDir.path, "${options.image.name}.app"))
                } else {
                    logger.debug {
                        "Apple code signing will not be performed because it disabled in the configuration " +
                                " (it should only be enabled when distributing an image for use on other machines)"
                    }
                }
                TODO()
            }

            override fun packArgsPlatform(): List<String> {
                return listOf(TYPE, "--app-image") // license file (if exists) is added later, at the DMG creation stage
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
                val systemPath = getenv("PATH") ?: ""
                return mapOf("PATH" to "${inputFiles.wixToolset!!.absolutePath};$systemPath")
            }
        }

        private object JPackageArgs {
            const val APP_VERSION = "--app_version"
            const val COPYRIGHT = "--copyright"
            const val DESCRIPTION = "--description"
            const val DEST = "--dest"
            const val ICON = "--icon"
            const val INPUT = "--input"
            const val LICENSE_FILE = "--license_file"
            const val LINUX_APP_CATEGORY = "--linux_app_category"
            const val LINUX_MENU_GROUP = "--linux_menu_group"
            const val LINUX_SHORTCUT = "--linux_shortcut"
            const val MAIN_CLASS = "--main_class"
            const val MAIN_JAR = "--main_jar"
            const val NAME = "--name"
            const val TYPE = "--type"
            const val VENDOR = "--vendor"
            const val VERBOSE = "--verbose"
            const val WIN_MENU = "--win_menu"
            const val WIN_MENU_GROUP = "--win_menu_group"
            const val WIN_SHORTCUT = "--win_shortcut"
        }
    }

    private class AppleCodeSigner(private val shell: Shell, private val macEntitlements: File, private val options: Options.AppleCodeSigning) {
        var initialised: Boolean = false
        lateinit var certSubject: String

        // TODO: copy the contents of this SO post into a PR comment at this line: https://stackoverflow.com/a/57912831/2902555
        fun init() {
            deleteExistingKeychainIfPresent()
            createKeychain()
            setDefaultKeychain()
            unlockKeychain()
            importCodeSigningIdentity()
            makeCodeSigningIdentityAccessible()
            certSubject = findCertSubject()
            initialised = true
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

        private fun setDefaultKeychain() {
            shell.execute(listOf(SECURITY, DEFAULT_KEYCHAIN, "-s", KEYCHAIN_NAME))
            shell.execute(listOf(SECURITY, LIST_KEYCHAINS, "-d", USER, "-s", LOGIN_KEYCHAIN, KEYCHAIN_NAME))
        }

        fun unlockKeychain() {
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
            val keystore = KeyStore.getInstance(PKCS12)
            keystore.load(FileInputStream(options.cert.path), options.certPassword.toCharArray())
            val keystoreAliases = keystore.aliases().toList()
            assert(keystoreAliases.size == 1)
            val cert: Certificate = keystore.getCertificate(keystore.aliases().nextElement())
            if (cert !is X509Certificate) throw IllegalStateException("Imported cert is not an X509 certificate (type = ${cert.type})")
            val subject = cert.subjectX500Principal.name
            val subjectCommonName: Rdn = LdapName(subject).rdns.find { it.type == CN }
                ?: throw IllegalStateException("Imported X509 cert subject does not specify a common name ($CN)! (subject = $subject)")
            return subjectCommonName.value.toString()
        }

        fun signAppImage(rootPath: Path) {
            TODO()
        }

        fun signUnsignedNativeLibs(root: File) {
            // Some JARs contain unsigned `.jnilib` and `.dylib` files, which we can extract, sign and repackage
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
            const val CN = "CN"
            const val CREATE_KEYCHAIN = "create-keychain"
            const val DEFAULT_KEYCHAIN = "default-keychain"
            const val DELETE_KEYCHAIN = "delete-keychain"
            const val IMPORT = "import"
            const val LIST_KEYCHAINS = "list-keychains"
            const val LOGIN_KEYCHAIN = "login.keychain"
            const val PKCS12 = "PKCS12"
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
