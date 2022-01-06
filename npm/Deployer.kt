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
import com.vaticle.bazel.distribution.common.OS.WINDOWS
import com.vaticle.bazel.distribution.common.OS.MAC
import com.vaticle.bazel.distribution.common.OS.LINUX
import com.vaticle.bazel.distribution.common.shell.Shell
import com.vaticle.bazel.distribution.common.util.SystemUtil.currentOS
import com.vaticle.bazel.distribution.npm.Deployer.CommandLineParams.Keys.REGISTRY_URL
import com.vaticle.bazel.distribution.npm.Deployer.Env.DEPLOY_NPM_TOKEN
import com.vaticle.bazel.distribution.npm.Deployer.Env.PATH
import picocli.CommandLine
import java.nio.file.Files
import java.nio.file.Path

class Deployer(val options: CommandLineParams) {
    private val logger = Logger(logLevel = DEBUG)
    private val registryURL = options.registryURL

    fun deploy() {
        configureAuthToken()
        publishPackage()
    }

    private fun configureAuthToken() {
        val npmToken = System.getenv(DEPLOY_NPM_TOKEN)
        if (npmToken == null) println("token should be passed via \$$DEPLOY_NPM_TOKEN env variable")
        Files.writeString(Path.of(".npmrc"), "//$registryURL:_authToken=$npmToken")
    }

    private fun publishPackage() {
        Shell(logger = logger, verbose = true).execute(
            command = listOf("npm", "publish", "--registry=$registryURL", "deploy_npm.tgz"),
            env = mapOf(PATH to pathEnv()))
    }

    private fun pathEnv(): String {
        val commonPaths = listOf(Path.of("external/nodejs/bin/nodejs/bin/").toRealPath().toString())
        val nativePaths = when (currentOS) {
            WINDOWS -> listOf(Path.of("external/nodejs_windows_amd64/bin/").toRealPath().toString())
            MAC -> listOf("/usr/bin", "/bin/", Path.of("external/nodejs_darwin_amd64/bin/").toRealPath().toString())
            LINUX -> listOf("/usr/bin", "/bin/", Path.of("external/nodejs_linux_amd64/bin/").toRealPath().toString())
        }
        return (commonPaths + nativePaths).joinToString(separator = ":")
    }

    class CommandLineParams {
        @CommandLine.Option(names = [REGISTRY_URL], required = true)
        lateinit var registryURL: String

        object Keys {
            const val REGISTRY_URL = "--registry_url"
        }
    }

    object Env {
        const val DEPLOY_NPM_TOKEN = "DEPLOY_NPM_TOKEN"
        const val PATH = "PATH"
    }
}
