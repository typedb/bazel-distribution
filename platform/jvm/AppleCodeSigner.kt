package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.common.shell.Shell
import com.vaticle.bazel.distribution.common.util.FileUtil.listFilesRecursively
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Codesign.Args.ENTITLEMENTS
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Codesign.Args.FORCE
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Codesign.Args.KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Codesign.Args.OPTIONS
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Codesign.Args.SIGN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Codesign.Args.TIMESTAMP
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Paths.TMP
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.CN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.CREATE_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.DEFAULT_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.DELETE_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.IMPORT
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.LIST_KEYCHAINS
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.LOGIN_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.PKCS12
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.SET_KEY_PARTITION_LIST
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.UNLOCK_KEYCHAIN
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.USER
import com.vaticle.bazel.distribution.platform.jvm.AppleCodeSigner.Security.USR_BIN_CODESIGN
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Extensions.DYLIB
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Extensions.JAR
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Extensions.JNILIB
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Programs.CODESIGN
import com.vaticle.bazel.distribution.platform.jvm.ShellArgs.Programs.SECURITY
import org.zeroturnaround.exec.ProcessResult
import java.io.File
import java.io.FileInputStream
import java.nio.file.Files
import java.nio.file.Path
import java.security.KeyStore
import java.security.cert.Certificate
import java.security.cert.X509Certificate
import javax.naming.ldap.LdapName
import javax.naming.ldap.Rdn

class AppleCodeSigner(private val shell: Shell, private val macEntitlements: File, private val options: Options.AppleCodeSigning) {
    var initialised: Boolean = false
    lateinit var certSubject: String

    fun init() {
        deleteKeychain()
        createKeychain()
        setDefaultKeychain()
        unlockKeychain()
        importCodeSigningIdentity()
        makeCodeSigningIdentityAccessible()
        certSubject = findCertSubject()
        initialised = true
    }

    fun deleteKeychain() {
        val keychainListInfo = shell.execute(listOf(SECURITY, LIST_KEYCHAINS)).outputString()
        if (KEYCHAIN_NAME in keychainListInfo) shell.execute(listOf(SECURITY, DELETE_KEYCHAIN, KEYCHAIN_NAME))
    }

    private fun createKeychain() {
        shell.execute(
            Shell.Command(
                Shell.Command.arg(SECURITY), Shell.Command.arg(CREATE_KEYCHAIN),
                Shell.Command.arg("-p"), Shell.Command.arg(KEYCHAIN_PASSWORD, printable = false),
                Shell.Command.arg(KEYCHAIN_NAME)
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
                Shell.Command.arg(SECURITY), Shell.Command.arg(UNLOCK_KEYCHAIN),
                Shell.Command.arg("-p"), Shell.Command.arg(KEYCHAIN_PASSWORD, printable = false),
                Shell.Command.arg(KEYCHAIN_NAME)
            )
        )
    }

    private fun importCodeSigningIdentity() {
        shell.execute(
            Shell.Command(
                Shell.Command.arg(SECURITY),
                Shell.Command.arg(IMPORT),
                Shell.Command.arg(options.cert.path),
                Shell.Command.arg("-k"),
                Shell.Command.arg(KEYCHAIN_NAME),
                Shell.Command.arg("-P"),
                Shell.Command.arg(options.certPassword, printable = false),
                Shell.Command.arg("-T"),
                Shell.Command.arg(USR_BIN_CODESIGN)
            )
        )
    }

    private fun makeCodeSigningIdentityAccessible() {
        shell.execute(
            Shell.Command(
                Shell.Command.arg(SECURITY), Shell.Command.arg(SET_KEY_PARTITION_LIST),
                Shell.Command.arg("-S"), Shell.Command.arg(KEY_PARTITION_LIST),
                Shell.Command.arg("-s"),
                Shell.Command.arg("-k"), Shell.Command.arg(KEYCHAIN_PASSWORD, printable = false),
                Shell.Command.arg(KEYCHAIN_NAME)
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

    fun signUnsignedNativeLibs(root: File) {
        // Some JARs contain unsigned `.jnilib` and `.dylib` files, which we can extract, sign and repackage
        for (jar in root.listFilesRecursively().filter {
            it.isFile && it.extension == JAR && it.name.matches(requireNotNull(options.deepSignJarsRegex))
        }) {
            val tmpPath = Path.of(TMP)
            val tmpDir: File = tmpPath.toFile()
            Files.createDirectory(tmpPath)
            shell.execute(listOf(ShellArgs.Programs.JAR, "xf", "../${jar.path}"), baseDir = tmpPath).outputString()

            val nativeLibs = tmpDir.listFilesRecursively().filter { it.extension in listOf(JNILIB, DYLIB) }
            if (nativeLibs.isNotEmpty()) {
                nativeLibs.forEach { signFile(file = it) }
                jar.setWritable(true)
                jar.delete()
                shell.execute(listOf(ShellArgs.Programs.JAR, "cMf", "../${jar.path}", "."), baseDir = tmpPath)
            }

            tmpDir.deleteRecursively()
        }
    }

    fun signFile(file: File) {
        file.setWritable(true)
        val signCommand: MutableList<String> = mutableListOf(
            CODESIGN, SIGN, certSubject,
            FORCE,
            ENTITLEMENTS, macEntitlements.path,
            OPTIONS, Codesign.RUNTIME,
            TIMESTAMP,
            KEYCHAIN, KEYCHAIN_NAME,
            file.path)
        if (JVMPlatformAssembler.verbose) signCommand += "-vvv"
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

    private object Codesign {
        const val RUNTIME = "runtime"

        object Args {
            const val ENTITLEMENTS = "--entitlements"
            const val FORCE = "-f"
            const val KEYCHAIN = "--keychain"
            const val OPTIONS = "--options"
            const val SIGN = "-s"
            const val STRICT = "--strict"
            const val TIMESTAMP = "--timestamp"
            const val VERIFY = "-v"
        }
    }

    private object Paths {
        const val CONTENTS = "Contents"
        const val MAC_OS = "MacOS"
        const val RUNTIME = "runtime"
        const val TMP = "tmp"
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
