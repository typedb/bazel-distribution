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

package com.vaticle.bazeldistribution.crates

import com.eclipsesource.json.Json
import com.eclipsesource.json.JsonArray
import com.eclipsesource.json.JsonObject
import com.electronwill.nightconfig.core.Config
import com.electronwill.nightconfig.toml.TomlWriter
import org.apache.commons.compress.archivers.tar.TarArchiveEntry
import org.apache.commons.compress.archivers.tar.TarArchiveOutputStream
import org.apache.commons.compress.utils.IOUtils
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import java.io.BufferedOutputStream
import java.io.ByteArrayInputStream
import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.concurrent.Callable
import java.util.zip.GZIPOutputStream
import kotlin.system.exitProcess


@Command(name = "crate-assembler", mixinStandardHelpOptions = true)
class CrateAssembler : Callable<Unit> {
    @Option(names = ["--srcs"])
    lateinit var srcs: String
    private val srcsList: Array<File>
        get() = if (srcs.isEmpty()) emptyArray() else srcs.split(";").map(::File).toTypedArray()

    @Option(names = ["--deps"])
    lateinit var deps: String
    private val depsList: Array<String>
        get() = if (deps.isEmpty()) emptyArray() else deps.split(";").toTypedArray()

    @Option(names = ["--output-crate"], required = true)
    lateinit var outputCrateFile: File

    @Option(names = ["--output-metadata-json"], required = true)
    lateinit var outputMetadataFile: File

    @Option(names = ["--root"], required = true)
    lateinit var crateRoot: Path

    @Option(names = ["--edition"], required = true)
    lateinit var edition: String

    @Option(names = ["--name"], required = true)
    lateinit var name: String

    @Option(names = ["--authors"], split = ";")
    lateinit var authors: Array<String>

    @Option(names = ["--description"], required = false)
    lateinit var description: String

    @Option(names = ["--documentation"], required = false)
    lateinit var documentation: String

    @Option(names = ["--homepage"], required = false)
    lateinit var homepage: String

    @Option(names = ["--keywords"], split = ";")
    lateinit var keywords: Array<String>

    @Option(names = ["--categories"], split = ";")
    lateinit var categories: Array<String>

    @Option(names = ["--license"], required = false)
    lateinit var license: String

    @Option(names = ["--repository"], required = false)
    lateinit var repository: String

    @Option(names = ["--readme-file"])
    var readmeFile: File? = null

    @Option(names = ["--version-file"])
    lateinit var versionFile: File

    override fun call() {
        writeCrateArchive()
        writeMetadataFile()
    }

    private fun writeCrateArchive() {
        val prefix = "$name-${versionFile.readText()}"
        outputCrateFile.outputStream().use { fos ->
            BufferedOutputStream(fos).use { bos ->
                GZIPOutputStream(bos).use { gzos ->
                    TarArchiveOutputStream(gzos).use { tarOutputStream ->
                        val libraryRoot = crateRoot.parent.toAbsolutePath()
                        srcsList.forEach { file ->
                            val sourceEntry = TarArchiveEntry(
                                file,
                                "$prefix/src/" + libraryRoot.relativize(file.toPath().toAbsolutePath()).toString()
                            )
                            tarOutputStream.putArchiveEntry(sourceEntry)
                            IOUtils.copy(file, tarOutputStream)
                            tarOutputStream.closeArchiveEntry()
                        }

                        val cargoToml = TarArchiveEntry("$prefix/Cargo.toml")
                        val cargoTomlText = generateCargoToml().toByteArray()
                        cargoToml.size = cargoTomlText.size.toLong()
                        tarOutputStream.putArchiveEntry(cargoToml)

                        IOUtils.copy(ByteArrayInputStream(cargoTomlText), tarOutputStream)
                        tarOutputStream.closeArchiveEntry()
                    }
                }
            }
        }
    }

    private fun generateCargoToml(): String {
        val cargoToml = Config.inMemory()
        cargoToml.createSubConfig().apply {
            cargoToml.set<Config>("package", this)
            set<String>("name", name)
            set<String>("edition", edition)
            set<String>("version", versionFile.readText())
            set<Array<String>>("authors", authors.filter { it != "" })
            set<String>("homepage", homepage)
            set<String>("repository", repository)
            set<String>("documentation", documentation)
            set<String>("description", description)
            set<String>("readme", readmeFile?.toPath()?.fileName?.toString() ?: "")
        }
        cargoToml.createSubConfig().apply {
            cargoToml.set<Config>("dependencies", this)
            depsList.associate { it.split("=").let { (dep, ver) -> dep to ver } }.forEach { (dep, ver) ->
                set<String>(dep, ver)
            }
        }
        return TomlWriter().writeToString(cargoToml.unmodifiable())
    }

    private fun writeMetadataFile() {
        outputMetadataFile.outputStream().use {
            it.write(constructMetadata().toByteArray(StandardCharsets.UTF_8))
        }
    }

    private fun constructMetadata(): String {
        return JsonObject().apply {
            set("name", name)
            set("vers", versionFile.readText())
            val depsArray = JsonArray()
            for (dep in depsList) {
                val (depName, depVer) = dep.split("=")
                val obj = JsonObject()
                obj.set("optional", false)
                obj.set("default_features", false)
                obj.set("name", depName)
                obj.set("features", JsonArray())
                obj.set("version_req", depVer)
                obj.set("target", Json.NULL)
                obj.set("kind", "normal")
                obj.set("registry", "https://github.com/rust-lang/crates.io-index")
                depsArray.add(obj)
            }
            set("deps", depsArray)
            set("features", JsonObject())
            set("authors", JsonArray().apply { authors.filter { it != "" }.forEach { add(it) } })
            set("description", description)
            set("documentation", documentation)
            set("homepage", homepage)
            readmeFile?.let {
                set("readme", readmeFile?.readText())
                set("readme_file", it.toPath().fileName.toString())
            } ?: run {
                set("readme", Json.NULL)
                set("readme_file", Json.NULL)
            }
            set("keywords", JsonArray().apply { keywords.filter { it != "" }.forEach { add(it) } })
            set("categories", JsonArray().apply { categories.filter { it != "" }.forEach { add(it) } })
            set("license", license)
            set("license_file", Json.NULL)
            set("repository", repository)
            // https://doc.rust-lang.org/cargo/reference/manifest.html#the-badges-section
            // as docs state all badges should go to README, so it's safe to keep it empty
            set("badges", JsonObject())
            set("links", Json.NULL)
        }.toString()
    }
}

fun main(args: Array<String>): Unit = exitProcess(CommandLine(CrateAssembler()).execute(*args))
