package com.typedb.bazel.distribution.common.macsigning

import com.typedb.bazel.distribution.common.Logging
import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.shell.Shell
import java.io.File
import java.nio.file.Files

class MacSigningTool(private val params: MacSigningCommandLineParams) {
    private val shell = Shell(Logging.Logger(logLevel = if (params.verbose) LogLevel.DEBUG else LogLevel.ERROR), params.verbose)

    fun run() {
        Keychain.checkUnlocked(shell, params.keychainName)
        val workDir = Files.createTempDirectory("macsigning").toFile()
        val srcDir = extractArchive(workDir)
        try {
            signBinaries(srcDir)
            val intermediatePkg = File(workDir, params.intermediatePkgName)
            Pkgbuild.run(shell, params.identifier, srcDir, params.installLocation, intermediatePkg)
            val packedPkg = File(workDir, "packed.pkg")
            Productbuild.run(shell, params.distributionXml, workDir, packedPkg)
            val signedPkg = File(workDir, "signed.pkg")
            Productsign.sign(shell, params.verbose, params.installerCertSubject, packedPkg, signedPkg)
            if (params.notarize) {
                Notarytool.submit(shell, params.verbose, params.keychainName, params.appleId, params.appleTeamId, signedPkg)
                Notarytool.staple(shell, params.verbose, signedPkg)
            }
            signedPkg.copyTo(params.output, overwrite = true)
        } finally {
            workDir.deleteRecursively()
        }
    }

    private fun extractArchive(workDir: File): File {
        val srcDir = File(workDir, "src")
        srcDir.mkdirs()
        shell.execute(listOf("tar", "-xf", params.src.absolutePath, "-C", srcDir.absolutePath, "--strip-components=1"))
        return srcDir
    }

    private fun signBinaries(srcDir: File) {
        for (relativePath in params.signBinaries) {
            Codesign.sign(shell, params.verbose, params.certSubject, params.keychainName, File(srcDir, relativePath), params.entitlements)
        }
    }

    private object Keychain {
        fun checkUnlocked(shell: Shell, name: String) {
            try {
                shell.execute(listOf("security", "show-keychain-info", name))
            } catch (e: Exception) {
                throw IllegalStateException(
                    "Signing keychain '$name' is not available or is locked. " +
                    "Run the keychain setup first: bazel run @typedb_bazel_distribution//common/macsigning:keychain-setup -- --signing_identities=<path/to/identities.p12> --keychain_name=$name",
                    e
                )
            }
        }
    }

    private object Codesign {
        fun sign(shell: Shell, verbose: Boolean, certSubject: String, keychainName: String, file: File, entitlements: File?) {
            file.setWritable(true)
            val command: MutableList<String> = mutableListOf("codesign", "-s", certSubject, "-f")
            if (entitlements != null) command += listOf("--entitlements", entitlements.path)
            command += listOf("--options", "runtime", "--timestamp", "--keychain", keychainName, file.path)
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

    private object Pkgbuild {
        fun run(shell: Shell, identifier: String, rootDir: File, installLocation: String, output: File) {
            shell.execute(listOf(
                "pkgbuild",
                "--identifier", identifier,
                "--root", rootDir.absolutePath,
                "--install-location", installLocation,
                output.absolutePath,
            ))
        }
    }

    private object Productbuild {
        fun run(shell: Shell, distributionXml: File, packageDir: File, output: File) {
            shell.execute(listOf(
                "productbuild",
                "--distribution", distributionXml.absolutePath,
                "--package-path", packageDir.absolutePath,
                output.absolutePath,
            ))
        }
    }

    private object Notarytool {
        fun submit(shell: Shell, verbose: Boolean, keychainName: String, appleId: String, appleTeamId: String, file: File) {
            val appleIdPassword = retrieveSecret(shell, keychainName, appleId)
            shell.execute(Shell.Command(listOfNotNull(
                Shell.Command.arg("xcrun"), Shell.Command.arg("notarytool"), Shell.Command.arg("submit"),
                if (verbose) Shell.Command.arg("-v") else null,
                Shell.Command.arg("--apple-id"), Shell.Command.arg(appleId),
                Shell.Command.arg("--password"), Shell.Command.arg(appleIdPassword, printable = false),
                Shell.Command.arg("--team-id"), Shell.Command.arg(appleTeamId),
                Shell.Command.arg("--wait"), Shell.Command.arg("--timeout"), Shell.Command.arg("1h"),
                Shell.Command.arg(file.path)
            )))
        }

        private fun retrieveSecret(shell: Shell, keychainName: String, account: String): String =
            shell.execute(listOf("security", "find-generic-password", "-a", account, "-s", keychainName, "-w", keychainName))
                .outputString().trim()


        fun staple(shell: Shell, verbose: Boolean, file: File) {
            shell.execute(listOfNotNull("xcrun", "stapler", "staple", if (verbose) "-v" else null, file.path))
        }
    }
}
