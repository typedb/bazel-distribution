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

package com.vaticle.typedb.driver.tool.docs.python

import com.vaticle.typedb.driver.tool.docs.dataclasses.Class
import com.vaticle.typedb.driver.tool.docs.dataclasses.EnumConstant
import com.vaticle.typedb.driver.tool.docs.dataclasses.Method
import com.vaticle.typedb.driver.tool.docs.dataclasses.Variable
import com.vaticle.typedb.driver.tool.docs.util.removeAllTags
import com.vaticle.typedb.driver.tool.docs.util.replaceCodeTags
import com.vaticle.typedb.driver.tool.docs.util.replaceEmTags
import com.vaticle.typedb.driver.tool.docs.util.replaceSymbolsForAnchor
import org.jsoup.Jsoup
import org.jsoup.nodes.Element
import picocli.CommandLine
import picocli.CommandLine.Parameters
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import java.util.*
import java.util.concurrent.Callable
import kotlin.collections.HashMap
import kotlin.system.exitProcess

fun main(args: Array<String>): Unit = exitProcess(CommandLine(PythonDocParser()).execute(*args))

@CommandLine.Command(name = "PythonDocParser", mixinStandardHelpOptions = true)
class PythonDocParser : Callable<Unit> {
    @Parameters(paramLabel = "<input>", description = ["Input directory"])
    private lateinit var inputDirectoryNames: List<String>

    @CommandLine.Option(names = ["--output", "-o"], required = true)
    private lateinit var outputDirectoryName: String

    /**
     * --dir=file=directory: put a file into the specified directory
     * If no directory is specified for at least one file, an exception will be thrown.
     */
    @CommandLine.Option(names = ["--dir", "-d"], required = true)
    private lateinit var dirs: HashMap<String, String>

    @Override
    override fun call() {
        val inputDirectoryName = inputDirectoryNames[0]

        val docsDir = System.getenv("BUILD_WORKSPACE_DIRECTORY")?.let { Paths.get(it).resolve(outputDirectoryName) }
            ?: Paths.get(outputDirectoryName)
        if (!docsDir.toFile().exists()) {
            Files.createDirectory(docsDir)
        }

        // HTML file path regex mapped to class names to include from that path.
        val fileClassFilter = mapOf(
                Pair(Regex(".*\\.api\\..*"), Regex(".*")),
                Pair(Regex(".*\\.common\\..*"), Regex(".*")),
                Pair(Regex(".*typedb\\.html"), Regex("TypeDB")),
        )

        File(inputDirectoryName).walkTopDown().filter {
            it.toString().endsWith(".html") && getClassFilter(it.toString(), fileClassFilter).isPresent()
        }.forEach {
            val classNameFilter = getClassFilter(it.toString(), fileClassFilter).get()
            val html = it.readText(Charsets.UTF_8)
            val parsed = Jsoup.parse(html)

            parsed.select("dl.class, dl.exception").forEach {
                val parsedClass = if (it.selectFirst("dt.sig-object + dd > p")!!.text().contains("Enum")) {
                    parseEnum(it)
                } else {
                    parseClass(it)
                }
                if (parsedClass.isNotEmpty() && classNameFilter.matches(parsedClass.name)) {
                    val parsedClassAsciiDoc = parsedClass.toAsciiDoc("python")
                    val fileName = "${parsedClass.name}.adoc"
                    val fileDir = docsDir.resolve(dirs[fileName]
                        ?: throw IllegalArgumentException("Output directory for '$fileName' was not provided"))
                    if (!fileDir.toFile().exists()) {
                        Files.createDirectory(fileDir)
                    }
                    val outputFile = fileDir.resolve(fileName).toFile()
                    outputFile.createNewFile()
                    outputFile.writeText(parsedClassAsciiDoc)
                }
            }
        }
    }

    private fun getClassFilter(filePathString: String, fileClassFilter: Map<Regex, Regex>, ): Optional<Regex> {
        return fileClassFilter.entries.stream().filter { it.key.matches(filePathString) }.findFirst().map { it.value };
    }

    private fun parseClass(element: Element): Class {
        val classSignElement = element.selectFirst("dt.sig-object")
        val className = classSignElement!!.selectFirst("dt.sig-object span.sig-name")!!.text()
        val classAnchor = className

        var classDetailsElement = classSignElement.nextElementSibling()
        val classDetailsParagraphs = classDetailsElement!!.children().map { it }.filter { it.tagName() == "p" }
        val (descr, bases) = classDetailsParagraphs.partition { it.select("code.py-class").isNullOrEmpty() }
        val superClasses = bases[0]!!.text().substringAfter("Bases: ").split(", ")
            .filter { it != "ABC" && it != "object" && it != "Generic[T]" && !it.startsWith("NativeWrapper") }
        val classDescr = descr.map { reformatTextWithCode(it.html()) }

        val exampleHeaderElements = classDetailsElement.children().map { it.firstElementChild() }
            .filter { it?.text()?.contains("Examples") ?: false }
        val classExamples = if (exampleHeaderElements.isNotEmpty()) {
            classDetailsElement = exampleHeaderElements.first()!!.parent()
            exampleHeaderElements.first()!!.nextElementSibling()?.select(".highlight")?.map { it.text() } ?: listOf()
        } else listOf()

        val methods = classDetailsElement!!.children().map { it }.filter { it.className() == "py method" }
            .map { parseMethod(it, classAnchor) }

        val properties = classDetailsElement.children().map { it }.filter { it.className() == "py property" }
            .map { parseProperty(it) }.filter { it.name != "native_object" }

        return Class(
            name = className,
            anchor = classAnchor,
            description = classDescr,
            examples = classExamples,
            fields = properties,
            methods = methods,
            superClasses = superClasses,
        )
    }

    private fun parseEnum(element: Element): Class {
        val classSignElement = element.selectFirst("dt.sig-object")
        val className = classSignElement!!.selectFirst("dt.sig-object span.sig-name")!!.text()
        val classAnchor = className

        val classDetails = classSignElement.nextElementSibling()
        val classDetailsParagraphs = classDetails!!.children().map { it }.filter { it.tagName() == "p" }
        val (descr, bases) = classDetailsParagraphs.partition { it.select("code.py-class").isNullOrEmpty() }
        val classDescr = descr.map { reformatTextWithCode(it.html()) }

        val classExamples = element.select("section:contains(Examples) .highlight").map { it.text() }

        val methods = classDetails.select("dl.method").map { parseMethod(it, classAnchor) }
        val members = classDetails.select("dl.attribute").map { parseEnumConstant(it) }

        return Class(
            name = className,
            anchor = classAnchor,
            description = classDescr,
            enumConstants = members,
            examples = classExamples,
            methods = methods,
        )
    }

    private fun parseMethod(element: Element, classAnchor: String): Method {
        val methodSignature = enhanceSignature(element.selectFirst("dt.sig-object")!!.text())
        val methodName = element.selectFirst("dt.sig-object span.sig-name")!!.text()
        val allArgs = getArgsFromSignature(element.selectFirst("dt.sig-object")!!)
        val methodReturnType = element.select(".sig-return-typehint").text()
        val methodDescr = element.select("dl.method > dd > p").map { reformatTextWithCode(it.html()) }
        val methodArgs = element.select(".field-list > dt:contains(Parameters) + dd p").map {
            val argName = it.selectFirst("strong")!!.text()
            assert(allArgs.contains(argName))
            val argDescr = reformatTextWithCode(removeArgName(it.html())).removePrefix(" – ")
            Variable(
                name = argName,
                defaultValue = allArgs[argName]?.second,
                description = argDescr,
                type = allArgs[argName]?.first,
            )
        }
        val methodReturnDescr = element.select(".field-list > dt:contains(Returns) + dd p").text()
        val methodExamples = element.select("section:contains(Examples) .highlight").map { it.text() }
        val methodAnchor = replaceSymbolsForAnchor("${classAnchor}_${methodName}_${methodArgs.map { it.shortString() }}")

        return Method(
            name = methodName,
            signature = methodSignature,
            anchor = methodAnchor,
            args = methodArgs,
            description = methodDescr,
            examples = methodExamples,
            returnDescription = methodReturnDescr,
            returnType = methodReturnType,
        )
    }

    private fun parseProperty(element: Element): Variable {
        val name = element.selectFirst("dt.sig-object span.sig-name")!!.text()
        val type = element.selectFirst("dt.sig-object span.sig-name + .property ")?.text()?.dropWhile { !it.isLetter() }
        val descr = element.select("dd > p").map { reformatTextWithCode(it.html()) }.joinToString("\n\n")
        return Variable(
            name = name,
            description = descr,
            type = type,
        )
    }

    private fun parseEnumConstant(element: Element): EnumConstant {
        val name = element.selectFirst("dt.sig-object span.sig-name")!!.text()
        val value = element.selectFirst("dt.sig-object span.sig-name + .property")!!.text().removePrefix("= ")
        return EnumConstant(
            name = name,
            value = value,
        )
    }

    private fun getArgsFromSignature(methodSignature: Element): Map<String, Pair<String?, String?>> {
        return methodSignature.select(".sig-param").map {
            it.selectFirst(".n")!!.text() to
                    Pair(it.select(".p + .w + .n").text(), it.selectFirst("span.default_value")?.text())
        }.toMap()
    }

    private fun reformatTextWithCode(html: String): String {
        return removeAllTags(replaceEmTags(replaceCodeTags(html)))
    }

    private fun removeArgName(html: String): String {
        return Regex("<strong>[^<]*</strong>").replace(html, "")
    }

    private fun enhanceSignature(signature: String): String {
        return signature.replace("→", "->").replace("¶", "").replace("abstract ", "")
    }
}
