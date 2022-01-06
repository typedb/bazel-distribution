/*
 * Copyright (C) 2021 Vaticle
 *
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

package com.vaticle.bazel.distribution.npm

import com.vaticle.bazel.distribution.common.Logging.Logger
import com.vaticle.bazel.distribution.common.Logging.LogLevel.DEBUG
import com.vaticle.bazel.distribution.common.OS.MAC
import com.vaticle.bazel.distribution.common.OS.LINUX
import com.vaticle.bazel.distribution.common.shell.Shell
import com.vaticle.bazel.distribution.common.util.SystemUtil.currentOS
import com.vaticle.bazel.distribution.npm.Deployer.CommandLineParams.Keys.NPM_PATH
import com.vaticle.bazel.distribution.npm.Deployer.CommandLineParams.Keys.RELEASE_REPO
import com.vaticle.bazel.distribution.npm.Deployer.CommandLineParams.Keys.SNAPSHOT_REPO
import com.vaticle.bazel.distribution.npm.Deployer.Env.DEPLOY_NPM_TOKEN
import com.vaticle.bazel.distribution.npm.Deployer.Env.PATH
import com.vaticle.bazel.distribution.npm.Deployer.Options.RepositoryType.*
import picocli.CommandLine
import java.nio.file.Files
import java.nio.file.Path

class Deployer(options: Options) {
    private val logger = Logger(logLevel = DEBUG)
    private val npmPath = options.npmPath
    private val registryURL = options.registryURL

    fun deploy() {
        configureAuthToken()
        publishPackage()
    }

    private fun configureAuthToken() {
        val npmToken = System.getenv(DEPLOY_NPM_TOKEN)
            ?: throw IllegalArgumentException("token should be passed via \$$DEPLOY_NPM_TOKEN env variable")
        Files.writeString(Path.of(".npmrc"), "//$registryURL:_authToken=$npmToken")
    }

    private fun publishPackage() {
        Shell(logger = logger, verbose = true).execute(
            command = listOf("npm", "publish", "--registry=$registryURL", "deploy_npm.tgz"),
            env = mapOf(PATH to pathEnv()))
    }

    private fun pathEnv(): String {
        val commonPaths = listOf(realPath(npmPath).parent)
        val otherPaths = when (currentOS) {
            MAC, LINUX -> listOf("/usr/bin", "/bin/")
            else -> listOf()
        }
        return (commonPaths + otherPaths).joinToString(":")
    }

    private fun realPath(path: String): Path {
        val pathObj = Path.of(path)
        return when (Files.exists(pathObj)) {
            true -> pathObj.toRealPath()
            false -> pathObj
        }
    }

    data class Options(val npmPath: String, val registryURL: String) {
        companion object {
            fun of(commandLineParams: CommandLineParams): Options {
                if (commandLineParams.params.isEmpty() || commandLineParams.params[0].isBlank()) {
                    throw IllegalArgumentException("Missing required positional argument: <${RepositoryType.allValuesString}>")
                }
                val registryURL = when (RepositoryType.of(commandLineParams.params[0])) {
                    SNAPSHOT -> commandLineParams.snapshotRepo
                    RELEASE -> commandLineParams.releaseRepo
                }
                return Options(commandLineParams.npmPath, registryURL)
            }
        }

        enum class RepositoryType(val displayName: String) {
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
    }

    class CommandLineParams {
        @CommandLine.Option(names = [NPM_PATH], required = true)
        lateinit var npmPath: String

        @CommandLine.Option(names = [SNAPSHOT_REPO], required = true)
        lateinit var snapshotRepo: String

        @CommandLine.Option(names = [RELEASE_REPO], required = true)
        lateinit var releaseRepo: String

        @CommandLine.Parameters
        lateinit var params: List<String>

        object Keys {
            const val NPM_PATH = "--npm_path"
            const val RELEASE_REPO = "--release_repo"
            const val SNAPSHOT_REPO = "--snapshot_repo"
        }
    }

    object Env {
        const val DEPLOY_NPM_TOKEN = "DEPLOY_NPM_TOKEN"
        const val PATH = "PATH"
    }
}
