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

package com.vaticle.bazeldistribution.crates

import com.eclipsesource.json.Json
import com.eclipsesource.json.JsonObject
import com.electronwill.nightconfig.core.Config
import com.electronwill.nightconfig.toml.TomlParser
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

    @Option(names = ["--dep-features"])
    lateinit var depFeatures: String
    private val depFeaturesList: Array<String>
        get() = if (depFeatures.isEmpty()) emptyArray() else depFeatures.split(";").toTypedArray()

    @Option(names = ["--dep-workspaces"])
    lateinit var depWorkspaces: String
    private val depWorkspaceList: Array<String>
        get() = if (depWorkspaces.isEmpty()) emptyArray() else depWorkspaces.split(";").toTypedArray()

    @Option(names = ["--output-crate"], required = true)
    lateinit var outputCrateFile: File

//    @Option(names = ["--output-metadata-json"], required = true)
//    lateinit var outputMetadataFile: File

    @Option(names = ["--root"], required = true)
    lateinit var crateRoot: Path

    @Option(names = ["--edition"], required = true)
    lateinit var edition: String

    @Option(names = ["--name"], required = true)
    lateinit var name: String

    @Option(names = ["--authors"], split = ";")
    lateinit var authors: Array<String>

    @Option(names = ["--description"], required = true)
    lateinit var description: String

    @Option(names = ["--documentation"], required = false)
    var documentation: String? = null

    @Option(names = ["--homepage"], required = true)
    lateinit var homepage: String

    @Option(names = ["--keywords"], split = ";")
    lateinit var keywords: Array<String>

    @Option(names = ["--categories"], split = ";")
    lateinit var categories: Array<String>

    @Option(names = ["--license"], required = true)
    lateinit var license: String

    @Option(names = ["--license-file"], required = false)
    var licenseFile: File? = null

    @Option(names = ["--repository"], required = true)
    lateinit var repository: String

    @Option(names = ["--crate-features"], split = ";")
    var crateFeatures: Array<String> = arrayOf()

    @Option(names = ["--universe-manifests"], split = ";")
    var universeManifests: Array<File> = arrayOf()

    @Option(names = ["--workspace-refs-file"], required = false)
    var workspaceRefsFile: File? = null;

    @Option(names = ["--readme-file"], required = false)
    var readmeFile: File? = null

    @Option(names = ["--version-file"], required = true)
    lateinit var versionFile: File

    override fun call() {
        val (externalDepsVersions: Map<String, String>, otherDepsVersions: Map<String, String>) = getDeps()
        writeCrateArchive(externalDepsVersions, otherDepsVersions)
//        writeMetadataFile(externalDepsVersions, otherDepsVersions)
    }

    private fun getDeps(): Pair<MutableMap<String, String>, MutableMap<String, String>> {
        val externalDepsVersions: MutableMap<String, String> = HashMap<String, String>().toMutableMap();
        val otherDepsVersions: MutableMap<String, String> = HashMap<String, String>().toMutableMap();
        val deps: Map<String, String> = if (deps.isEmpty()) {
            emptyMap()
        } else {
            deps.split(";").associate { it.split("=").let { (dep, version) -> dep to version } }
        };

        if (workspaceRefsFile != null) {
            val workspaceRefs = Json.parse(workspaceRefsFile?.readText()).asObject();
            val bazelDepWorkspace = depWorkspaceList.associate { it.split("=").let { (dep, workspace) -> dep to workspace } }
            for (entry in deps.entries) {
                if (isExternalDep(entry.key, bazelDepWorkspace, workspaceRefs)) {
                    externalDepsVersions[entry.key] = externalDepVersion(entry.key, bazelDepWorkspace, workspaceRefs);
                } else {
                    otherDepsVersions[entry.key] = entry.value
                }
            }
        } else {
            otherDepsVersions.putAll(deps);
        }
        return Pair(externalDepsVersions, otherDepsVersions)
    }

    private fun isExternalDep(dep: String, bazelDepWorkspace: Map<String, String>, workspaceRefs: JsonObject): Boolean {
        val workspace = bazelDepWorkspace.get(dep)
        return workspaceRefs.get("commits").asObject().get(workspace) != null ||
                workspaceRefs.get("tags").asObject().get(workspace) != null;
    }

    private fun externalDepVersion(dep: String, bazelDepWorkspace: Map<String, String>, workspaceRefs: JsonObject): String {
        val workspace = bazelDepWorkspace.get(dep)
        val commitDep = workspaceRefs.get("commits").asObject().get(workspace)
        if (commitDep != null) return commitDep.asString();
        val tagDep = workspaceRefs.get("tags").asObject().get(workspace)
        if (tagDep != null) return tagDep.asString();
        throw IllegalStateException();
    }

    private fun writeCrateArchive(externalDepsVersions: Map<String, String>, otherDepsVersions: Map<String, String>) {
        val prefix = "$name-${versionFile.readText()}"
        outputCrateFile.outputStream().use { fos ->
            BufferedOutputStream(fos).use { bos ->
                GZIPOutputStream(bos).use { gzos ->
                    TarArchiveOutputStream(gzos).use { tarOutputStream ->
                        tarOutputStream.setLongFileMode(TarArchiveOutputStream.LONGFILE_POSIX)
                        val libraryRoot = crateRoot.toAbsolutePath().parent
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
                        val crateRootPath = "src/" + libraryRoot.relativize(crateRoot.toAbsolutePath()).toString()
                        val cargoTomlText = generateCargoToml(crateRootPath, externalDepsVersions, otherDepsVersions).toByteArray()
                        cargoToml.size = cargoTomlText.size.toLong()
                        tarOutputStream.putArchiveEntry(cargoToml)
                        IOUtils.copy(ByteArrayInputStream(cargoTomlText), tarOutputStream)
                        tarOutputStream.closeArchiveEntry()

                        if (licenseFile != null) {
                            println("writing license file")
                            tarOutputStream.putArchiveEntry(TarArchiveEntry(
                                    licenseFile,
                                    "$prefix/" + licenseFile?.name
                            ))
                            IOUtils.copy(licenseFile, tarOutputStream)
                            tarOutputStream.closeArchiveEntry()
                        }

                        if (readmeFile != null) {
                            tarOutputStream.putArchiveEntry(TarArchiveEntry(
                                    readmeFile,
                                    "$prefix/" + readmeFile?.name
                            ))
                            IOUtils.copy(readmeFile, tarOutputStream)
                            tarOutputStream.closeArchiveEntry()
                        }
                    }
                }
            }
        }
    }

    private fun generateCargoToml(crateRootPath: String, externalDepsVersions: Map<String, String>, otherDepsVersions: Map<String, String>): String {
        val cargoToml = Config.inMemory()
        cargoToml.createSubConfig().apply {
            cargoToml.set<Config>("package", this)
            set<String>("name", name)
            set<String>("edition", edition)
            set<String>("version", versionFile.readText())
            set<Array<String>>("authors", authors.filter { it != "" })
            set<String>("homepage", homepage)
            set<String>("repository", repository)
            if (documentation != null) {
                set<String>("documentation", documentation)
            }
            set<String>("description", description)
            set<String>("readme", readmeFile?.toPath()?.fileName?.toString() ?: "")
            set<String>("license", license)
            set<String>("licenseFile", licenseFile?.toPath()?.fileName?.toString() ?: "")
        }
        cargoToml.createSubConfig().apply {
            cargoToml.set<Config>("lib", this)
            set<String>("path", crateRootPath)
        }

        val universeDeps = universeManifests.flatMap {
            TomlParser().parse(it.inputStream())
                    .getOrElse("dependencies", Config.inMemory()).entrySet().asSequence()
        }.associate { it.key to it.getValue<String>() }

        val externalDepFeatures = depFeaturesList.associate { it.split("=").let { (dep, feats) -> dep to feats } }
                .mapValues { (_, feats) -> feats.split(",") }

        cargoToml.createSubConfig().apply {
            cargoToml.set<Config>("dependencies", this)
            externalDepsVersions.forEach { (dep, version) ->
                val depConfig = Config.inMemory()
                set<Config>(dep, depConfig)
                depConfig.set<String>("version", "=$version")
                depConfig.set("features", externalDepFeatures.get(dep).orEmpty())
            }

            otherDepsVersions.forEach { (dep, version) ->
                if (universeDeps.contains(dep))
                    set<String>(dep, universeDeps[dep])
                else
                    set<String>(dep, "=$version")
            }
        }

        if (crateFeatures.isNotEmpty()) {
            cargoToml.createSubConfig().apply {
                cargoToml.set<Config>("features", this)
                crateFeatures.associate {
                    it.split("=").let { items ->
                        if (items.size == 2) items[0] to items[1].split(",")
                        else items[0] to listOf()
                    }
                }.forEach { (feature, implied) -> set(feature, implied) }
            }
        }

        return TomlWriter().writeToString(cargoToml.unmodifiable())
    }

//    private fun writeMetadataFile(externalDepsVersions: MutableMap<String, String>, otherDepsVersions: MutableMap<String, String>) {
//        outputMetadataFile.outputStream().use {
//            it.write(constructMetadata(externalDepsVersions, otherDepsVersions).toByteArray(StandardCharsets.UTF_8))
//        }
//    }
//
//    private fun constructMetadata(): String {
//        val features = JsonArray();
//        return JsonObject().apply {
//            set("name", name)
//            set("vers", versionFile.readText())
//            val depsArray = JsonArray()
//            for (dep in depsList) {
//                val (depName, depVer) = dep.split("=")
//                val obj = JsonObject()
//                obj.set("optional", false)
//                obj.set("default_features", false)
//                obj.set("name", depName)
//                obj.set("features", JsonArray())
//                obj.set("version_req", depVer)
//                obj.set("target", Json.NULL)
//                obj.set("kind", "normal")
//                obj.set("registry", "")
//                depsArray.add(obj)
//            }
//            set("deps", depsArray)
//            set("features", JsonObject())
//            set("authors", JsonArray().apply { authors.filter { it != "" }.forEach { add(it) } })
//            set("description", description)
//            if (documentation != null) {
//                set("documentation", documentation)
//            }
//            set("homepage", homepage)
//            readmeFile?.let {
//                set("readme", readmeFile?.readText())
//                set("readme_file", it.toPath().fileName.toString())
//            } ?: run {
//                set("readme", Json.NULL)
//                set("readme_file", Json.NULL)
//            }
//            set("keywords", JsonArray().apply { keywords.filter { it != "" }.forEach { add(it) } })
//            set("categories", JsonArray().apply { categories.filter { it != "" }.forEach { add(it) } })
//            set("license", license)
//            set("license_file", Json.NULL)
//            set("repository", repository)
//            // https://doc.rust-lang.org/cargo/reference/manifest.html#the-badges-section
//            // as docs state all badges should go to README, so it's safe to keep it empty
//            set("badges", JsonObject())
//            set("links", Json.NULL)
//        }.toString()
//    }
}

fun main(args: Array<String>): Unit = exitProcess(CommandLine(CrateAssembler()).execute(*args))
