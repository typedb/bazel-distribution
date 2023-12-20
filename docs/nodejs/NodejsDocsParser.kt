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

package com.vaticle.typedb.driver.tool.docs.nodejs

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
import java.util.concurrent.Callable
import kotlin.system.exitProcess

fun main(args: Array<String>): Unit = exitProcess(CommandLine(NodejsDocParser()).execute(*args))

@CommandLine.Command(name = "NodejsDocParser", mixinStandardHelpOptions = true)
class NodejsDocParser : Callable<Unit> {
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

        val parsedClasses: HashMap<String, Class> = hashMapOf()
        val namespaceFunctions: HashMap<String, MutableList<Method>> = hashMapOf()

        // special case for namespace functions that we should parse
        val namespaceFunctionsFilter = Regex(".*/functions/.*(coreDriver|cloudDriver).*")
        File(inputDirectoryName).walkTopDown().filter {
            (it.toString().contains("/classes/") || it.toString().contains("/interfaces/")
                    || it.toString().contains("/modules/") || namespaceFunctionsFilter.matches(it.toString()))
        }.forEach {
            val html = it.readText(Charsets.UTF_8)
            val parsed = Jsoup.parse(html)
            val title = parsed.select(".tsd-page-title h1")
            if (title.text().contains("Function")) {
                val namespaceName = Paths.get(it.path).fileName.toString().split(".")[0];
                val function = parsed.select("section.tsd-panel > .tsd-signatures > .tsd-signature").map {
                    parseMethod(it, namespaceName)
                }.first()
                namespaceFunctions.computeIfAbsent(namespaceName) { mutableListOf() }.add(function)
            } else {
                val parsedClass = if (!title.isNullOrEmpty() && (title.text().contains("Class") || title.text().contains("Interface"))) {
                    parseClass(parsed)
                } else {
                    assert(title.text().contains("Namespace"))
                    parseNamespace(parsed)
                }
                parsedClasses[parsedClass.name] = if (parsedClasses.contains(parsedClass.name)) {
                    parsedClasses[parsedClass.name]!!.merge(parsedClass)
                } else {
                    parsedClass
                }
            }
        }

        namespaceFunctions.forEach{ (namespaceName, functions) ->
            if (parsedClasses.contains(namespaceName)) {
                val classWithMethod = Class(namespaceName, methods = functions.toList())
                parsedClasses[namespaceName] = parsedClasses[namespaceName]!!.merge(classWithMethod)
            } else {
                throw IllegalArgumentException("Function $functions exists in namespace $namespaceName but not class definition was found to attach to");
            }
        }

        parsedClasses.forEach { (name, parsedClass) ->
            if (parsedClasses[parsedClass.name]!!.isNotEmpty()) {
                val parsedClassAsciiDoc = parsedClasses[parsedClass.name]!!.toAsciiDoc("nodejs")
                val fileName = "${generateFilename(parsedClass.name)}.adoc"
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

    private fun parseClass(document: Element): Class {
        val className =
                document.selectFirst(".tsd-page-title h1")!!.textNodes().first()!!.text().split(" ", limit = 2)[1]
        val classAnchor = replaceSymbolsForAnchor(className)
        val classDescr = document.select(".tsd-page-title + section.tsd-comment div.tsd-comment p").map {
            reformatTextWithCode(it.html())
        }

        val superClasses = document.select("ul.tsd-hierarchy li:has(ul.tsd-hierarchy span.target)").map {
            it.child(0).text()
        }

        val propertiesElements = document.select("section.tsd-member-group:contains(Properties)")
        val properties = propertiesElements.select("section.tsd-member:not(.tsd-is-private)").map {
            parseProperty(it)
        }

        val methodsElements = document.select(
                "section.tsd-member-group:contains(Constructors), " +
                        "section.tsd-member-group:contains(Method)"
        )
        val methods = methodsElements.select("section.tsd-member > .tsd-signatures > .tsd-signature").map {
            parseMethod(it, classAnchor)
        }.filter {
            it.name != "proto"
        } + document.select("section.tsd-member-group:contains(Accessors)")
                .select("section.tsd-member > .tsd-signatures > .tsd-signature").map {
                    parseAccessor(it, classAnchor)
                }

        return Class(
                name = className,
                anchor = classAnchor,
                description = classDescr,
                fields = properties,
                methods = methods,
                superClasses = superClasses,
        )
    }

    private fun parseNamespace(document: Element): Class {
        val className = document.selectFirst(".tsd-page-title h1")!!.text().split(" ")[1]
        val classAnchor = replaceSymbolsForAnchor(className)
        val classDescr = document.select(".tsd-page-title + section.tsd-comment div.tsd-comment p").map {
            reformatTextWithCode(it.html())
        }
        val variables = document.select(".tsd-index-heading:contains(Variables) + .tsd-index-list a").map {
            EnumConstant(name = it.text())
        }
        return Class(
                name = className,
                anchor = classAnchor,
                description = classDescr,
                enumConstants = variables,
        )
    }

    private fun parseMethod(element: Element, classAnchor: String): Method {
        val methodSignature = element.text()
        val methodName = element.selectFirst(".tsd-kind-call-signature, .tsd-kind-constructor-signature")!!.text()
        val descrElement = element.nextElementSibling()
        val methodReturnType = descrElement!!
                .selectFirst(".tsd-description > .tsd-returns-title:not(.tsd-parameter-signature .tsd-returns-title)")
                ?.text()?.substringAfter("Returns ")
        val methodDescr =
                descrElement.select(".tsd-description > .tsd-comment p").map { reformatTextWithCode(it.html()) }
        val methodExamples =
                descrElement.select(".tsd-description > .tsd-comment > :has(a[href*=examples]) + pre > :not(button)")
                        .map { it.text() }

        val methodArgs = descrElement.select(
                ".tsd-description > .tsd-parameters > .tsd-parameter-list > " +
                        "li:not(.tsd-parameter-signature li)"
        ).map {
            Variable(
                    name = it.selectFirst(".tsd-kind-parameter")!!.text(),
                    type = it.selectFirst("h5")!!.text().substringAfter(": "),
                    description = it.selectFirst(".tsd-comment")?.let { reformatTextWithCode(it.html()) },
            )
        }
        val methodAnchor = replaceSymbolsForAnchor("${classAnchor}_${methodName}_${methodArgs.map { it.shortString() }}")

        return Method(
                name = methodName,
                anchor = methodAnchor,
                signature = methodSignature,
                args = methodArgs,
                description = methodDescr,
                examples = methodExamples,
                returnType = methodReturnType,
        )
    }

    private fun parseAccessor(element: Element, classAnchor: String): Method {
        val methodSignature = element.text()
        val methodName = element.selectFirst(".tsd-signature")!!.textNodes().first()!!.text()
        val descrElement = element.nextElementSibling()
        val methodReturnType = descrElement!!.select(".tsd-returns-title > *")
                .joinToString("") { it.text() }
        val methodDescr =
                descrElement.select(".tsd-description > .tsd-comment p").map { reformatTextWithCode(it.html()) }
        val methodExamples = descrElement
                .select(".tsd-description > .tsd-comment > :has(a[href*=examples]) + pre > :not(button)")
                .map { it.text() }
        val methodArgs = descrElement.select(
                ".tsd-description > .tsd-parameters > .tsd-parameter-list > " +
                        "li:not(.tsd-parameter-signature li)"
        ).map {
            Variable(
                    name = it.selectFirst(".tsd-kind-parameter")!!.text(),
                    type = it.selectFirst("h5")!!.text().substringAfter(": "),
                    description = it.selectFirst(".tsd-comment")?.let { reformatTextWithCode(it.html()) },
            )
        }
        val methodAnchor = replaceSymbolsForAnchor("${classAnchor}_${methodName}_${methodArgs.map { it.shortString() }}")

        return Method(
                name = methodName,
                signature = methodSignature,
                anchor = methodAnchor,
                description = methodDescr,
                examples = methodExamples,
                returnType = methodReturnType,
        )
    }

    private fun parseProperty(element: Element): Variable {
        val name = element.selectFirst(".tsd-signature span.tsd-kind-property")!!.text()
        val type = element.selectFirst(".tsd-signature .tsd-signature-type")?.text()
        val descr = element.selectFirst(".tsd-signature + .tsd-comment")?.text()
        return Variable(
                name = name,
                description = descr,
                type = type,
        )
    }

    private fun reformatTextWithCode(html: String): String {
        return removeAllTags(replaceEmTags(replaceCodeTags(html)))
    }

    private fun generateFilename(className: String): String {
        return className.replace("[<>]".toRegex(), "_")
    }
}
