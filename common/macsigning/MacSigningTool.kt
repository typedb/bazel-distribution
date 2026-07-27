package com.typedb.bazel.distribution.common.macsigning

import com.typedb.bazel.distribution.common.Logging
import com.typedb.bazel.distribution.common.Logging.LogLevel
import com.typedb.bazel.distribution.common.shell.Shell
import java.io.File
import java.nio.file.Files

class MacSigningTool(private val params: MacSigningCommandLineParams) {
    private val shell = Shell(Logging.Logger(logLevel = if (params.verbose) LogLevel.DEBUG else LogLevel.ERROR), params.verbose)
    private val signer = AppleSigner(shell = shell, verbose = params.verbose)

    fun run() {
        val workDir = Files.createTempDirectory("macsigning").toFile()
        val srcDir = extractArchive(workDir)
        try {
            signer.init(listOf(params.signingIdentities to requireEnv(Env.SIGNING_IDENTITIES_PASSWORD)))
            signBinaries(srcDir)
            val intermediatePkg = File(workDir, params.intermediatePkgName)
            pkgbuild(srcDir, intermediatePkg)
            val packedPkg = File(workDir, "packed.pkg")
            productbuild(params.distributionXml, workDir, packedPkg)
            val signedPkg = File(workDir, "signed.pkg")
            signer.productsign(params.installerCertSubject, packedPkg, signedPkg)
            if (params.notarize) {
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
        for (relativePath in params.signBinaries) {
            signer.codesign(params.certSubject, File(srcDir, relativePath), params.entitlements)
        }
    }

    private fun pkgbuild(rootDir: File, output: File) {
        shell.execute(listOf(
            "pkgbuild",
            "--identifier", params.identifier,
            "--root", rootDir.absolutePath,
            "--install-location", params.installLocation,
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
        const val SIGNING_IDENTITIES_PASSWORD = "APPLE_SIGNING_IDENTITIES_PASSWORD"
        const val APPLE_ID = "APPLE_ID"
        const val APPLE_ID_PASSWORD = "APPLE_ID_PASSWORD"
        const val APPLE_TEAM_ID = "APPLE_TEAM_ID"
    }
}
