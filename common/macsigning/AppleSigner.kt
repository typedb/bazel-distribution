package com.typedb.bazel.distribution.common.macsigning

import com.typedb.bazel.distribution.common.shell.Shell
import java.io.File

class AppleSigner(
    private val shell: Shell,
    private val verbose: Boolean,
) : AutoCloseable {
    fun init(certs: List<Pair<File, String>>) {
        val (firstCert, firstPassword) = certs.first()
        Keychain.delete(shell)
        Keychain.create(shell, firstPassword)
        Keychain.setDefault(shell)
        Keychain.unlock(shell, firstPassword)
        certs.forEach { (cert, password) ->
            Keychain.importIdentity(shell, cert, password, "/usr/bin/codesign", "/usr/bin/productsign")
        }
        Keychain.makeAccessible(shell, firstPassword)
    }

    override fun close() = Keychain.delete(shell)

    fun codesign(certSubject: String, file: File, entitlements: File? = null) = Codesign.sign(shell, verbose, certSubject, file, entitlements)
    fun productsign(installerCertSubject: String, inputPkg: File, outputPkg: File) = Productsign.sign(shell, verbose, installerCertSubject, inputPkg, outputPkg)
    fun notarize(file: File, appleID: String, appleIDPassword: String, appleTeamID: String) = Notarytool.submit(shell, verbose, appleID, appleIDPassword, appleTeamID, file)
    fun staple(file: File) = Notarytool.staple(shell, verbose, file)

    private object Keychain {
        val NAME = "macsigning-${java.util.UUID.randomUUID()}.keychain"
        val PASSWORD = java.util.UUID.randomUUID().toString()

        fun delete(shell: Shell) {
            val keychainListInfo = shell.execute(listOf("security", "list-keychains")).outputString()
            if (NAME in keychainListInfo) shell.execute(listOf("security", "delete-keychain", NAME))
        }

        fun create(shell: Shell, certPassword: String) {
            shell.execute(Shell.Command(
                Shell.Command.arg("security"), Shell.Command.arg("create-keychain"),
                Shell.Command.arg("-p"), Shell.Command.arg(PASSWORD, printable = false),
                Shell.Command.arg(NAME)
            ))
        }

        fun setDefault(shell: Shell) {
            shell.execute(listOf("security", "default-keychain", "-s", NAME))
            shell.execute(listOf("security", "list-keychains", "-d", "user", "-s", "login.keychain", NAME))
        }

        fun unlock(shell: Shell, certPassword: String) {
            shell.execute(Shell.Command(
                Shell.Command.arg("security"), Shell.Command.arg("unlock-keychain"),
                Shell.Command.arg("-p"), Shell.Command.arg(certPassword, printable = false),
                Shell.Command.arg(NAME)
            ))
        }

        fun importIdentity(shell: Shell, cert: File, certPassword: String, vararg trustedApps: String) {
            shell.execute(Shell.Command(listOfNotNull(
                Shell.Command.arg("security"), Shell.Command.arg("import"),
                Shell.Command.arg(cert.path),
                Shell.Command.arg("-k"), Shell.Command.arg(NAME),
                Shell.Command.arg("-P"), Shell.Command.arg(certPassword, printable = false),
            ) + trustedApps.flatMap { listOf(Shell.Command.arg("-T"), Shell.Command.arg(it)) }))
        }

        fun makeAccessible(shell: Shell, certPassword: String) {
            shell.execute(Shell.Command(
                Shell.Command.arg("security"), Shell.Command.arg("set-key-partition-list"),
                Shell.Command.arg("-S"), Shell.Command.arg("apple-tool:,apple:,codesign:"),
                Shell.Command.arg("-s"),
                Shell.Command.arg("-k"), Shell.Command.arg(PASSWORD, printable = false),
                Shell.Command.arg(NAME)
            ))
        }
    }

    private object Codesign {
        fun sign(shell: Shell, verbose: Boolean, certSubject: String, file: File, entitlements: File?) {
            file.setWritable(true)
            val command: MutableList<String> = mutableListOf("codesign", "-s", certSubject, "-f")
            if (entitlements != null) command += listOf("--entitlements", entitlements.path)
            command += listOf("--options", "runtime", "--timestamp", "--keychain", Keychain.NAME, file.path)
            if (verbose) command += "-vvv"
            shell.execute(command)
        }
    }

    private object Productsign {
        fun sign(shell: Shell, verbose: Boolean, installerCertSubject: String, inputPkg: File, outputPkg: File) {
            val command: MutableList<String> = mutableListOf("productsign")
            if (verbose) command += "-v"
            command += listOf("--sign", installerCertSubject, inputPkg.path, outputPkg.path)
            shell.execute(command)
        }
    }

    private object Notarytool {
        fun submit(shell: Shell, verbose: Boolean, appleID: String, appleIDPassword: String, appleTeamID: String, file: File) {
            shell.execute(Shell.Command(listOfNotNull(
                Shell.Command.arg("xcrun"), Shell.Command.arg("notarytool"), Shell.Command.arg("submit"),
                if (verbose) Shell.Command.arg("-v") else null,
                Shell.Command.arg("--apple-id"), Shell.Command.arg(appleID),
                Shell.Command.arg("--password"), Shell.Command.arg(appleIDPassword, printable = false),
                Shell.Command.arg("--team-id"), Shell.Command.arg(appleTeamID, printable = false),
                Shell.Command.arg("--wait"), Shell.Command.arg("--timeout"), Shell.Command.arg("1h"),
                Shell.Command.arg(file.path)
            )))
        }

        fun staple(shell: Shell, verbose: Boolean, file: File) {
            shell.execute(listOfNotNull("xcrun", "stapler", "staple", if (verbose) "-v" else null, file.path))
        }
    }
}
