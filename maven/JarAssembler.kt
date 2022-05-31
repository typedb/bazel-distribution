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

package com.vaticle.bazel.distribution.maven

import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.charset.Charset
import java.nio.file.Path
import java.nio.file.Paths
import java.util.concurrent.Callable
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import kotlin.RuntimeException
import kotlin.collections.HashMap
import kotlin.system.exitProcess


@Command(name = "jar-assembler", mixinStandardHelpOptions = true)
class JarAssembler : Callable<Unit> {

    @Option(names = ["--output"], required = true)
    lateinit var outputFile: File

    @Option(names = ["--group-id"])
    var groupId = ""

    @Option(names = ["--artifact-id"])
    var artifactId = ""

    @Option(names = ["--pom-file"])
    var pomFile: File? = null

    @Option(names = ["--jars"], split = ";")
    lateinit var jars: Array<File>

    private val isAarPackaging get() = outputFile.extension == "aar"

    override fun call() {
        when (isAarPackaging) {
            true -> assembleAar()
            else -> assembleJar()
        }
    }

    // TODO: Call into to build class jar for aar
    private fun assembleJar() {
        val entries = hashMapOf<String, ByteArray>()
        val entryNames = mutableSetOf<String>()

        if (pomFile != null) {
            val pomPath = "META-INF/maven/${groupId}/${artifactId}/pom.xml"
            entries += preCreateDirectories(Paths.get(pomPath))
            entries[pomPath] = pomFile!!.readBytes()
        }

        for (jar in jars) {
            if (jar.extension == "aar") {
                throw RuntimeException("cannot package AAR unless output is AAR")
            }
            ZipFile(jar).use { jarZip ->
                jarZip.entries().asSequence().forEach { entry ->
                    if (entryNames.contains(entry.name)) {
                        return@forEach
                        // throw RuntimeException("duplicate entry in the JAR: ${entry.name}")
                    }
                    if (entry.name.contains("META-INF/maven")) {
                        // pom.xml will be added by us
                        return@forEach
                    }
                    if (entry.isDirectory) {
                        // needed directories would be added by us
                        return@forEach
                    }
                    entryNames.add(entry.name)
                    entries.processEntry(jarZip, entry)
                }
            }
        }

        ZipOutputStream(BufferedOutputStream(FileOutputStream(outputFile))).use { jar ->
            entries.keys.sorted().forEach {
                val newEntry = ZipEntry(it)
                jar.putNextEntry(newEntry)
                jar.write(entries[it]!!)
            }
        }
    }


    private fun assembleAar() {
        val entries = hashMapOf<String, ByteArray>()
        val entryNames = mutableSetOf<String>()

        val classes = hashMapOf<String, ByteArray>()
        val classNames = mutableSetOf<String>()

        if (pomFile != null) {
            val pomPath = "META-INF/maven/${groupId}/${artifactId}/pom.xml"
            entries += preCreateDirectories(Paths.get(pomPath))
            entries[pomPath] = pomFile!!.readBytes()
        }

        var baseAar = jars.single { it.extension == "aar" }
        ZipFile(baseAar).use { aar ->
            aar.entries().asSequence().forEach { entry ->
                if (entry.name.contains("META-INF/maven")) {
                    // pom.xml will be added by us
                } else if (entry.isDirectory) {
                    // needed directories would be added by us
                } else if (entry.name == "classes.jar") {
                    // pull out classes in nested JAR
                    entry.let(aar::getInputStream).let(::ZipInputStream).use { classesJar ->
                        var zipEntry: ZipEntry? = classesJar.nextEntry
                        while (zipEntry != null) {
                            if (zipEntry.name.contains("META-INF/maven")) {
                                // pom.xml will be added by us
                            } else if (zipEntry.isDirectory) {
                                // needed directories would be added by us
                            } else {
                                classNames.add(zipEntry.name)
                                val sourceFileBytes = classesJar.readBytes()
                                val resultLocation = getFinalPath(zipEntry, sourceFileBytes)
                                classes += preCreateDirectories(Paths.get(resultLocation))
                                classes[resultLocation] = sourceFileBytes
                            }
                            zipEntry = classesJar.nextEntry
                        }
                    }
                } else {
                    // add to top-level entries
                    entryNames.add(entry.name)
                    entries.processEntry(aar, entry)
                }
            }
        }

        // merge the rest of the class jars
        for (jar in jars.filter { it.extension != "aar" }) {
            ZipFile(jar).use { jarZip ->
                jarZip.entries().asSequence().forEach { entry ->
                    if (classNames.contains(entry.name)) {
                        // TODO: Investigate why this is
                        println("I have a duplicate entry: ${entry.name}")
                        return@forEach
//                        throw RuntimeException("duplicate entry in the JAR: ${entry.name}")
                    }
                    if (entry.name.contains("META-INF/maven")) {
                        // pom.xml will be added by us
                        return@forEach
                    }
                    if (entry.isDirectory) {
                        // needed directories would be added by us
                        return@forEach
                    }
                    classNames.add(entry.name)
                    classes.processEntry(jarZip, entry)
                }
            }
        }

        ZipOutputStream(BufferedOutputStream(FileOutputStream(outputFile))).use { aar ->
            ZipEntry("classes.jar").let(aar::putNextEntry)
            val classJar = ZipOutputStream(aar)
            classes.keys.sorted().forEach {
                val newEntry = ZipEntry(it)
                classJar.putNextEntry(newEntry)
                classJar.write(classes[it])
            }
            classJar.finish()

            entries.keys.sorted().forEach {
                val newEntry = ZipEntry(it)
                aar.putNextEntry(newEntry)
                aar.write(entries[it]!!)
            }
        }
    }

    /** Add [ZipEntry] information to [this] map */
    private fun HashMap<String, ByteArray>.processEntry(file: ZipFile, entry: ZipEntry) {
        BufferedInputStream(file.getInputStream(entry)).use { inputStream ->
            val sourceFileBytes = inputStream.readBytes()
            val resultLocation = getFinalPath(entry, sourceFileBytes)
            this += preCreateDirectories(Paths.get(resultLocation))
            this[resultLocation] = sourceFileBytes
        }
    }

    /**
     * For path "a/b/c.java" inserts "a/" and "a/b/ into `entries`
     */
    private fun preCreateDirectories(path: Path): Map<String, ByteArray> {
        val newEntries = HashMap<String, ByteArray>()
        for (i in path.nameCount-1 downTo 1) {
            val subPath = path.subpath(0, i).toString() + "/"
            newEntries[subPath] = ByteArray(0)
        }
        return newEntries
    }

    private fun getFinalPath(entry: ZipEntry, sourceFileBytes: ByteArray): String {
        return if (entry.name.endsWith(".java")) {
            // files in source JARs are moved according to their `package` statement
            val sourceFile = toStringUTF8(sourceFileBytes)
            val sourceFileName = Paths.get(entry.name).fileName.toString()
            val sourceFilePackage = getJavaPackage(sourceFile) ?: throw RuntimeException("could not obtain package of ${entry.name}")
            "${sourceFilePackage.replace(".", "/")}/$sourceFileName"
        } else {
            entry.name
        }
    }

    private fun toStringUTF8(sourceFileBytes: ByteArray): String {
        return sourceFileBytes.toString(Charset.forName("UTF-8"))
    }

    private fun getJavaPackage(sourceFile: String): String? {
        val javaPackageRegex = Regex("package\\s+([a-zA_Z_][\\.\\w]*);")
        return javaPackageRegex.find(sourceFile)?.groups?.get(1)?.value
    }

}

fun main(args: Array<String>): Unit = exitProcess(CommandLine(JarAssembler()).execute(*args))
