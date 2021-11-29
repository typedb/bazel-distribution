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

import com.vaticle.bazel.distribution.common.util.PropertiesUtil.getBooleanOrDefault
import com.vaticle.bazel.distribution.common.util.PropertiesUtil.getStringOrNull
import com.vaticle.bazel.distribution.common.util.PropertiesUtil.requireString
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_CODE_SIGNING_CERT_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID
import com.vaticle.bazel.distribution.platform.jvm.CommandLineParams.Keys.APPLE_ID_PASSWORD
import com.vaticle.bazel.distribution.platform.jvm.JVMPlatformAssembler.logger
import com.vaticle.bazel.distribution.platform.jvm.Logging.Logger
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLE_CODE_SIGN
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLE_CODE_SIGNING_CERT_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.APPLE_DEEP_SIGN_JARS_REGEX
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.COPYRIGHT
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.CREATE_SHORTCUT
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.ICON_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.DESCRIPTION
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.IMAGE_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.IMAGE_NAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.VENDOR
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.JDK_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.LICENSE_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.LINUX_APP_CATEGORY
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.LINUX_MENU_GROUP
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.MAC_ENTITLEMENTS_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.MAIN_CLASS
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.MAIN_JAR
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.OUTPUT_ARCHIVE_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.SOURCE_FILENAME
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.VERBOSE
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.VERSION_FILE_PATH
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.WINDOWS_MENU_GROUP
import com.vaticle.bazel.distribution.platform.jvm.Options.Keys.WINDOWS_WIX_TOOLSET_PATH
import java.io.File
import java.io.FileInputStream
import java.util.Properties

data class Options(val verbose: Boolean, val input: Input, val image: Image, val launcher: Launcher, val output: Output) {
    companion object {
        fun of(commandLineParams: CommandLineParams): Options {
            val props = Properties().apply { load(FileInputStream(commandLineParams.configFile)) }
            val verbose = props.getBooleanOrDefault(VERBOSE, defaultValue = false)
            logger = Logger(logLevel = if (verbose) Logging.LogLevel.DEBUG else Logging.LogLevel.ERROR)

            if (verbose) {
                logger.debug { "" }
                logger.debug { "Parsed properties: " }
                props.forEach { (key, value) -> logger.debug { "$key=$value" } }
                logger.debug { "" }
            }

            return Options(
                verbose = verbose,
                input = Input.of(props),
                image = Image.of(commandLineParams, props),
                launcher = Launcher.of(props),
                output = Output.of(props)
            )
        }
    }

    data class Input(
        val jdkPath: String, val sourceFilename: String, val versionFilePath: String, val iconPath: String?,
        val licensePath: String?, val macEntitlementsPath: String?, val windowsWiXToolsetPath: String?
    ) {
        companion object {
            fun of(props: Properties) = Input(
                jdkPath = props.requireString(JDK_PATH),
                sourceFilename = props.requireString(SOURCE_FILENAME),
                versionFilePath = props.requireString(VERSION_FILE_PATH),
                iconPath = props.getStringOrNull(ICON_PATH),
                licensePath = props.getStringOrNull(LICENSE_PATH),
                macEntitlementsPath = props.getStringOrNull(MAC_ENTITLEMENTS_PATH),
                windowsWiXToolsetPath = props.getStringOrNull(WINDOWS_WIX_TOOLSET_PATH)
            )
        }
    }

    data class Image(
        val name: String, val description: String?, val vendor: String?, val copyright: String?,
        val filename: String, val appleCodeSigning: AppleCodeSigning?
    ) {
        val appleCodeSigningEnabled: Boolean = appleCodeSigning != null

        companion object {
            fun of(commandLineParams: CommandLineParams, props: Properties) = Image(
                name = props.requireString(IMAGE_NAME),
                description = props.getStringOrNull(DESCRIPTION),
                vendor = props.getStringOrNull(VENDOR),
                copyright = props.getStringOrNull(COPYRIGHT),
                filename = props.requireString(IMAGE_FILENAME),
                appleCodeSigning = if (APPLE_CODE_SIGN in props.keys) AppleCodeSigning.of(commandLineParams, props) else null
            )
        }
    }

    data class Launcher(val mainJar: String, val mainClass: String, val createShortcut: Boolean, val linux: Linux, val windows: Windows) {
        companion object {
            fun of(props: Properties) = Launcher(
                mainJar = props.requireString(MAIN_JAR),
                mainClass = props.requireString(MAIN_CLASS),
                createShortcut = props.getBooleanOrDefault(CREATE_SHORTCUT, defaultValue = false),
                linux = Linux.of(props),
                windows = Windows.of(props)
            )
        }

        data class Linux(val menuGroup: String?, val appCategory: String?) {
            companion object {
                fun of(props: Properties) = Linux(
                    menuGroup = props.getStringOrNull(LINUX_MENU_GROUP),
                    appCategory = props.getStringOrNull(LINUX_APP_CATEGORY)
                )
            }
        }

        data class Windows(val menuGroup: String?) {
            companion object {
                fun of(props: Properties) = Windows(menuGroup = props.getStringOrNull(WINDOWS_MENU_GROUP))
            }
        }
    }

    data class Output(val archivePath: String) {
        companion object {
            fun of(props: Properties) = Output(archivePath = props.requireString(OUTPUT_ARCHIVE_PATH))
        }
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
                    deepSignJarsRegex = props.getStringOrNull(APPLE_DEEP_SIGN_JARS_REGEX)?.let { Regex(it) }
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

    private object Keys {
        const val APPLE_CODE_SIGN = "appleCodeSign"
        const val APPLE_CODE_SIGNING_CERT_PATH = "appleCodeSigningCertPath"
        const val APPLE_DEEP_SIGN_JARS_REGEX = "appleDeepSignJarsRegex"
        const val COPYRIGHT = "copyright"
        const val CREATE_SHORTCUT = "createShortcut"
        const val DESCRIPTION = "description"
        const val ICON_PATH = "iconPath"
        const val IMAGE_FILENAME = "imageFilename"
        const val IMAGE_NAME = "imageName"
        const val JDK_PATH = "jdkPath"
        const val LICENSE_PATH = "licensePath"
        const val LINUX_APP_CATEGORY = "linuxAppCategory"
        const val LINUX_MENU_GROUP = "linuxMenuGroup"
        const val MAC_ENTITLEMENTS_PATH = "macEntitlementsPath"
        const val MAIN_CLASS = "mainClass"
        const val MAIN_JAR = "mainJar"
        const val OUTPUT_ARCHIVE_PATH = "outputArchivePath"
        const val SOURCE_FILENAME = "srcFilename"
        const val VENDOR = "vendor"
        const val VERBOSE = "verbose"
        const val VERSION_FILE_PATH = "versionFilePath"
        const val WINDOWS_MENU_GROUP = "windowsMenuGroup"
        const val WINDOWS_WIX_TOOLSET_PATH = "windowsWiXToolsetPath"
    }
}
