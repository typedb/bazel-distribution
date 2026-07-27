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
            signer.use {
                it.init(params.cert, params.certPassword)
                signBinaries(srcDir)
                val intermediatePkg = File(workDir, intermediatePkgName)
                pkgbuild(srcDir, intermediatePkg)
                val packedPkg = File(workDir, "packed.pkg")
                productbuild(params.distributionXml, workDir, packedPkg)
                val signedPkg = File(workDir, "signed.pkg")
                it.productsign(installerCertSubject, packedPkg, signedPkg)
                if (notarize) {
                    requireNotarizationCredentials()
                    it.notarize(signedPkg, params.appleID!!, params.appleIDPassword!!, params.appleTeamID!!)
                    it.staple(signedPkg)
                }
                signedPkg.copyTo(params.output, overwrite = true)
            }
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
        val entitlements = entitlementsPath?.let { File(it) }
        for (relativePath in signBinaries) {
            signer.codesign(File(srcDir, relativePath), entitlements)
        }
    }

    private fun pkgbuild(rootDir: File, output: File) {
        shell.execute(listOf(
            Programs.PKGBUILD,
            PkgbuildArgs.IDENTIFIER, identifier,
            PkgbuildArgs.ROOT, rootDir.absolutePath,
            PkgbuildArgs.INSTALL_LOCATION, installLocation,
            output.absolutePath,
        ))
    }

    private fun productbuild(distributionXml: File, packageDir: File, output: File) {
        shell.execute(listOf(
            Programs.PRODUCTBUILD,
            ProductbuildArgs.DISTRIBUTION, distributionXml.absolutePath,
            ProductbuildArgs.PACKAGE_PATH, packageDir.absolutePath,
            output.absolutePath,
        ))
    }

    private fun requireNotarizationCredentials() {
        if (params.appleID.isNullOrBlank()) error("--apple_id is required when notarize=true")
        if (params.appleIDPassword.isNullOrBlank()) error("--apple_id_password is required when notarize=true")
        if (params.appleTeamID.isNullOrBlank()) error("--apple_team_id is required when notarize=true")
    }

    private object Programs {
        const val PKGBUILD = "pkgbuild"
        const val PRODUCTBUILD = "productbuild"
    }

    private object PkgbuildArgs {
        const val IDENTIFIER = "--identifier"
        const val INSTALL_LOCATION = "--install-location"
        const val ROOT = "--root"
    }

    private object ProductbuildArgs {
        const val DISTRIBUTION = "--distribution"
        const val PACKAGE_PATH = "--package-path"
    }

    object Keys {
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
