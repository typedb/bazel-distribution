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

package com.vaticle.typedb.driver.tool.docs.adoc

class AsciiDocBuilder {
    fun header(level: Int, header: String): String {
        return "=".repeat(level) + " $header\n\n"
    }

    fun anchor(link: String): String {
        return "[#_$link]\n"
    }

    fun boldHeader(header: String): String {
        return "*$header*\n\n"
    }

    fun caption(title: String): String {
        return "[caption=\"\"]\n.$title\n"
    }

    fun captionedBlock(title: String, content: String): String {
        return caption(title) + "====\n\n$content====\n\n"
    }

    fun codeBlock(content: String?, language: String?): String {
        var result = "[source"
        language?.let { result += ",$language" }
        result += "]\n----\n$content\n----\n\n"
        return result
    }

    fun tagBegin(title: String): String {
        return "// tag::$title[]\n"
    }

    fun tagEnd(title: String): String {
        return "// end::$title[]\n\n"
    }

    fun unorderedList(items: Iterable<String>): String {
        return items.joinToString("\n") { "* `$it`" }
    }

    fun tabs(items: Iterable<Pair<String, String>>): String {
        var result = "[tabs]\n====\n"
        result += items.joinToString("\n") { (tabName, content) ->
            "$tabName::\n+\n--\n$content--\n"
        }
        result += "====\n\n"
        return result
    }

    /**
     * Gets the list if pairs {tab_caption, tab_content} and produces tabs if not all elements are equal
     */
    fun tabsIfNotEqual(tabs: List<Pair<String, String>>): String {
        return if (tabs.all { it.second == tabs[0].second }) {
            tabs[0].second
        } else {
            this.tabs(tabs.sortedBy { it.first })
        }
    }
}
