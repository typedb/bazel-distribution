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

package com.vaticle.bazel.distribution.maven

import com.eclipsesource.json.Json
import com.eclipsesource.json.JsonObject
import com.eclipsesource.json.JsonValue
import org.w3c.dom.Document
import org.w3c.dom.Element
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import java.io.File
import java.util.concurrent.Callable
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.OutputKeys
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult
import kotlin.system.exitProcess


@Command(name = "pom-generator", mixinStandardHelpOptions = true)
class PomGenerator : Callable<Unit> {

    @Option(names = ["--version_file"])
    lateinit var versionFile: File

    @Option(names = ["--output_file"])
    lateinit var outputFile: File

    @Option(names = ["--workspace_refs_file"])
    lateinit var workspaceRefsFile: File

    @Option(names = ["--project_name"])
    var projectName = ""

    @Option(names = ["--project_description"])
    var projectDescription = ""

    @Option(names = ["--project_url"])
    var projectUrl = ""

    @Option(names = ["--license"])
    var license = ""

    @Option(names = ["--scm_url"])
    var scmUrl = ""

    @Option(names = ["--developers"])
    var developers = "{}"

    @Option(names = ["--target_group_id"])
    var targetGroupId = ""

    @Option(names = ["--target_artifact_id"])
    var targetArtifactId = ""

    @Option(names = ["--target_deps_coordinates"])
    lateinit var dependencyCoordinates: String

    @Option(names = ["--profiles"])
    var profilesSpec: String = ""

    fun getLicenseInfo(license_id: String): Pair<String, String> {
        return when {
            license_id.equals("apache") -> {
                Pair("Apache License, Version 2.0", "https://www.apache.org/licenses/LICENSE-2.0.txt")
            }
            license_id.equals("mit") -> {
                Pair("MIT License", "https://opensource.org/licenses/MIT")
            }
            else -> {
                throw RuntimeException("unknown license identifier: $license_id")
            }
        }
    }

    fun parseMavenCoordinate(coordinate: String): Triple<String, String, String> {
        val (groupId, artifactId, version) = coordinate.split(":")
        return Triple(groupId, artifactId, version)
    }

    fun version(originalVersion: String, version: String, workspace_refs: JsonObject): String {
        if (originalVersion.equals("{pom_version}")) {
            return version
        }
        val versionCommit = workspace_refs.get("commits").asObject().get(originalVersion)
        if (versionCommit != null) {
            return versionCommit.asString()
        }
        val tagCommit = workspace_refs.get("tags").asObject().get(originalVersion)
        if (tagCommit != null) {
            return tagCommit.asString()
        }
        return originalVersion
    }

    fun licenses(pom: Document): Element {
        val licenses = pom.createElement("licenses")
        val licenseElem = pom.createElement("license")
        val licenseNameElem = pom.createElement("name")
        // obtain full license name and URL from an identifier
        val (licenseName, licenseUrl) = getLicenseInfo(license)
        licenseNameElem.appendChild(pom.createTextNode(licenseName))
        val licenseUrlElem = pom.createElement("url")
        licenseUrlElem.appendChild(pom.createTextNode(licenseUrl))
        licenseElem.appendChild(licenseNameElem)
        licenseElem.appendChild(licenseUrlElem)
        licenses.appendChild(licenseElem)
        return licenses
    }

    /**
     * Creates the `developers` tag for a POM from a [JsonObject] describing each `developer`
     * using the key as the `id` and the value as an array of strings containing a "=" delimited
     * key, value pair for additional developer info elements.
     *
     * { "john": ["name=John Smith", "email=john@email.com"] }
     */
    fun Document.developers(developers: JsonObject): Element = createElement("developers").apply {
        developers.map { (id, attributes) ->
            createElement("developer").apply {
                (listOf(createElement("id").apply {
                    appendChild(createTextNode(id))
                }) + attributes.asArray().map { it.asString().split("=") }.map { (element, value) ->
                    createElement(element).apply {
                        appendChild(createTextNode(value))
                    }
                }).forEach(::appendChild)
            }
        }.forEach(::appendChild)
    }

    fun scm(pom: Document, version: String): Element {
        val scm = pom.createElement("scm")
        val connection = pom.createElement("connection")
        connection.appendChild(pom.createTextNode(scmUrl))
        val developerConnection = pom.createElement("developerConnection")
        developerConnection.appendChild(pom.createTextNode(scmUrl))
        val tag = pom.createElement("tag")
        tag.appendChild(pom.createTextNode(version))
        val scmUrlElem = pom.createElement("url")
        scmUrlElem.appendChild(pom.createTextNode(this.scmUrl))
        scm.appendChild(connection)
        scm.appendChild(developerConnection)
        scm.appendChild(tag)
        scm.appendChild(scmUrlElem)
        return scm
    }

    fun dependencies(pom: Document, version: String, workspace_refs: JsonObject, dependencies: String): Element {
        val dependenciesElem = pom.createElement("dependencies")
        val coordinates = if (dependencies.isEmpty()) emptyArray() else dependencies.split(";").toTypedArray()
        for (dep in coordinates) {
            val depCoordinates = parseMavenCoordinate(dep)
            val dependencyElem = pom.createElement("dependency")

            val dependencyGroupId = pom.createElement("groupId")
            dependencyGroupId.appendChild(pom.createTextNode(depCoordinates.first))
            val dependencyArtifactId = pom.createElement("artifactId")
            dependencyArtifactId.appendChild(pom.createTextNode(depCoordinates.second))
            val dependencyVersion = pom.createElement("version")
            dependencyVersion.appendChild(pom.createTextNode(version(depCoordinates.third, version, workspace_refs)))

            dependencyElem.appendChild(dependencyGroupId)
            dependencyElem.appendChild(dependencyArtifactId)
            dependencyElem.appendChild(dependencyVersion)
            dependenciesElem.appendChild(dependencyElem)
        }
        return dependenciesElem
    }

    fun profiles(pom: Document, version: String, workspace_refs: JsonObject): Element {
        val profilesElem = pom.createElement("profiles")
        val profiles = if (profilesSpec.isEmpty()) emptyArray() else profilesSpec.split(";").toTypedArray()
        for (profile in profiles) {
            val (id, dependencies) = profile.split("#", limit = 2)
            val (os, arch) = id.split(",", limit = 2)
            val profileElem = pom.createElement("profile")

            val idElem = pom.createElement("id")
            idElem.appendChild(pom.createTextNode("$os-$arch"))
            profileElem.appendChild(idElem)

            val activationElem = pom.createElement("activation")
            val osElem = pom.createElement("os")

            val familyElem = pom.createElement("family")
            familyElem.appendChild(pom.createTextNode(os))
            osElem.appendChild(familyElem)

            val archElem = pom.createElement("arch")
            archElem.appendChild(pom.createTextNode(arch))
            osElem.appendChild(archElem)

            activationElem.appendChild(osElem)
            profileElem.appendChild(activationElem)

            profileElem.appendChild(dependencies(pom, version, workspace_refs, dependencies))

            profilesElem.appendChild(profileElem)
        }
        return profilesElem
    }

    private fun outputDocumentToFile(pom: Document) {
        val transformer = TransformerFactory.newInstance().newTransformer()
        transformer.setOutputProperty(OutputKeys.INDENT, "yes")
        transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2")
        transformer.transform(DOMSource(pom), StreamResult(outputFile))
    }

    override fun call() {
        val version = versionFile.readText()
        val workspace_refs = Json.parse(workspaceRefsFile.readText()).asObject()

        // Create an XML document for constructing the POM
        val pom = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument()

        // root element describing the project
        val rootElement = pom.createElement("project")
        rootElement.setAttribute("xmlns", "http://maven.apache.org/POM/4.0.0")
        rootElement.setAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
        rootElement.setAttribute("xsi:schemaLocation", "http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd")
        pom.appendChild(rootElement)

        // version of the Maven POM format
        val modelVersion = pom.createElement("modelVersion")
        modelVersion.appendChild(pom.createTextNode("4.0.0"))
        rootElement.appendChild(modelVersion)

        // project name
        val name = pom.createElement("name")
        name.appendChild(pom.createTextNode(projectName))
        rootElement.appendChild(name)

        // project description
        val description = pom.createElement("description")
        description.appendChild(pom.createTextNode(projectDescription))
        rootElement.appendChild(description)

        // project URL
        val url = pom.createElement("url")
        url.appendChild(pom.createTextNode(projectUrl))
        rootElement.appendChild(url)

        // licenses
        rootElement.appendChild(licenses(pom))

        val developers = Json.parse(developers).asObject()
        if (!developers.isEmpty) rootElement.appendChild(pom.developers(developers))

        // source control management information
        rootElement.appendChild(scm(pom, version))

        // group id of the library
        val groupIdElem = pom.createElement("groupId")
        groupIdElem.appendChild(pom.createTextNode(targetGroupId))
        rootElement.appendChild(groupIdElem)

        // artifact id of the library
        val artifactIdElem = pom.createElement("artifactId")
        artifactIdElem.appendChild(pom.createTextNode(targetArtifactId))
        rootElement.appendChild(artifactIdElem)

        // version of the library
        val versionElem = pom.createElement("version")
        versionElem.appendChild(pom.createTextNode(version))
        rootElement.appendChild(versionElem)

        // add dependency information
        rootElement.appendChild(dependencies(pom, version, workspace_refs, dependencyCoordinates))

        rootElement.appendChild(profiles(pom, version, workspace_refs))

        // write the final result
        outputDocumentToFile(pom)
    }
}

private operator fun JsonObject.Member.component1(): String = name
private operator fun JsonObject.Member.component2(): JsonValue = value

fun main(args: Array<String>): Unit = exitProcess(CommandLine(PomGenerator()).execute(*args))
