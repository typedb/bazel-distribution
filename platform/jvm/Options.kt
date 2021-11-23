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
import com.vaticle.bazel.distribution.common.config.requireString
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_CODE_SIGNING_CERT_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_CODE_SIGNING_CERT_PATH
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLICATION_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLICATION_NAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.ICON_PATH
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

data class Options(
    val verbose: Boolean, val input: Input, val output: Output, val java: Java,
    val application: Application, val appleCodeSigning: AppleCodeSigning?
) {
    val appleCodeSigningEnabled: Boolean = appleCodeSigning != null

    companion object {
        fun of(commandLineParams: CommandLineParams): Options {
            val props = Properties().apply { load(FileInputStream(commandLineParams.configPath)) }

            return Options(
                input = Input.of(props),
                output = Output.of(props),
                java = Java.of(props),
                application = Application.of(props),
                verbose = props.getBoolean(VERBOSE, defaultValue = false),
                appleCodeSigning = if (commandLineParams.appleCodeSign) AppleCodeSigning.of(commandLineParams) else null
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

    data class Application(val name: String, val filename: String) {
        companion object {
            fun of(props: Properties) = Application(
                name = props.requireString(APPLICATION_NAME),
                filename = props.requireString(APPLICATION_FILENAME)
            )
        }
    }

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

    data class AppleCodeSigning(
        val appleID: String, val appleIDPassword: String, val certificatePath: File, val certificatePassword: String
    ) {
        companion object {
            fun of(commandLineParams: CommandLineParams) = commandLineParams.run {
                AppleCodeSigning(
                    appleID = require(APPLE_ID, appleID),
                    appleIDPassword = require(APPLE_ID_PASSWORD, appleIDPassword),
                    certificatePath = require(APPLE_CODE_SIGNING_CERT_PATH, appleCodeSigningCertPath),
                    certificatePassword = require(APPLE_CODE_SIGNING_CERT_PASSWORD, appleCodeSigningCertPassword)
                )
            }

            private fun <T> require(key: String, value: T): T {
                if (value == null || value is String && value.isBlank()) {
                    throw IllegalStateException("'$key' must be set if '${APPLE_CODE_SIGNING_CERT_PATH}' is set")
                }
                return value
            }
        }

        override fun toString(): String {
            return "Options.AppleCodeSigning: (credentials hidden)"
        }
    }
}
