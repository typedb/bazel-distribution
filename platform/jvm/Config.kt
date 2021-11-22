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

package com.vaticle.bazel.distribution.platform.jvm

import com.vaticle.bazel.distribution.common.config.getBoolean
import com.vaticle.bazel.distribution.common.config.getString
import com.vaticle.bazel.distribution.common.config.propertiesOf
import com.vaticle.bazel.distribution.common.config.requireString
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.APPLICATION_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.APPLICATION_NAME
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.ICON_PATH
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.JDK_PATH
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.MAC_ENTITLEMENTS_PATH
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.MAIN_CLASS
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.MAIN_JAR
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.OUTPUT_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.SOURCE_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.VERBOSE
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.VERSION_FILE_PATH
import com.vaticle.bazel.distribution.platform.jvm.Config.Keys.WINDOWS_WIX_TOOLSET_PATH
import java.util.Properties

fun configOf(propertiesFileContent: String): Config {
    val props = propertiesOf(propertiesFileContent)

    return Config(
        input = inputConfigOf(props),
        output = outputConfigOf(props),
        java = javaConfigOf(props),
        application = applicationConfigOf(props),
        verbose = props.getBoolean(VERBOSE, defaultValue = false)
    )
}

private fun inputConfigOf(props: Properties) = Config.Input(
    jdkPath = props.requireString(JDK_PATH),
    sourceFilename = props.requireString(SOURCE_FILENAME),
    versionFilePath = props.requireString(VERSION_FILE_PATH),
    iconPath = props.getString(ICON_PATH),
    macEntitlementsPath = props.getString(MAC_ENTITLEMENTS_PATH),
    windowsWiXToolsetPath = props.getString(WINDOWS_WIX_TOOLSET_PATH)
)

private fun outputConfigOf(props: Properties) = Config.Output(filename = props.requireString(OUTPUT_FILENAME))

private fun javaConfigOf(props: Properties) = Config.Java(
    mainJar = props.requireString(MAIN_JAR),
    mainClass = props.requireString(MAIN_CLASS)
)

private fun applicationConfigOf(props: Properties) = Config.Application(
    name = props.requireString(APPLICATION_NAME),
    filename = props.requireString(APPLICATION_FILENAME),
)

data class Config(
    val verbose: Boolean, val input: Input, val output: Output, val java: Java, val application: Application
) {
    data class Input(
        val jdkPath: String, val sourceFilename: String, val versionFilePath: String, val iconPath: String?,
        val macEntitlementsPath: String?, val windowsWiXToolsetPath: String?
    )

    data class Output(val filename: String)

    data class Java(val mainJar: String, val mainClass: String)

    data class Application(val name: String, val filename: String)

    object Keys {
        const val APPLICATION_FILENAME = "applicationFilename"
        const val APPLICATION_NAME = "applicationName"
        const val ICON_PATH = "iconPath"
        const val JDK_PATH = "jdkPath"
        const val MAC_ENTITLEMENTS_PATH = "macEntitlementsPath"
        const val MAIN_CLASS = "mainClass"
        const val MAIN_JAR = "mainJar"
        const val OUTPUT_FILENAME = "outFilename"
        const val SOURCE_FILENAME = "srcFilename"
        const val VERBOSE = "verbose"
        const val VERSION_FILE_PATH = "versionFilePath"
        const val WINDOWS_WIX_TOOLSET_PATH = "windowsWixToolsetPath"
    }
}
