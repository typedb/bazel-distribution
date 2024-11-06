/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package com.vaticle.bazel.distribution.npm.deploy

import com.vaticle.bazel.distribution.npm.deploy.Options.CommandLineParams.NPM_PATH
import com.vaticle.bazel.distribution.npm.deploy.Options.CommandLineParams.RELEASE_REPO
import com.vaticle.bazel.distribution.npm.deploy.Options.CommandLineParams.SNAPSHOT_REPO
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

    val npmToken: String?
        get() {
            return System.getenv().get(Env.DEPLOY_NPM_TOKEN);
        }

    val npmUsername: String?
        get() {
            return System.getenv().get(Env.DEPLOY_NPM_USERNAME)
        }

    val npmPassword: String?
        get() {
            return System.getenv().get(Env.DEPLOY_NPM_PASSWORD)
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
        const val DEPLOY_NPM_USERNAME = "DEPLOY_NPM_USERNAME"
        const val DEPLOY_NPM_PASSWORD = "DEPLOY_NPM_PASSWORD"
    }
}
