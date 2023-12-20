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

class AsciiDocTableBuilder(private val headers: List<String>) {
    private val rows: MutableList<List<String?>> = mutableListOf()

    fun addRow(row: List<String?>) {
        assert(this.headers.size == row.size)
        rows.add(row)
    }

    fun build(): String {
        return this.header() + this.body()
    }

    private fun header(): String {
        return "[cols=\"~" + ",~".repeat(this.headers.size - 1) +
                "\"]\n[options=\"header\"]\n" +
                "|===\n|" +
                headers.joinToString(" |") + "\n"
    }

    private fun body(): String {
        return rows.joinToString("") { this.row(it) } + "|===\n"
    }

    private fun row(row: List<String?>): String {
        return "a| " + row.joinToString(" a| ") + "\n"
    }
}
