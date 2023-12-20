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

package com.vaticle.typedb.driver.tool.docs.java

import com.vaticle.typedb.driver.tool.docs.dataclasses.Class
import com.vaticle.typedb.driver.tool.docs.dataclasses.EnumConstant
import com.vaticle.typedb.driver.tool.docs.dataclasses.Method
import com.vaticle.typedb.driver.tool.docs.dataclasses.Variable
import com.vaticle.typedb.driver.tool.docs.util.*
import org.jsoup.Jsoup
import org.jsoup.nodes.Element
import picocli.CommandLine
import picocli.CommandLine.Parameters
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.concurrent.Callable
import kotlin.system.exitProcess


fun main(args: Array<String>): Unit = exitProcess(CommandLine(JavaDocParser()).execute(*args))

@CommandLine.Command(name = "JavaDocsParser", mixinStandardHelpOptions = true)
class JavaDocParser : Callable<Unit> {
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

        File(inputDirectoryName).walkTopDown().filter {
            it.toString().contains("/driver/") && !it.toString().contains("-use")
                    && !it.toString().contains("-summary") && !it.toString().contains("-tree")
                    && it.toString().endsWith(".html")
        }.forEach {
            val html = File(it.path).readText(Charsets.UTF_8)
            val parsed = Jsoup.parse(html)
            val parsedClass = if (!parsed.select("h2[title^=Interface]").isNullOrEmpty()
                || !parsed.select("h2[title^=Class]").isNullOrEmpty()
            ) {
                parseClass(parsed, it.parent)
            } else {
                parseEnum(parsed)
            }

            if (parsedClass.isNotEmpty()) {
                val parsedClassAsciiDoc = parsedClass.toAsciiDoc("java")
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

    private fun parseClass(document: Element, currentDirName: String): Class {
        val className = document.selectFirst(".contentContainer .description pre .typeNameLabel")!!.text()
        val classAnchor = replaceSymbolsForAnchor(className)
        val classDescr: List<String> = document.selectFirst(".contentContainer .description pre + div")
            ?.let { splitToParagraphs(it.html()) }?.map { reformatTextWithCode(it.substringBefore("<h")) } ?: listOf()
        val packagePath = document.selectFirst(".packageLabelInType + a")?.text()
        val classExamples =
            document.select(".contentContainer .description pre + div pre").map { replaceSpaces(it.text()) }
        val superClasses =
            document.select(".contentContainer .description dt:contains(Superinterfaces) + dd code").map {
                it.text()
            }

        val fields = document.select(".summary > ul > li > section > ul > li:has(a[id=field.summary]) > table tr:gt(0)")
            .map { parseField(it) }
        val methods =
            document.select(".details > ul > li > section > ul > li:has(a[id=constructor.detail]) > ul > li").map {
                parseMethod(it, classAnchor)
            } + document.select(".details > ul > li > section > ul > li:has(a[id=method.detail]) > ul > li").map {
                parseMethod(it, classAnchor)
            } + document.select(".memberSummary + ul > li > h3:contains(Methods inherited from) + code > a").map {
                val parentPath = Path.of(currentDirName).resolve(it.attr("href").substringBefore("#"))
                val parentHtml = File(parentPath.toString()).readText(Charsets.UTF_8)
                val parentParsed = Jsoup.parse(parentHtml)
                val anchor = it.attr("href").substringAfter("#")
                parseMethod(parentParsed.selectFirst("a[id=$anchor] + ul > li")!!, classAnchor)
            }

        return Class(
            name = className,
            anchor = classAnchor,
            description = classDescr,
            examples = classExamples,
            fields = fields,
            methods = methods,
            packagePath = packagePath,
            superClasses = superClasses,
        )
    }

    private fun parseEnum(document: Element): Class {
        val className = document.selectFirst(".contentContainer .description pre .typeNameLabel")!!.text()
        val classAnchor = replaceSymbolsForAnchor(className)
        val classDescr: List<String> = document.selectFirst(".contentContainer .description pre + div")
            ?.let { splitToParagraphs(it.html()) }?.map { reformatTextWithCode(it.substringBefore("<h")) } ?: listOf()
        val packagePath = document.selectFirst(".packageLabelInType + a")?.text()
        val classExamples =
            document.select(".contentContainer .description pre + div pre").map { replaceSpaces(it.text()) }
        val classBases = document.select(".contentContainer .description dt:contains(Superinterfaces) + dd code").map {
            it.text()
        }

        val enumConstants =
            document.select(".summary > ul > li > section > ul > li:has(a[id=enum.constant.summary]) > table tr:gt(0)")
                .map {
                    parseEnumConstant(it)
                }
        val fields =
            document.select(".summary > ul > li > section > ul > li:has(a[id=field.summary]) > table tr:gt(0)").map {
                parseField(it)
            }
        val methods =
            document.select(".details > ul > li > section > ul > li:has(a[id=constructor.detail]) > ul > li").map {
                parseMethod(it, classAnchor)
            } + document.select(".details > ul > li > section > ul > li:has(a[id=method.detail]) > ul > li").map {
                parseMethod(it, classAnchor)
            }

        return Class(
            name = className,
            anchor = classAnchor,
            description = classDescr,
            enumConstants = enumConstants,
            examples = classExamples,
            fields = fields,
            methods = methods,
            packagePath = packagePath,
            superClasses = classBases,
        )
    }

    private fun parseMethod(element: Element, classAnchor: String): Method {
        val methodName = element.selectFirst("h4")!!.text()
        val methodSignature = element.selectFirst("li.blockList > pre")!!.text()
        val argsList = getArgsFromSignature(methodSignature)
        val argsMap = argsList.toMap()
        val methodReturnType = getReturnTypeFromSignature(methodSignature)
        var methodDescr: List<String> = element.selectFirst("li.blockList > pre ~ div:not(div:has(.descfrmTypeLabel))")
            ?.let { splitToParagraphs(it.html()) }
            ?.map { replaceSpaces(reformatTextWithCode(it.substringBefore("<h"))) } ?: listOf()
        val methodExamples = element.select("li.blockList > pre + div pre").map { replaceSpaces(it.text()) }

        val methodArgs = element
            .select(
                "dt:has(.paramLabel) " +
                        "~ dd:not(dt:has(.returnLabel) ~ dd, dt:has(.throwsLabel) ~ dd, dt:has(.seeLabel) ~ dd)"
            )
            .map {
                val arg_name = it.selectFirst("code")!!.text()
                assert(argsMap.contains(arg_name))
                Variable(
                    name = arg_name,
                    type = argsMap[arg_name]?.replace("...", "[]"),
                    description = reformatTextWithCode(it.html().substringAfter(" - ")),
                )
            }
        val methodAnchor = replaceSymbolsForAnchor("${classAnchor}_${methodName}_${argsList.map{ it.second }}")
        val seeAlso = element.selectFirst("dt:has(.seeLabel) + dd")?.let { reformatTextWithCode(it.html()) }
        seeAlso?.let { methodDescr += "\nSee also: $seeAlso\n" }

        return Method(
            name = methodName,
            signature = enhanceSignature(methodSignature),
            anchor = methodAnchor,
            args = methodArgs,
            description = methodDescr,
            examples = methodExamples,
            returnType = methodReturnType,
        )

    }

    private fun parseField(element: Element): Variable {
        val name = element.selectFirst(".colSecond")!!.text()
        val type = element.selectFirst(".colFirst")!!.text()
        val descr = element.selectFirst(".colLast")?.text()
        return Variable(
            name = name,
            description = descr,
            type = type,
        )
    }

    private fun parseEnumConstant(element: Element): EnumConstant {
        val name = element.selectFirst(".colFirst")!!.text()
        return EnumConstant(
            name = name,
        )
    }

    private fun getArgsFromSignature(methodSignature: String): List<Pair<String, String>> {
        return methodSignature
            .replace("\\s+".toRegex(), " ")
            .substringAfter("(").substringBefore(")")
            .split(",\\s".toRegex()).map {
                it.split("\u00a0").let { it.last() to it.dropLast(1).joinToString(" ") }
            }.filter { !it.first.isEmpty() || !it.second.isEmpty()}
            .toList()
    }

    private fun reformatTextWithCode(html: String): String {
        return removeAllTags(replaceLocalLinks(replaceEmTags(replacePreTags(replaceCodeTags(html)))))
    }

    private fun replacePreTags(html: String): String {
        return html.replace("<pre>", "[source,java]\n----\n").replace("</pre>", "\n----\n")
    }

    private fun enhanceSignature(signature: String): String {
        return replaceSpaces(signature)
    }

    private fun getReturnTypeFromSignature(signature: String): String {
        return Regex("@[^\\s]*\\s|default ").replace(
            signature.substringBefore("(")
                .substringBeforeLast("\u00a0"), ""
        )
    }

    private fun splitToParagraphs(html: String): List<String> {
        return html.replace("</p>", "").split("\\s*<p>\\s*".toRegex()).map { it.trim() }
    }

    private fun replaceLocalLinks(html: String): String {
        val fragments: MutableList<String> = Regex("<a\\shref=\"#([^\"]*)\">([^<]*)</a>")
            .replace(html, "<<#_~$1~,$2>>").split("~").toMutableList()
        if (fragments.size > 1) {
            val iterator = fragments.listIterator()
            while (iterator.hasNext()) {
                val value = iterator.next()
                if (!value.contains("<<") && !value.contains(">>")) {
                    iterator.set(replaceSymbolsForAnchor(value))
                }
            }
        }
        return fragments.joinToString("")
    }

    private fun generateFilename(className: String): String {
        return className.replace("[<>]".toRegex(), "_")
    }
}
