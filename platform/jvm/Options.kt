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

import com.vaticle.bazel.distribution.common.util.PropertiesUtil.getBoolean
import com.vaticle.bazel.distribution.common.util.PropertiesUtil.getString
import com.vaticle.bazel.distribution.common.util.PropertiesUtil.requireString
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_CODE_SIGNING_CERT_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLE_CODE_SIGN
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLE_CODE_SIGNING_CERT_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLE_DEEP_SIGN_JARS_REGEX
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.ICON_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.IMAGE_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.IMAGE_NAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.JDK_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.MAC_ENTITLEMENTS_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.MAIN_CLASS
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.MAIN_JAR
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.OUTPUT_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.SOURCE_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.VERBOSE
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.VERSION_FILE_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.WINDOWS_WIX_TOOLSET_PATH
import java.io.File
import java.io.FileInputStream
import java.util.Properties

data class Options(val verbose: Boolean, val input: Input, val image: Image, val output: Output) {
    companion object {
        fun of(commandLineParams: CommandLineParams): Options {
            val props = Properties().apply { load(FileInputStream(commandLineParams.configFile)) }

            return Options(
                verbose = props.getBoolean(VERBOSE, defaultValue = false),
                input = Input.of(props),
                image = Image.of(commandLineParams, props),
                output = Output.of(props)
            )
        }
    }

    data class Input(
        val jdkPath: String, val sourceFilename: String, val versionFilePath: String, val iconPath: String?,
        val macEntitlementsPath: String?, val windowsWiXToolsetPath: String?
    ) {
        companion object {
            fun of(props: Properties) = Input(
                jdkPath = props.requireString(JDK_PATH),
                sourceFilename = props.requireString(SOURCE_FILENAME),
                versionFilePath = props.requireString(VERSION_FILE_PATH),
                iconPath = props.getString(ICON_PATH),
                macEntitlementsPath = props.getString(MAC_ENTITLEMENTS_PATH),
                windowsWiXToolsetPath = props.getString(WINDOWS_WIX_TOOLSET_PATH)
            )
        }
    }

    data class Image(val name: String, val filename: String, val java: Java, val appleCodeSigning: AppleCodeSigning?) {
        val appleCodeSigningEnabled: Boolean = appleCodeSigning != null

        companion object {
            fun of(commandLineParams: CommandLineParams, props: Properties) = Image(
                name = props.requireString(IMAGE_NAME),
                filename = props.requireString(IMAGE_FILENAME),
                java = Java.of(props),
                appleCodeSigning = if (APPLE_CODE_SIGN in props) AppleCodeSigning.of(commandLineParams, props) else null
            )
        }
    }

    data class Output(val filename: String) {
        companion object {
            fun of(props: Properties) = Output(filename = props.requireString(OUTPUT_FILENAME))
        }
    }

    data class Java(val mainJar: String, val mainClass: String) {
        companion object {
            fun of(props: Properties) = Java(
                mainJar = props.requireString(MAIN_JAR),
                mainClass = props.requireString(MAIN_CLASS)
            )
        }
    }

    private object Keys {
        const val APPLE_CODE_SIGN = "appleCodeSign"
        const val APPLE_CODE_SIGNING_CERT_PATH = "appleCodeSigningCertPath"
        const val APPLE_DEEP_SIGN_JARS_REGEX = "appleDeepSignJarsRegex"
        const val ICON_PATH = "iconPath"
        const val IMAGE_FILENAME = "imageFilename"
        const val IMAGE_NAME = "imageName"
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

    data class AppleCodeSigning(
        val appleID: String, val appleIDPassword: String, val cert: File, val certPassword: String,
        val deepSignJarsRegex: Regex?
    ) {
        val signNativeLibsInDeps: Boolean = deepSignJarsRegex != null

        companion object {
            fun of(commandLineParams: CommandLineParams, props: Properties) = commandLineParams.run {
                AppleCodeSigning(
                    appleID = require(APPLE_ID, appleID),
                    appleIDPassword = require(APPLE_ID_PASSWORD, appleIDPassword),
                    cert = File(props.requireString(APPLE_CODE_SIGNING_CERT_PATH)),
                    certPassword = require(APPLE_CODE_SIGNING_CERT_PASSWORD, appleCodeSigningCertPassword),
                    deepSignJarsRegex = props.getString(APPLE_DEEP_SIGN_JARS_REGEX)?.let { Regex(it) }
                )
            }

            private fun <T> require(key: String, value: T?): T {
                if (value == null || value is String && value.isBlank()) {
                    throw IllegalStateException("'$key' must be set if '${APPLE_CODE_SIGNING_CERT_PATH}' is set")
                }
                return value
            }
        }

        override fun toString(): String {
            return "Options.AppleCodeSigning: deepSignJarsRegex=$deepSignJarsRegex; (credentials hidden)"
        }
    }
}
