package com.vaticle.bazel.distribution.npm.deploy

import com.vaticle.bazel.distribution.npm.deploy.Options.CommandLineParams.NPM_PATH
import com.vaticle.bazel.distribution.npm.deploy.Options.CommandLineParams.RELEASE_REPO
import com.vaticle.bazel.distribution.npm.deploy.Options.CommandLineParams.SNAPSHOT_REPO
import com.vaticle.bazel.distribution.npm.deploy.Options.Env.DEPLOY_NPM_TOKEN
import com.vaticle.bazel.distribution.npm.deploy.Options.RepositoryType.RELEASE
import com.vaticle.bazel.distribution.npm.deploy.Options.RepositoryType.SNAPSHOT
import picocli.CommandLine

class Options {
    @CommandLine.Option(names = [NPM_PATH], required = true)
    lateinit var npmPath: String

    @CommandLine.Option(names = [SNAPSHOT_REPO], required = true)
    private lateinit var snapshotRepo: String

    @CommandLine.Option(names = [RELEASE_REPO], required = true)
    private lateinit var releaseRepo: String

    @CommandLine.Parameters
    private lateinit var params: List<String>

    val registryURL: String
        get() {
            if (params.isEmpty() || params[0].isBlank()) {
                throw IllegalArgumentException("Missing required positional argument: <${RepositoryType.allValuesString}>")
            }
            return when (RepositoryType.of(params[0])) {
                SNAPSHOT -> snapshotRepo
                RELEASE -> releaseRepo
            }
        }

    val npmToken: String
        get() {
            return System.getenv(DEPLOY_NPM_TOKEN)
                ?: throw IllegalArgumentException("token should be passed via \$${DEPLOY_NPM_TOKEN} env variable")
        }

    companion object {
        fun of(args: Array<String>): Options {
            val cliList: List<CommandLine> = CommandLine(Options()).parseArgs(*args).asCommandLineList()
            assert(cliList.size == 1)
            return cliList[0].getCommand()
        }
    }

    private enum class RepositoryType(val displayName: String) {
        SNAPSHOT("snapshot"),
        RELEASE("release");

        companion object {
            val allValuesString = values().joinToString("|") { it.displayName }

            fun of(displayName: String): RepositoryType {
                return values().find { it.displayName == displayName }
                    ?: throw IllegalArgumentException("Invalid repo type: '$displayName' (valid values are <$allValuesString>)")
            }
        }
    }

    object CommandLineParams {
        const val NPM_PATH = "--npm-path"
        const val RELEASE_REPO = "--release-repo"
        const val SNAPSHOT_REPO = "--snapshot-repo"
    }

    object Env {
        const val DEPLOY_NPM_TOKEN = "DEPLOY_NPM_TOKEN"
    }
}
