#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# This file is based on the original implementation of https://github.com/SeleniumHQ/selenium/.

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_dotnet//dotnet/private:common.bzl", "is_debug")
load("@rules_dotnet//dotnet/private:providers.bzl", "DotnetAssemblyRuntimeInfo")

# The change to the PATH is recommended here:
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual?source=recommendations#set-environment-variables-system-wide
# We list our .Net installation first because we
# want it to be picked up first

# The `MSBuildEnableWorkloadResolver` is disabled to prevent warnings
# about a missing Microsoft.NET.SDK.WorkloadAutoImportPropsLocator

def dotnet_preamble(toolchain):
    return """
export DOTNET="$(pwd)/{dotnet}"
export DOTNET_CLI_HOME="$(dirname $DOTNET)"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export DOTNET_ROOT="$(dirname $DOTNET)"
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH
export MSBuildEnableWorkloadResolver=false
export CWD=$(pwd)

# Required to make packing work on Windows
export APPDATA="$(pwd)"
export PROGRAMFILES="$(pwd)"

# Required to make NuGet tool work on non-writable home path like GitHub actions
export XDG_DATA_HOME=$(mktemp -d)

# Create `global.json` to trick .Net into using the hermetic toolchain
# https://learn.microsoft.com/en-us/dotnet/core/tools/global-json
echo '{{"sdk": {{"version": "{version}"}} }}' >$(pwd)/global.json

""".format(
        dotnet = toolchain.runtime.files_to_run.executable.path,
        version = toolchain.dotnetinfo.sdk_version,
    )


def nuget_pack_impl(ctx):
    nuspec = ctx.actions.declare_file("%s-generated.nuspec" % ctx.label.name)

    current_arch = ""

    native_lib_files = ""

    native_lib = None

    if ctx.attr.mac_native_lib:
        native_lib = ctx.attr.mac_native_lib
        current_arch = ".osx-x64"

    if ctx.attr.linux_native_lib:
        native_lib = ctx.attr.linux_native_lib
        current_arch = ".linux-x64"

    if ctx.attr.win_native_lib:
        native_lib = ctx.attr.win_native_lib
        current_arch = ".win-x64"

    package_name = "%s%s"  % (ctx.attr.id, current_arch)

    if native_lib:
        target_dir = "runtimes/{}/native"
        if current_arch == ".osx-arm64":
            target_dir = target_dir.format("osx-arm64")
        elif current_arch == ".osx-x64":
            target_dir = target_dir.format("osx-x64")
        elif current_arch == ".linux-arm64":
            target_dir = target_dir.format("linux-arm64")
        elif current_arch == ".linux-x64":
            target_dir = target_dir.format("linux-x64")
        elif current_arch == ".win-arm64":
            target_dir = target_dir.format("win-arm64")
        elif current_arch == ".win-x64":
            target_dir = target_dir.format("win-x64")

        native_ref_template = """    <file src="%s" target="%s" />
"""
        native_lib_files += native_ref_template % (native_lib, target_dir)

    ctx.actions.expand_template(
        template = ctx.file.nuspec_template,
        output = nuspec,
        substitutions = {
            "$packageid$": package_name,
            "$version$": ctx.attr.version,
            "$native_lib_files$": native_lib_files,
            "$target_framework$": ctx.attr.target_framework,
        },
    )

    build_flavor = "Debug" if is_debug(ctx) else "Release"

    # A mapping of files to the paths in which we expect to find them in the package
    paths = {}

    for (lib, name) in ctx.attr.libs.items():
        assembly_info = lib[DotnetAssemblyRuntimeInfo]

        for dll in assembly_info.libs:
            paths[dll] = "lib/%s/%s.dll" % (ctx.attr.target_framework, name)
        for pdb in assembly_info.pdbs:
            paths[pdb] = "lib/%s/%s.pdb" % (ctx.attr.target_framework, name)
        for doc in assembly_info.xml_docs:
            paths[doc] = "lib/%s/%s.xml" % (ctx.attr.target_framework, name)

    csproj_template = """<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>%s</TargetFramework>
        <AssemblyName>%s</AssemblyName>
        <RootNamespace>%s</RootNamespace>
    </PropertyGroup>
</Project>
""" % (ctx.attr.target_framework, package_name, ctx.attr.id)

    csproj_file = ctx.actions.declare_file("%s-generated.csproj" % ctx.label.name)
    ctx.actions.write(csproj_file, csproj_template)
    paths[csproj_file] = "project.csproj"

    for (file, name) in ctx.attr.files.items():
        paths[file.files.to_list()[0]] = name

    # Zip everything up so we have the right file structure
    zip_file = ctx.actions.declare_file("%s-intermediate.zip" % ctx.label.name)
    args = ctx.actions.args()
    args.add_all(["Cc", zip_file])
    for (file, path) in paths.items():
        args.add("%s=%s" % (path, file.path))
    args.add("project.nuspec=%s" % (nuspec.path))

    ctx.actions.run(
        executable = ctx.executable._zip,
        arguments = [args],
        inputs = paths.keys() + [nuspec],
        outputs = [zip_file],
    )

    # Now lay everything out on disk and execute the dotnet pack rule

    # Now we have everything, let's build our package
    toolchain = ctx.toolchains["@rules_dotnet//dotnet:toolchain_type"]

    nupkg_name_stem = "%s.%s" % (package_name, ctx.attr.version)

    dotnet = toolchain.runtime.files_to_run.executable
    pkg = ctx.actions.declare_file("%s.nupkg" % nupkg_name_stem)
    symbols_pkg = ctx.actions.declare_file("%s.snupkg" % nupkg_name_stem)

    # Prepare our cache of nupkg files
    packages = ctx.actions.declare_directory("%s-nuget-packages" % ctx.label.name)
    packages_cmd = "mkdir -p %s " % packages.path

    transitive_libs = depset(transitive = [l[DotnetAssemblyRuntimeInfo].deps for l in ctx.attr.libs]).to_list()
    package_files = depset([lib.nuget_info.nupkg for lib in transitive_libs if lib.nuget_info]).to_list()

    if len(package_files):
        packages_cmd += "&& cp " + " ".join([f.path for f in package_files]) + " " + packages.path

    ctx.actions.run_shell(
        outputs = [packages],
        inputs = package_files,
        command = packages_cmd,
        mnemonic = "LayoutNugetPackages",
    )

    cmd = dotnet_preamble(toolchain) + \
          "mkdir %s-working-dir && " % ctx.label.name + \
          "echo $(pwd) && " + \
          "$(location @bazel_tools//tools/zip:zipper) x %s -d %s-working-dir && " % (zip_file.path, ctx.label.name) + \
          "cd %s-working-dir && " % ctx.label.name + \
          "echo '<configuration><packageSources><clear /><add key=\"local\" value=\"%%CWD%%/%s\" /></packageSources></configuration>' >nuget.config && " % packages.path + \
          "$DOTNET restore --no-dependencies && " + \
          "$DOTNET pack --no-build --include-symbols -p:NuspecFile=project.nuspec --include-symbols -p:SymbolPackageFormat=snupkg -p:Configuration=%s -p:PackageId=%s -p:Version=%s -p:PackageVersion=%s -p:NuspecProperties=\"version=%s\" && " % (build_flavor, package_name, ctx.attr.version, ctx.attr.version, ctx.attr.version) + \
          "cp bin/%s/%s.%s.nupkg ../%s && " % (build_flavor, package_name, ctx.attr.version, pkg.path) + \
          "cp bin/%s/%s.%s.snupkg ../%s" % (build_flavor, package_name, ctx.attr.version, symbols_pkg.path)

    cmd = ctx.expand_location(
        cmd,
        targets = [
            ctx.attr._zip,
        ],
    )

    ctx.actions.run_shell(
        outputs = [pkg, symbols_pkg],
        inputs = [
            zip_file,
            dotnet,
            packages,
        ],
        tools = [ctx.executable._zip, dotnet]
            + toolchain.default.files.to_list()
            + toolchain.runtime.default_runfiles.files.to_list()
            + toolchain.runtime.data_runfiles.files.to_list(),
        command = cmd,
        mnemonic = "CreateNupkg",
    )

    return [
        DefaultInfo(
            files = depset([pkg, symbols_pkg]),
#            files = depset([pkg]),
#            runfiles = ctx.runfiles(files = [pkg]),
            runfiles = ctx.runfiles(files = [pkg, symbols_pkg]),
        ),
    ]

nuget_pack = rule(
    nuget_pack_impl,
    attrs = {
        "id": attr.string(
            doc = "Nuget ID of the package",
            mandatory = True,
        ),
        "version": attr.string(
            mandatory = True,
        ),
        "libs": attr.label_keyed_string_dict(
            doc = "The .Net libraries that are being published",
            providers = [DotnetAssemblyRuntimeInfo],
        ),
        "files": attr.label_keyed_string_dict(
            doc = "Mapping of files to paths within the nuget package",
            allow_empty = True,
            allow_files = True,
        ),
        "mac_native_lib": attr.string(
            doc = "Name of the native lib compiled for MacOS",
        ),
        "linux_native_lib": attr.string(
            doc = "Name of the native lib compiled for Linux",
        ),
        "win_native_lib": attr.string(
            doc = "Name of the native lib compiled for Windows",
        ),
        "target_framework": attr.string(
            doc = "Target C# build framework",
            mandatory = True,
        ),
        "property_group_vars": attr.string_dict(
            doc = "Keys and values for variables declared in `PropertyGroup`s in the `csproj_file`",
            allow_empty = True,
        ),
        "nuspec_template": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "_zip": attr.label(
            default = "@bazel_tools//tools/zip:zipper",
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_dotnet//dotnet:toolchain_type"],
)

def _nuget_push_impl(ctx):
    apikey = ""

    all_srcs = ctx.attr.src.files.to_list()

    package_files = []
    for package_file in ctx.attr.src.files.to_list():
        if package_file.extension == "snupkg":
            continue # .snupkg are automatically included by the nuget push command if they are in the same dir
        package_files.append(package_file)

    csharp_toolchain = ctx.toolchains["@rules_dotnet//dotnet:toolchain_type"]
    dotnet_runtime = csharp_toolchain.dotnetinfo.runtime_files[0]

    package_file_paths = []
    for package_file in package_files:
        package_file_paths.append(ctx.expand_location(package_file.short_path))

    package_file = package_files[0]

    push_file = ctx.actions.declare_file("%s-push.py" % ctx.label.name)

    ctx.actions.expand_template(
        template = ctx.file._push_script_template,
        output = push_file,
        substitutions = {
            '{dotnet_runtime_path}': dotnet_runtime.path,
#            '{nupkg_path}': ctx.expand_location(package_file.short_path),
            '{nupkg_path}': " ".join(package_file_paths),
            '{api_key}': apikey,
            '{target_repo_url}': ctx.attr.repository_url,
        },
        is_executable = True,
    )

    return DefaultInfo(
        executable = push_file,
        runfiles = ctx.runfiles(files = all_srcs + [dotnet_runtime])
    )


nuget_push = rule(
    implementation = _nuget_push_impl,
    executable = True,
    attrs = {
        "src": attr.label(
            allow_files = [".nupkg", ".snupkg"],
            doc = "Nuget packages (and their debug symbol packages) to push",
        ),
        "repository_url": attr.string(
            mandatory = True,
            doc = "URL of the target repository",
        ),
        "_push_script_template": attr.label(
            allow_single_file = True,
            default = "//nuget/templates:push.py",
        ),
    },
#    outputs = {
#        "push_script": "push.py"
#    },
    toolchains = [
        "@rules_dotnet//dotnet:toolchain_type",
    ],
)
