package com.typedb.bazel.distribution.common.macsigning

import com.typedb.bazel.distribution.common.Logging
import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.shell.Shell
import java.io.File

class KeychainSetupTool(
    private val signingIdentities: File,
    private val keychainName: String,
    private val appleId: String?,
    private val appleTeamId: String?,
) {
    private val shell = Shell(Logging.Logger(logLevel = LogLevel.DEBUG), true)
    private val password = java.util.UUID.randomUUID().toString()

    fun run() {
        delete()
        create()
        setDefault()
        unlock()
        importIdentity()
        makeAccessible()
        if (appleId != null && appleTeamId != null) storeNotarizationCredentials(appleId, appleTeamId)
    }

    private fun delete() {
        val listed = shell.execute(listOf("security", "list-keychains")).outputString()
        if (keychainName in listed) shell.execute(listOf("security", "delete-keychain", keychainName))
    }

    private fun create() {
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("create-keychain"),
            Shell.Command.arg("-p"), Shell.Command.arg(password, printable = false),
            Shell.Command.arg(keychainName),
        ))
    }

    private fun setDefault() {
        shell.execute(listOf("security", "default-keychain", "-s", keychainName))
        shell.execute(listOf("security", "list-keychains", "-d", "user", "-s", "login.keychain", keychainName))
    }

    private fun unlock() {
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("unlock-keychain"),
            Shell.Command.arg("-p"), Shell.Command.arg(password, printable = false),
            Shell.Command.arg(keychainName),
        ))
    }

    private fun importIdentity() {
        val certPassword = System.getenv(SIGNING_IDENTITIES_PASSWORD_ENV)
            ?: error("Required environment variable $SIGNING_IDENTITIES_PASSWORD_ENV is not set")
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("import"),
            Shell.Command.arg(signingIdentities.path),
            Shell.Command.arg("-k"), Shell.Command.arg(keychainName),
            Shell.Command.arg("-P"), Shell.Command.arg(certPassword, printable = false),
            Shell.Command.arg("-T"), Shell.Command.arg("/usr/bin/codesign"),
            Shell.Command.arg("-T"), Shell.Command.arg("/usr/bin/productsign"),
        ))
    }

    private fun makeAccessible() {
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("set-key-partition-list"),
            Shell.Command.arg("-S"), Shell.Command.arg("apple-tool:,apple:,codesign:"),
            Shell.Command.arg("-s"),
            Shell.Command.arg("-k"), Shell.Command.arg(password, printable = false),
            Shell.Command.arg(keychainName),
        ))
    }

    private fun storeNotarizationCredentials(appleId: String, appleTeamId: String) {
        val appleIdPassword = System.getenv(APPLE_ID_PASSWORD_ENV)
            ?: error("Required environment variable $APPLE_ID_PASSWORD_ENV is not set")
        storeSecret(appleId, appleIdPassword)
        storeSecret(ACCOUNT_APPLE_TEAM_ID, appleTeamId)
    }

    private fun storeSecret(account: String, value: String) {
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("add-generic-password"),
            Shell.Command.arg("-a"), Shell.Command.arg(account),
            Shell.Command.arg("-s"), Shell.Command.arg(keychainName),
            Shell.Command.arg("-w"), Shell.Command.arg(value, printable = false),
            Shell.Command.arg(keychainName),
        ))
    }

    companion object {
        const val SIGNING_IDENTITIES_PASSWORD_ENV = "APPLE_SIGNING_IDENTITIES_PASSWORD"
        const val APPLE_ID_PASSWORD_ENV = "APPLE_ID_PASSWORD"
        const val ACCOUNT_APPLE_TEAM_ID = "apple-team-id"
    }
}
