package com.typedb.bazel.distribution.common.macsigning

import com.typedb.bazel.distribution.common.Logging
import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.shell.Shell
import java.io.File

class KeychainSetupTool(
    private val signingIdentities: File,
    private val keychainName: String,
    private val passwords: List<String>,
    private val signingIdentitiesPasswordEnv: String,
    private val partitionList: String,
    private val trustedApps: List<String>,
) {
    private val shell = Shell(Logging.Logger(logLevel = LogLevel.DEBUG), true)
    private val keychainPassword = java.util.UUID.randomUUID().toString()

    fun run() {
        delete()
        create()
        setDefault()
        unlock()
        importIdentity()
        makeAccessible()
        passwords.forEach { entry ->
            val (account, envVar) = entry.split(":", limit = 2)
            val secret = System.getenv(envVar) ?: error("Required environment variable $envVar is not set")
            storeSecret(account, secret)
        }
    }

    private fun delete() {
        val listed = shell.execute(listOf("security", "list-keychains")).outputString()
        if (keychainName in listed) shell.execute(listOf("security", "delete-keychain", keychainName))
    }

    private fun create() {
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("create-keychain"),
            Shell.Command.arg("-p"), Shell.Command.arg(keychainPassword, printable = false),
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
            Shell.Command.arg("-p"), Shell.Command.arg(keychainPassword, printable = false),
            Shell.Command.arg(keychainName),
        ))
    }

    private fun importIdentity() {
        val certPassword = if (signingIdentitiesPasswordEnv.isNotEmpty())
            System.getenv(signingIdentitiesPasswordEnv) ?: error("Environment variable $signingIdentitiesPasswordEnv is not set")
        else ""
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("import"),
            Shell.Command.arg(signingIdentities.path),
            Shell.Command.arg("-k"), Shell.Command.arg(keychainName),
            Shell.Command.arg("-P"), Shell.Command.arg(certPassword, printable = false),
        ) + trustedApps.flatMap { listOf(Shell.Command.arg("-T"), Shell.Command.arg(it)) }))
    }

    private fun makeAccessible() {
        shell.execute(Shell.Command(
            Shell.Command.arg("security"), Shell.Command.arg("set-key-partition-list"),
            Shell.Command.arg("-S"), Shell.Command.arg(partitionList),
            Shell.Command.arg("-s"),
            Shell.Command.arg("-k"), Shell.Command.arg(keychainPassword, printable = false),
            Shell.Command.arg(keychainName),
        ))
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

}
