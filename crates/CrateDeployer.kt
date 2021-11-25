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

import com.google.api.client.http.*
import com.google.api.client.http.javanet.NetHttpTransport
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import picocli.CommandLine.Parameters
import java.io.File
import java.util.concurrent.Callable
import kotlin.system.exitProcess
import java.nio.ByteBuffer
import java.nio.ByteOrder


enum class CrateRepoType {
    Snapshot,
    Release,
}

fun httpPut(url: String, token: String, content: ByteArray): HttpResponse {
    return NetHttpTransport()
        .createRequestFactory()
        .buildPutRequest(GenericUrl(url), ByteArrayContent("application/json", content))
        .setHeaders(
            HttpHeaders().setAuthorization(token)
        )
        .execute()
}


@Command(name = "crate-deployer", mixinStandardHelpOptions = true)
class CrateDeployer : Callable<Unit> {
    @Option(names = ["--crate"], required = true)
    lateinit var crate: File

    @Option(names = ["--metadata-json"], required = true)
    lateinit var metadataJson: File

    @Option(names = ["--snapshot-repo"], required = true)
    lateinit var snapshotRepo: String

    @Option(names = ["--release-repo"], required = true)
    lateinit var releaseRepo: String

    @Parameters(index = "0")
    lateinit var releaseMode: CrateRepoType

    private val repoUrl: String
        get() = when (releaseMode) {
            CrateRepoType.Snapshot -> snapshotRepo
            CrateRepoType.Release -> releaseRepo
        } + "/api/v1/crates/new"

    private val token = System.getenv("DEPLOY_CRATE_TOKEN") ?: throw RuntimeException(
        "token should be passed via DEPLOY_CRATE_TOKEN token"
    )

    override fun call() {
        val metadataJsonContent = metadataJson.readBytes()
        val crateContent = crate.readBytes()
        /*
         * Cargo repository expects a single-part body containing both metadata in JSON
         * and the actual crate in a tarball. Each part is prefixed with a
         * 32-bit little-endian length identifier.
         */
        val payload = ByteBuffer.allocate(4 + metadataJsonContent.size + 4 + crateContent.size)
            .order(ByteOrder.LITTLE_ENDIAN)
            .putInt(metadataJsonContent.size)
            .put(metadataJsonContent)
            .putInt(crateContent.size)
            .put(crateContent)
            .array()

        httpPut(repoUrl, token, payload)
    }
}

fun main(args: Array<String>): Unit =
    exitProcess(CommandLine(CrateDeployer()).setCaseInsensitiveEnumValuesAllowed(true).execute(*args))