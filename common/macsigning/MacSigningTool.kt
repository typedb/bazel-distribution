package com.typedb.bazel.distribution.common.macsigning

import com.typedb.bazel.distribution.common.Logging
import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.shell.Shell
import com.typedb.bazel.distribution.common.util.PropertiesUtil.getBooleanOrDefault
import com.typedb.bazel.distribution.common.util.PropertiesUtil.getStringOrNull
import com.typedb.bazel.distribution.common.util.PropertiesUtil.requireString
import java.io.File
import java.io.FileInputStream
import java.nio.file.Files
import java.util.Properties

class MacSigningTool(private val params: MacSigningCommandLineParams) {
    private val props = Properties().apply { load(FileInputStream(params.configFile)) }
    private val verbose = props.getBooleanOrDefault(Keys.VERBOSE, defaultValue = false)
    private val shell = Shell(Logging.Logger(logLevel = if (verbose) LogLevel.DEBUG else LogLevel.ERROR), verbose)
    private val notarize = props.getBooleanOrDefault(Keys.NOTARIZE, defaultValue = false)
    private val identifier = props.requireString(Keys.IDENTIFIER)
    private val installLocation = props.requireString(Keys.INSTALL_LOCATION)
    private val certSubject = props.requireString(Keys.CERT_SUBJECT)
    private val installerCertSubject = props.requireString(Keys.INSTALLER_CERT_SUBJECT)
    private val intermediatePkgName = props.requireString(Keys.INTERMEDIATE_PKG_NAME)
    private val signBinaries = props.getStringOrNull(Keys.SIGN_BINARIES)
        ?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList()
    private val entitlementsPath = props.getStringOrNull(Keys.ENTITLEMENTS)

    private val signer = AppleSigner(shell = shell, verbose = verbose)

    fun run() {
        val workDir = Files.createTempDirectory("macsigning").toFile()
        val srcDir = extractArchive(workDir)
        try {
            signer.init(params.cert, requireEnv(Env.CERT_PASSWORD), certSubject, params.installerCert, requireEnv(Env.INSTALLER_CERT_PASSWORD), installerCertSubject)
            signBinaries(srcDir)
            val intermediatePkg = File(workDir, intermediatePkgName)
            pkgbuild(srcDir, intermediatePkg)
            val packedPkg = File(workDir, "packed.pkg")
            productbuild(params.distributionXml, workDir, packedPkg)
            val signedPkg = File(workDir, "signed.pkg")
            signer.productsign(installerCertSubject, packedPkg, signedPkg)
            if (notarize) {
                signer.notarize(signedPkg, requireEnv(Env.APPLE_ID), requireEnv(Env.APPLE_ID_PASSWORD), requireEnv(Env.APPLE_TEAM_ID))
                signer.staple(signedPkg)
            }
            signedPkg.copyTo(params.output, overwrite = true)
        } finally {
            signer.close()
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
        val entitlements = entitlementsPath?.let { File(it) }
        for (relativePath in signBinaries) {
            signer.codesign(certSubject, File(srcDir, relativePath), entitlements)
        }
    }

    private fun pkgbuild(rootDir: File, output: File) {
        shell.execute(listOf(
            "pkgbuild",
            "--identifier", identifier,
            "--root", rootDir.absolutePath,
            "--install-location", installLocation,
            output.absolutePath,
        ))
    }

    private fun productbuild(distributionXml: File, packageDir: File, output: File) {
        shell.execute(listOf(
            "productbuild",
            "--distribution", distributionXml.absolutePath,
            "--package-path", packageDir.absolutePath,
            output.absolutePath,
        ))
    }

    private fun requireEnv(name: String): String =
        System.getenv(name) ?: error("Required environment variable $name is not set")

    private object Env {
        const val CERT_PASSWORD = "APPLE_CODE_SIGNING_CERT_PASSWORD"
        const val INSTALLER_CERT_PASSWORD = "APPLE_INSTALLER_CERT_PASSWORD"
        const val APPLE_ID = "APPLE_ID"
        const val APPLE_ID_PASSWORD = "APPLE_ID_PASSWORD"
        const val APPLE_TEAM_ID = "APPLE_TEAM_ID"
    }

    object Keys {
        const val CERT_SUBJECT = "certSubject"
        const val ENTITLEMENTS = "entitlements"
        const val IDENTIFIER = "identifier"
        const val INSTALL_LOCATION = "installLocation"
        const val INSTALLER_CERT_SUBJECT = "installerCertSubject"
        const val INTERMEDIATE_PKG_NAME = "intermediatePkgName"
        const val NOTARIZE = "notarize"
        const val SIGN_BINARIES = "signBinaries"
        const val VERBOSE = "verbose"
    }
}
