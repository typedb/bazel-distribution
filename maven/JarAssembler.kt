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

import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.nio.charset.Charset
import java.nio.file.Path
import java.nio.file.Paths
import java.util.concurrent.Callable
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import kotlin.RuntimeException
import kotlin.system.exitProcess

typealias Entries = MutableMap<String, ByteArray>
private fun Entries(): Entries = mutableMapOf()

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

    override fun call() {
        Entries().apply {
            pomFile?.readBytes()?.let { pomContents ->
                val pomPath = "META-INF/maven/${groupId}/${artifactId}/pom.xml"
                this += preCreateDirectories(Paths.get(pomPath))
                this[pomPath] = pomContents
            }

            ZipOutputStream(BufferedOutputStream(FileOutputStream(outputFile))).use {
                if (outputFile.extension == "aar") assembleAar(it)
                else assembleClassesJar(it)
            }
        }
    }

    /** Assemble a class JAR containing the transitive class closure from [jars] and any pre-existing entries in [this] */
    private fun Entries.assembleClassesJar(output: ZipOutputStream, jars: List<File> = this@JarAssembler.jars.toList()) {
        for (jar in jars) {
            if (jar.extension == "aar") {
                throw RuntimeException("cannot package AAR within classes JAR")
            }
            processZip(ZipFile(jar))
        }

        writeEntries(output)
    }

    /** Assemble an AAR from a base AAR containing the transitive class closure from the additional [jars] and any pre-existing entries in [this] */
    private fun Entries.assembleAar(output: ZipOutputStream) {
        val classes = Entries()
        processZip(jars.single { it.extension == "aar" }.let(::ZipFile)) { aar, entry ->
            validateEntry(entry)?.let {
                if (entry.name == "classes.jar") {
                    // pull out classes in nested JAR
                    entry.let(aar::getInputStream).let(::ZipInputStream).use { classesJar ->
                        var zipEntry: ZipEntry? = classesJar.nextEntry
                        while (zipEntry != null) {
                            classes.processEntry(classesJar, zipEntry)
                            zipEntry = classesJar.nextEntry
                        }
                    }
                } else {
                    // add to top-level entries
                    processEntry(aar, entry)
                }
            }
        }

        // write classes jar first
        ZipEntry("classes.jar").let(output::putNextEntry)
        val classJar = ZipOutputStream(output)
        classes.assembleClassesJar(classJar, jars.filter { it.extension != "aar" })
        classJar.finish()

        // write the rest of the entries
        writeEntries(output)
    }

    /** [process] each [ZipEntry] in [file] within the context of [this] */
    private fun Entries.processZip(file: ZipFile, process: Entries.(zip: ZipFile, entry: ZipEntry) -> Unit = { zip, entry -> processEntry(zip, entry) }) = file.use { zip ->
        zip.entries().asSequence().forEach { entry ->
            process(zip, entry)
        }
    }

    /** Validate [ZipEntry] and add information to [this] entries map */
    private fun Entries.processEntry(zip: ZipFile, entry: ZipEntry): Unit = BufferedInputStream(zip.getInputStream(entry)).use {
        processEntry(it, entry)
    }

    /** Validate [ZipEntry] and add information to [this] entries map */
    private fun Entries.processEntry(inputStream: InputStream, entry: ZipEntry) {
        validateEntry(entry)?.let {
            val sourceFileBytes = inputStream.readBytes()
            val resultLocation = getFinalPath(it, sourceFileBytes)
            this += preCreateDirectories(Paths.get(resultLocation))
            this[resultLocation] = sourceFileBytes
        }
    }

    /** Return null if this [entry] shouldn't be processed */
    private fun Entries.validateEntry(entry: ZipEntry): ZipEntry? = when {
        entry.isDirectory -> {
            // needed directories would be added by us
            null
        }
        entry.name.contains("META-INF/maven") -> {
            // pom.xml will be added by us
            null
        }
        keys.contains(entry.name) -> {
            // TODO: Investigate why I'm getting duplicates
            println("I have a duplicate entry: ${entry.name}")
            null
            // throw RuntimeException("duplicate entry in the JAR: ${entry.name}")
        }
        else -> entry
    }

    /** Write entries captured in [this] to [output] */
    private fun Entries.writeEntries(output: ZipOutputStream) {
        entries.sortedBy(Map.Entry<String, *>::key).forEach { (key, entry) ->
            output.putNextEntry(ZipEntry(key))
            output.write(entry)
        }
    }

    /**
     * For path "a/b/c.java" inserts "a/" and "a/b/ into `entries`
     */
    private fun preCreateDirectories(path: Path): Map<String, ByteArray> {
        val newEntries = Entries()
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
