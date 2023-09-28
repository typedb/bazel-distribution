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

load("@vaticle_bazel_distribution//common:rules.bzl", _assemble_zip = "assemble_zip", _java_deps = "java_deps")


supported_oses = ["Mac", "Linux", "Windows"]


def _require_apple_code_signing_attr(attr, name):
    if not attr:
        fail("Parameter {} must be set if variable APPLE_CODE_SIGN is set".format(attr))


def _require_apple_code_signing_file(file, name):
    if not file:
        fail("Parameter {} must be set if variable APPLE_CODE_SIGN is set".format(name))


def _require_apple_code_signing_var(ctx, var):
    if var not in ctx.var:
        fail("Variable {} must be set if variable APPLE_CODE_SIGN is set".format(var))


def _assemble_zip_to_jvm_platform_impl(ctx):
    if (ctx.attr.os not in supported_oses):
        fail("assemble_jvm_platform is not supported on this operating system")

    # TODO: copied from bazel-distribution/pip/rules.bzl
    if not ctx.attr.version_file:
        version_file = ctx.actions.declare_file(ctx.attr.name + "__do_not_reference.version")
        version = ctx.var.get('version', '0.0.0')

        if len(version) == 40:
            # this is a commit SHA, most likely
            version = "0.0.0-{}".format(version)

        ctx.actions.run_shell(
            inputs = [],
            outputs = [version_file],
            command = "echo {} > {}".format(version, version_file.path)
        )
    else:
        version_file = ctx.file.version_file

    progress_message = "Assembling {} image for {}".format(ctx.attr.image_name, ctx.attr.os)

    config = """
verbose: {}
logSensitiveData: {}
jdkPath: {}
srcFilename: {}
imageName: {}
imageFilename: {}
versionFilePath: {}
jarsPath: {}
mainJarPath: {}
mainClass: {}
createShortcut: {}
outputArchivePath: {}
""".format(
    ctx.attr.verbose,
    ctx.attr.log_sensitive_data,
    ctx.file.jdk.path,
    ctx.file.assemble_zip.path,
    ctx.attr.image_name,
    ctx.attr.image_filename,
    version_file.path,
    ctx.attr.jars_path,
    ctx.attr.main_jar_path,
    ctx.attr.main_class,
    ctx.attr.create_shortcut,
    ctx.outputs.distribution_file.path
    )

    if "APPLE_CODE_SIGN" in ctx.var and ctx.var["APPLE_CODE_SIGN"].lower() in "yes, true":
        _require_apple_code_signing_file(ctx.file.mac_entitlements, "mac_entitlements")
        _require_apple_code_signing_file(ctx.file.mac_code_signing_cert, "mac_code_signing_cert")
        _require_apple_code_signing_attr(ctx.attr.mac_app_id, "mac_app_id")

        config = config + """
appleCodeSign: True
appleCodeSigningCertPath: {}
macAppID: {}
""".format(ctx.file.mac_code_signing_cert.path, ctx.attr.mac_app_id)

        progress_message = progress_message + " (NOTE: notarization typically takes several minutes to complete)"

    inputs = [ctx.file.jdk, ctx.file.assemble_zip, version_file]

    # TODO: refactor into a less repetitive structure, perhaps constructing 'config' in one go using a 'dict'?
    if ctx.attr.description:
        config = config + """
description: {}
""".format(ctx.attr.description)

    if ctx.attr.vendor:
        config = config + """
vendor: {}
""".format(ctx.attr.vendor)

    if ctx.attr.copyright:
        config = config + """
copyright: {}
""".format(ctx.attr.copyright)

    if ctx.attr.linux_app_category:
        config = config + """
linuxAppCategory: {}
""".format(ctx.attr.linux_app_category)

    if ctx.attr.linux_menu_group:
        config = config + """
linuxMenuGroup: {}
""".format(ctx.attr.linux_menu_group)

    if ctx.attr.mac_deep_sign_jars_regex:
        config = config + """
appleDeepSignJarsRegex: {}
""".format(ctx.attr.mac_deep_sign_jars_regex)

    if ctx.attr.windows_menu_group:
        config = config + """
windowsMenuGroup: {}
""".format(ctx.attr.windows_menu_group)

    if ctx.file.icon:
        inputs = inputs + [ctx.file.icon]
        config = config + """
iconPath: {}
""".format(ctx.file.icon.path)

    if ctx.file.license_file:
        inputs = inputs + [ctx.file.license_file]
        config = config + """
licensePath: {}
""".format(ctx.file.license_file.path)

    if ctx.file.mac_entitlements:
        inputs = inputs + [ctx.file.mac_entitlements]
        config = config + """
macEntitlementsPath: {}
""".format(ctx.file.mac_entitlements.path)

    if ctx.file.windows_wix_toolset:
        inputs = inputs + [ctx.file.windows_wix_toolset]
        config = config + """
windowsWiXToolsetPath: {}
""".format(ctx.file.windows_wix_toolset.path)

    config_file = ctx.actions.declare_file(ctx.attr.name + "__config.properties")
    ctx.actions.run_shell(
        inputs = [],
        outputs = [config_file],
        command = "echo \"{}\" > {}".format(config, config_file.path)
    )

    config_path_arg = "--config_path={}".format(config_file.path)
    if "APPLE_CODE_SIGN" in ctx.var and ctx.var["APPLE_CODE_SIGN"] == "yes":
        _require_apple_code_signing_var(ctx, "APPLE_ID")
        _require_apple_code_signing_var(ctx, "APPLE_ID_PASSWORD")
        _require_apple_code_signing_var(ctx, "APPLE_CODE_SIGNING_CERT_PASSWORD")

        arguments = [
            config_path_arg,
            "--apple_id={}".format(ctx.var["APPLE_ID"]),
            "--apple_id_password={}".format(ctx.var["APPLE_ID_PASSWORD"]),
            "--apple_code_signing_cert_password={}".format(ctx.var["APPLE_CODE_SIGNING_CERT_PASSWORD"])
        ]
    else:
        arguments = [config_path_arg]

    ctx.actions.run(
        inputs = inputs + [config_file],
        outputs = [ctx.outputs.distribution_file],
        executable = ctx.executable._assemble_jvm_platform_bin,
        arguments = arguments,
        progress_message = progress_message,
    )

    return DefaultInfo(data_runfiles = ctx.runfiles(files=[ctx.outputs.distribution_file]))


_assemble_zip_to_jvm_platform = rule(
    attrs = {
        "assemble_zip": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The ZIP assembly to pack into a platform-native application",
        ),
        "image_name": attr.string(
            mandatory = True,
            doc = "The application image name",
        ),
        "image_filename": attr.string(
            mandatory = True,
            doc = "The application image filename",
        ),
        "description": attr.string(
            doc = "The application description",
        ),
        "vendor": attr.string(
            doc = "The application vendor",
        ),
        "copyright": attr.string(
            doc = "The application's copyright text",
        ),
        "license_file": attr.label(
            allow_single_file = True,
            doc = "The license file",
        ),
        "icon": attr.label(
            allow_single_file = True,
            doc = "The application icon",
        ),
        "version_file": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The version file",
        ),
        "jdk": attr.label(
            allow_single_file = True,
            doc = "Archive containing the JDK, which must be at least version 16",
        ),
        "jars_path": attr.string(
            mandatory = True,
            doc = "The location of the JARs to be packed into this image",
        ),
        "main_jar_path": attr.string(
            mandatory = True,
            doc = "The path of the JAR containing the main function, relative to the jar_path",
        ),
        "main_class": attr.string(
            mandatory = True,
            doc = "The main class name, which must be fully qualified (using the full package address)",
        ),
        "os": attr.string(
            mandatory = True,
            doc = "The host OS",
        ),
        "verbose": attr.bool(
            mandatory = True,
            doc = "Enable verbose output for debugging",
        ),
        "log_sensitive_data": attr.bool(
            mandatory = True,
            doc = "If enabled, sensitive data including passwords will be included in the output logs",
        ),
        "create_shortcut": attr.bool(
            mandatory = True,
            doc = "Whether to create a shortcut for the application (on systems that support desktop shortcuts)",
        ),
        "linux_app_category": attr.string(
            doc = "'Section' value of the DEB control file on Debian-based Linux systems",
        ),
        "linux_menu_group": attr.string(
            doc = "Menu group this application is placed in on Linux, defining the categories under which the application will be classified",
        ),
        "mac_app_id": attr.string(
            doc = "On Mac, the primary bundle ID that uniquely identifies the application, which is submitted to Apple's notarization service to verify the app",
        ),
        "mac_entitlements": attr.label(
            allow_single_file = True,
            doc = "The Mac entitlements.mac.plist file",
        ),
        "mac_code_signing_cert": attr.label(
            allow_single_file = True,
            doc = "The Mac code signing certificate",
        ),
        "mac_deep_sign_jars_regex": attr.string(
            doc = "On Mac, JARs in the Java deps whose names match this regex will be repackaged with their native libraries signed",
        ),
        "windows_menu_group": attr.string(
            doc = "Start Menu group this application is placed in on Windows. If unset, the application will not be placed in the Start Menu",
        ),
        "windows_wix_toolset": attr.label(
            allow_single_file = True,
            doc = "Archive containing the Windows WiX toolset",
        ),
        "_assemble_jvm_platform_bin": attr.label(
            default = "@vaticle_bazel_distribution//platform/jvm:assembler-bin",
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {
        "distribution_file": "%{name}.zip"
    },
    implementation = _assemble_zip_to_jvm_platform_impl,
    doc = "A JVM application image",
)


def native_jdk17():
    return select({
        "@vaticle_bazel_distribution//platform:is_linux_arm64": "@jdk17_linux_arm64//file",
        "@vaticle_bazel_distribution//platform:is_linux_x86_64": "@jdk17_linux_x86_64//file",
        "@vaticle_bazel_distribution//platform:is_mac_arm64": "@jdk17_mac_arm64//file",
        "@vaticle_bazel_distribution//platform:is_mac_x86_64": "@jdk17_mac_x86_64//file",
        "@vaticle_bazel_distribution//platform:is_windows_x86_64": "@jdk17_windows_x86_64//file",
    })

def assemble_jvm_platform(name,
                          image_name,
                          image_filename,
                          description,
                          vendor,
                          copyright,
                          license_file,
                          version_file,
                          java_deps,
                          java_deps_root,
                          main_jar_path,
                          main_class,
                          icon = None,
                          jdk = native_jdk17(),
                          additional_files = {},
                          verbose = False,
                          log_sensitive_data = False,
                          create_shortcut = True,
                          linux_app_category = None,
                          linux_menu_group = None,
                          mac_app_id = None,
                          mac_entitlements = None,
                          mac_code_signing_cert = None,
                          mac_deep_sign_jars_regex = None,
                          windows_menu_group = None,
                          windows_wix_toolset = "@wix_toolset_311//file"):

    assemble_zip_name = "{}-deps-zip".format(name)

    _assemble_zip(
        name = assemble_zip_name,
        targets = [java_deps],
        additional_files = additional_files,
        output_filename = assemble_zip_name,
    )

    _assemble_zip_to_jvm_platform(
        name = name,
        assemble_zip = assemble_zip_name,
        image_name = image_name,
        image_filename = image_filename,
        description = description,
        vendor = vendor,
        copyright = copyright,
        license_file = license_file,
        icon = icon,
        version_file = version_file,
        jars_path = java_deps_root,
        main_jar_path = main_jar_path,
        main_class = main_class,
        jdk = jdk,
        os = select({
            "@vaticle_bazel_distribution//platform:is_mac": "Mac",
            "@vaticle_bazel_distribution//platform:is_linux": "Linux",
            "@vaticle_bazel_distribution//platform:is_windows": "Windows",
        }),
        verbose = verbose,
        log_sensitive_data = log_sensitive_data,
        create_shortcut = create_shortcut,
        linux_app_category = linux_app_category,
        linux_menu_group = linux_menu_group,
        mac_app_id = mac_app_id,
        mac_entitlements = mac_entitlements,
        mac_code_signing_cert = select({
            "@vaticle_bazel_distribution//platform/jvm:apple-code-sign": mac_code_signing_cert,
            "//conditions:default": None,
        }),
        mac_deep_sign_jars_regex = mac_deep_sign_jars_regex,
        windows_menu_group = windows_menu_group,
        windows_wix_toolset = select({
            "@vaticle_bazel_distribution//platform:is_windows": windows_wix_toolset,
            "//conditions:default": None,
        }),
    )
