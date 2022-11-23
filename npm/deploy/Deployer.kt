/*
 * Copyright (C) 2022 Vaticle
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

package com.vaticle.bazel.distribution.npm.deploy

import com.vaticle.bazel.distribution.common.Logging.Logger
import com.vaticle.bazel.distribution.common.Logging.LogLevel.DEBUG
import com.vaticle.bazel.distribution.common.OS.MAC
import com.vaticle.bazel.distribution.common.OS.LINUX
import com.vaticle.bazel.distribution.common.shell.Shell
import com.vaticle.bazel.distribution.common.shell.Shell.Command.Companion.arg
import com.vaticle.bazel.distribution.common.util.SystemUtil.currentOS
import java.nio.file.Files
import java.nio.file.Path

class Deployer(private val options: Options) {
    private val logger = Logger(logLevel = DEBUG)

    fun deploy() {
        Shell(logger = logger, verbose = true).execute(
            command = Shell.Command(
                arg("npm"), arg("publish"), arg("--registry=${options.registryURL}"),
                arg("--${authParamFormattedURL(options.registryURL)}/:_authToken=${options.npmToken}", printable = false),
                arg("deploy_npm.tgz")),
            env = mapOf("PATH" to pathEnv()))
    }

    /**
     * Convert a registry URL to the format expected when passing it together with an auth token.
     *
     * ### Examples:
     * - https://registry.npmjs.org/ --> //registry.npmjs.org
     * - registry.npmjs.org --> //registry.npmjs.org
     */
    private fun authParamFormattedURL(url: String): String {
        return url.trimEnd('/').let { if (":" in it) it.split(":")[1] else "//$it" }
    }

    private fun pathEnv(): String {
        val commonPaths = listOf(realPath(options.npmPath).parent)
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
}
