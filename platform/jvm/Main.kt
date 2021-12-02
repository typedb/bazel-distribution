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

import picocli.CommandLine

fun parseCommandLine(args: Array<String>): Options {
    val commandLine = CommandLine(CommandLineParams())
    val parseResult: CommandLine.ParseResult = commandLine.parseArgs(*args)
    assert(parseResult.asCommandLineList().size == 1)
    val parameters: CommandLineParams = parseResult.asCommandLineList()[0].getCommand<CommandLineParams>()
    return Options.of(parameters)
}

fun main(args: Array<String>) {
    JVMPlatformAssembler.run {
        init(options = parseCommandLine(args))
        assemble()
    }
}
