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

package com.vaticle.bazel.distribution.common.config

import java.io.StringReader
import java.util.Properties

fun require(key: String, value: String?): String {
    if (value.isNullOrBlank()) throw IllegalStateException("Missing value for required property '$key'")
    return value
}

fun propertiesOf(value: String): Properties {
    return Properties().apply { load(StringReader(value)) }
}

fun Properties.getString(key: String): String? {
    return getProperty(key)
}

fun Properties.requireString(key: String): String {
    return require(key, getProperty(key))
}

fun Properties.getBoolean(key: String, defaultValue: Boolean = false): Boolean {
    return getProperty(key)?.toBoolean() ?: defaultValue
}

fun Properties.requireBoolean(key: String): Boolean {
    return require(key, getProperty(key)).toBoolean()
}
