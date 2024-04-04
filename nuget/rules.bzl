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


def _check_platform(platform):
    allowed_values = ("osx-arm64", "osx-x64", "linux-arm64", "linux-x64", "win-arm64", "win-x64")
    if platform not in allowed_values:
        fail("Platform must be set to any of {}. Got {} instead!".format(allowed_values, platform))


def _parse_version(ctx):
    version = ctx.attr.version
    if not version:
        version = ctx.var.get("version", "0.0.0")

    return version


def _nuget_pack_impl(ctx):
    version = _parse_version(ctx)
    nuspec = ctx.actions.declare_file("{}-generated.nuspec".format(ctx.label.name))

    # A mapping of files to the paths in which we expect to find them in the package
    paths = {}
    native_lib_declrs = ""

    if ctx.attr.platform:
        platform_suffix = ".{}".format(ctx.attr.platform)
    else:
        platform_suffix = ""

    package_name = "{}{}".format(ctx.attr.id, platform_suffix)

    if ctx.files.native_libs:
        _check_platform(ctx.attr.platform)
        native_target_dir = "runtimes/{}/native".format(ctx.attr.platform)

        for native_lib in ctx.files.native_libs:
            paths[native_lib] = native_lib.short_path
            native_lib_declrs += """    <file src="{}" target="{}" />
""".format(native_lib.short_path, native_target_dir)

    ctx.actions.expand_template(
        template = ctx.file.nuspec_template,
        output = nuspec,
        substitutions = {
            "$packageid$": package_name,
            "$version$": version,
            "$native_lib_declrs$": native_lib_declrs,
            "$target_framework$": ctx.attr.target_framework,
        },
    )

    build_flavor = "Debug" if is_debug(ctx) else "Release"

    for (lib, name) in ctx.attr.libs.items():
        assembly_info = lib[DotnetAssemblyRuntimeInfo]

        for dll in assembly_info.libs:
            paths[dll] = "lib/{}/{}.dll".format(ctx.attr.target_framework, name)
        for pdb in assembly_info.pdbs:
            paths[pdb] = "lib/{}/{}.pdb".format(ctx.attr.target_framework, name)
        for doc in assembly_info.xml_docs:
            paths[doc] = "lib/{}/{}.xml".format(ctx.attr.target_framework, name)

    csproj_template = """<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>{}</TargetFramework>
        <AssemblyName>{}</AssemblyName>
        <RootNamespace>{}</RootNamespace>
    </PropertyGroup>
</Project>
""".format(ctx.attr.target_framework, package_name, ctx.attr.id)

    csproj_file = ctx.actions.declare_file("{}-generated.csproj".format(ctx.label.name))
    ctx.actions.write(csproj_file, csproj_template)
    paths[csproj_file] = "project.csproj"

    for (file, name) in ctx.attr.files.items():
        paths[file.files.to_list()[0]] = name

    # Zip everything up so we have the right file structure
    zip_file = ctx.actions.declare_file("{}-intermediate.zip".format(ctx.label.name))
    args = ctx.actions.args()
    args.add_all(["Cc", zip_file])
    for (file, path) in paths.items():
        args.add("{}={}".format(path, file.path))
    args.add("project.nuspec={}".format(nuspec.path))

    ctx.actions.run(
        executable = ctx.executable._zip,
        arguments = [args],
        inputs = paths.keys() + [nuspec],
        outputs = [zip_file],
    )

    # Now lay everything out on disk and execute the dotnet pack rule

    # Now we have everything, let's build our package
    toolchain = ctx.toolchains["@rules_dotnet//dotnet:toolchain_type"]

    nupkg_name_stem = "{}.{}".format(package_name, version)

    dotnet = toolchain.runtime.files_to_run.executable
    pkg = ctx.actions.declare_file("{}.nupkg".format(nupkg_name_stem))
    symbols_pkg = ctx.actions.declare_file("{}.snupkg".format(nupkg_name_stem))

    # Prepare our cache of nupkg files
    packages = ctx.actions.declare_directory("{}-nuget-packages".format(ctx.label.name))
    packages_cmd = "mkdir -p {} ".format(packages.path)

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
          "mkdir {}-working-dir && ".format(ctx.label.name) + \
          "echo $(pwd) && " + \
          "$(location @bazel_tools//tools/zip:zipper) x {} -d {}-working-dir && ".format(zip_file.path, ctx.label.name) + \
          "cd {}-working-dir && ".format(ctx.label.name) + \
          "echo '<configuration><packageSources><clear /><add key=\"local\" value=\"%%CWD%%/{}\" /></packageSources></configuration>' >nuget.config && ".format(packages.path) + \
          "$DOTNET restore --no-dependencies && " + \
          "$DOTNET pack --no-build --include-symbols -p:NuspecFile=project.nuspec --include-symbols -p:SymbolPackageFormat=snupkg -p:Configuration={} -p:PackageId={} -p:Version={} -p:PackageVersion={} -p:NuspecProperties=\"version={}\" && ".format(build_flavor, package_name, version, version, version) + \
          "cp bin/{}/{}.{}.nupkg ../{} && ".format(build_flavor, package_name, version, pkg.path) + \
          "cp bin/{}/{}.{}.snupkg ../{}".format(build_flavor, package_name, version, symbols_pkg.path)

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
            runfiles = ctx.runfiles(files = [pkg, symbols_pkg]),
        ),
    ]

nuget_pack = rule(
    _nuget_pack_impl,
    attrs = {
        "id": attr.string(
            doc = "Nuget ID of the package",
            mandatory = True,
        ),
        "version": attr.string(
            doc = """
            Target package's version.
            Alternatively, pass --define version=VERSION to Bazel invocation.
            Not specifying version at all defaults to '0.0.0'
            """,
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
        "platform": attr.string(
            doc = "Target platform and architecture for platform-specific packages: {platform}-{arch}.",
            default = "",
        ),
        "native_libs": attr.label_list(
            doc = "Native libs to include into the package",
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
            doc = "Template .nuspec file with the project description",
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
    all_srcs = ctx.attr.src.files.to_list()

    package_files = []
    for package_file in ctx.attr.src.files.to_list():
        if package_file.extension == "snupkg":
            continue # .snupkg are automatically included by the nuget push command if they are in the same dir
        package_files.append(package_file)

    toolchain = ctx.toolchains["@rules_dotnet//dotnet:toolchain_type"]
    dotnet_runtime = toolchain.runtime.files_to_run.executable

    package_file_paths = []
    for package_file in package_files:
        package_file_paths.append(ctx.expand_location(package_file.short_path))

    push_file = ctx.actions.declare_file(ctx.attr.script_file_name)

    ctx.actions.expand_template(
        template = ctx.file._push_script_template,
        output = push_file,
        substitutions = {
            '{dotnet_runtime_path}': dotnet_runtime.path,
            '{nupkg_paths}': " ".join(package_file_paths),
            '{snapshot_url}': ctx.attr.snapshot_url,
            '{release_url}': ctx.attr.release_url,
        },
        is_executable = True,
    )

    return DefaultInfo(
        executable = push_file,
        runfiles = ctx.runfiles(files = all_srcs + toolchain.dotnetinfo.runtime_files),
    )


_nuget_push = rule(
    implementation = _nuget_push_impl,
    executable = True,
    attrs = {
        "src": attr.label(
            allow_files = [".nupkg", ".snupkg"],
            doc = "Nuget packages (and their debug symbol packages) to push",
        ),
        "snapshot_url" : attr.string(
            mandatory = True,
            doc = "URL of the target snapshot repository",
        ),
        "release_url" : attr.string(
            mandatory = True,
            doc = "URL of the target release repository",
        ),
        "script_file_name": attr.string(
            mandatory = True,
            doc = "Name of instantiated deployment script"
        ),
        "_push_script_template": attr.label(
            allow_single_file = True,
            default = "//nuget/templates:push.py",
        ),
    },
    toolchains = [
        "@rules_dotnet//dotnet:toolchain_type",
    ],
)


def nuget_push(name, src, snapshot_url, release_url, **kwargs):
    push_script_name = "{}_script".format(name)
    push_script_file_name = "{}-push.py".format(push_script_name)

    _nuget_push(
        name = push_script_name,
        script_file_name = push_script_file_name,
        src = src,
        snapshot_url = snapshot_url,
        release_url = release_url,
        **kwargs
    )

    native.py_binary(
        name = name,
        srcs = [push_script_name],
        main = push_script_file_name
    )
