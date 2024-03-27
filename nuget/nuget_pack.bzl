#
# Copyright (C) 2022 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# This file is based on the original implementation of https://github.com/SeleniumHQ/selenium/.

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

    ctx.actions.expand_template(
        template = ctx.file.nuspec_template,
        output = nuspec,
        substitutions = {
            "$packageid$": ctx.attr.id,
            "$version$": ctx.attr.version,
            "$osx_native_lib$": ctx.attr.osx_native_lib,
            "$linux_native_lib$": ctx.attr.linux_native_lib,
            "$win_native_lib$": ctx.attr.win_native_lib,
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
""" % (ctx.attr.target_framework, ctx.attr.id, ctx.attr.id)

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

    nupkg_name_stem = "%s.%s" % (ctx.attr.id, ctx.attr.version)

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
          "$DOTNET pack --no-build --include-symbols -p:NuspecFile=project.nuspec --include-symbols -p:SymbolPackageFormat=snupkg -p:Configuration=%s -p:PackageId=%s -p:Version=%s -p:PackageVersion=%s -p:NuspecProperties=\"version=%s\" && " % (build_flavor, ctx.attr.id, ctx.attr.version, ctx.attr.version, ctx.attr.version) + \
          "cp bin/%s/%s.%s.nupkg ../%s && " % (build_flavor, ctx.attr.id, ctx.attr.version, pkg.path) + \
          "cp bin/%s/%s.%s.snupkg ../%s" % (build_flavor, ctx.attr.id, ctx.attr.version, symbols_pkg.path)

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
        tools = [
            ctx.executable._zip,
            dotnet,
        ] + toolchain.default.files.to_list() + toolchain.runtime.default_runfiles.files.to_list() + toolchain.runtime.data_runfiles.files.to_list(),
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
        "osx_native_lib": attr.string(
            doc = "Name of the native lib compiled for OSX",
            mandatory = True,
        ),
        "linux_native_lib": attr.string(
            doc = "Name of the native lib compiled for Linux",
            mandatory = True,
        ),
        "win_native_lib": attr.string(
            doc = "Name of the native lib compiled for Windows",
            mandatory = True,
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
