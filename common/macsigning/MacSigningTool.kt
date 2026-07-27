package com.typedb.bazel.distribution.common.macsigning

import com.typedb.bazel.distribution.common.Logging
import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.shell.Shell
import java.io.File
import java.nio.file.Files
import java.time.Duration
import java.util.concurrent.TimeUnit

class MacSigningTool(private val params: MacSigningCommandLineParams) {
    private val shell = Shell(Logging.Logger(logLevel = if (params.verbose) LogLevel.DEBUG else LogLevel.ERROR), params.verbose)

    fun run() {
        progress("Checking keychain '${params.keychainName}'...")
        Keychain.checkUnlocked(shell, params.keychainName)
        val workDir = Files.createTempDirectory("macsigning").toFile()
        progress("Extracting archive '${params.src.name}'...")
        val srcDir = extractArchive(workDir)
        try {
            signBinaries(srcDir)
            val intermediatePkg = File(workDir, params.intermediatePkgName)
            progress("Running pkgbuild...")
            Pkgbuild.run(shell, params.identifier, srcDir, params.installLocation, params.postinstallScript, intermediatePkg)
            val packedPkg = File(workDir, "packed.pkg")
            progress("Running productbuild...")
            Productbuild.run(shell, params.distributionXml, workDir, packedPkg)
            val signedPkg = File(workDir, "signed.pkg")
            progress("Running productsign...")
            Productsign.sign(shell, params.verbose, params.installerCertSubject, packedPkg, signedPkg)
            if (params.notarize) {
                progress("Submitting for notarization...")
                Notarytool.submit(shell, params.verbose, params.keychainName, params.appleId, params.appleTeamId, signedPkg)
                progress("Stapling notarization ticket...")
                Notarytool.staple(shell, params.verbose, signedPkg)
            }
            progress("Copying output to '${params.output}'...")
            signedPkg.copyTo(params.output, overwrite = true)
        } finally {
            workDir.deleteRecursively()
        }
    }

    private fun progress(message: String) {
        if (params.verbose) System.err.println(message)
    }

    private fun extractArchive(workDir: File): File {
        val srcDir = File(workDir, "src")
        srcDir.mkdirs()
        shell.execute(listOf("tar", "-xf", params.src.absolutePath, "-C", srcDir.absolutePath, "--strip-components=1"))
        return srcDir
    }

    private fun signBinaries(srcDir: File) {
        for (relativePath in params.signBinaries) {
            progress("Codesigning '$relativePath'...")
            Codesign.sign(shell, params.verbose, params.applicationCertSubject, params.keychainName, File(srcDir, relativePath), params.entitlements)
        }
    }

    private object Keychain {
        fun checkUnlocked(shell: Shell, name: String) {
            try {
                shell.execute(listOf("security", "show-keychain-info", name), timeout = Duration.ofSeconds(10))
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
            shell.execute(command, timeout = Duration.ofSeconds(10))
        }
    }

    private object Productsign {
        fun sign(shell: Shell, verbose: Boolean, installerCertSubject: String, inputPkg: File, outputPkg: File) {
            val command: MutableList<String> = mutableListOf("productsign")
            if (verbose) command += "-v"
            command += listOf("--sign", installerCertSubject, inputPkg.path, outputPkg.path)
            shell.execute(command, timeout = Duration.ofSeconds(10))
        }
    }

    private object Pkgbuild {
        fun run(shell: Shell, identifier: String, rootDir: File, installLocation: String, postinstallScript: File?, output: File) {
            val command = mutableListOf(
                "pkgbuild",
                "--identifier", identifier,
                "--root", rootDir.absolutePath,
                "--install-location", installLocation,
            )
            if (postinstallScript != null) {
                val scriptsDir = File(output.parentFile, "scripts").also { it.mkdirs() }
                postinstallScript.copyTo(File(scriptsDir, "postinstall"), overwrite = true)
                command += listOf("--scripts", scriptsDir.absolutePath)
            }
            command += output.absolutePath
            shell.execute(command, timeout = Duration.ofSeconds(10))
        }
    }

    private object Productbuild {
        fun run(shell: Shell, distributionXml: File, packageDir: File, output: File) {
            shell.execute(listOf(
                "productbuild",
                "--distribution", distributionXml.absolutePath,
                "--package-path", packageDir.absolutePath,
                output.absolutePath,
            ), timeout = Duration.ofSeconds(10)
            )
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
            )), timeout = Duration.ofSeconds(600))
        }

        private fun retrieveSecret(shell: Shell, keychainName: String, account: String): String =
            shell.execute(listOf("security", "find-generic-password", "-a", account, "-s", keychainName, "-w", keychainName), timeout = Duration.ofSeconds(10))
                .outputString().trim()


        fun staple(shell: Shell, verbose: Boolean, file: File) {
            shell.execute(listOfNotNull("xcrun", "stapler", "staple", if (verbose) "-v" else null, file.path), timeout = Duration.ofSeconds(10))
        }
    }
}
