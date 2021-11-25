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

    config = """/
verbose: {}
jdkPath: {}
srcFilename: {}
imageName: {}
imageFilename: {}
versionFilePath: {}
mainJar: {}
mainClass: {}
outFilename: {}
""".format(
    True,
    ctx.file.jdk.path,
    ctx.file.assemble_zip.path,
    ctx.attr.image_name,
    ctx.attr.image_filename,
    version_file.path,
    ctx.attr.main_jar,
    ctx.attr.main_class,
    ctx.outputs.distribution_file.path)

    if "APPLE_CODE_SIGN" in ctx.var:
        if not ctx.file.mac_entitlements:
            fail("Parameter mac_entitlements must be set if variable APPLE_CODE_SIGN is set")
        if not ctx.file.mac_code_signing_cert:
            fail("Parameter mac_code_signing_cert must be set if variable APPLE_CODE_SIGN is set")

        if "APPLE_ID" not in ctx.var:
            fail("Variable APPLE_ID must be set if variable APPLE_CODE_SIGN is set")
        if "APPLE_ID_PASSWORD" not in ctx.var:
            fail("Variable APPLE_ID_PASSWORD must be set if variable APPLE_CODE_SIGN is set")
        if "APPLE_CODE_SIGNING_CERT_PASSWORD" not in ctx.var:
            fail("Variable APPLE_CODE_SIGNING_CERT_PASSWORD must be set if variable APPLE_CODE_SIGN is set")

        config = config + """/
appleCodeSign: True
appleCodeSigningCertPath: {}
""".format(ctx.file.mac_code_signing_cert.path)

        progress_message = progress_message + " (NOTE: notarization typically takes several minutes to complete)"

    inputs = [ctx.file.jdk, ctx.file.assemble_zip, version_file]

    if ctx.file.icon:
        inputs = inputs + [ctx.file.icon]
        config = config + """/
iconPath: {}
""".format(ctx.file.icon.path)

    if ctx.file.mac_entitlements:
        inputs = inputs + [ctx.file.mac_entitlements]
        config = config + """/
macEntitlementsPath: {}
""".format(ctx.file.mac_entitlements.path)

    if hasattr(ctx.attr, "mac_deep_sign_jars_regex"):
        config = config + """/
appleDeepSignJarsRegex: {}
""".format(ctx.attr.mac_deep_sign_jars_regex)

    if ctx.file.windows_wix_toolset:
        inputs = inputs + [ctx.file.windows_wix_toolset]
        config = config + """/
windowsWixToolsetPath: {}
""".format(ctx.file.windows_wix_toolset.path)

    config_file = ctx.actions.declare_file(ctx.attr.name + "__config.properties")
    ctx.actions.run_shell(
        inputs = [],
        outputs = [config_file],
        command = "echo \"{}\" > {}".format(config, config_file.path)
    )

    config_path_arg = "--config_path={}".format(config_file.path)
    if "APPLE_CODE_SIGN" in ctx.var:
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
        "main_jar": attr.string(
            mandatory = True,
            doc = "The name of the JAR containing the main method",
        ),
        "main_class": attr.string(
            mandatory = True,
            doc = "The main class",
        ),
        "os": attr.string(
            mandatory = True,
            doc = "The host OS",
        ),
        "mac_entitlements": attr.label(
            allow_single_file = True,
            doc = "The MacOS entitlements.mac.plist file",
        ),
        "mac_code_signing_cert": attr.label(
            allow_single_file = True,
            doc = "The MacOS code signing certificate",
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


# TODO: upgrade all to JDK17
def native_jdk16():
    return select({
        "@vaticle_dependencies//util/platform:is_mac": "@jdk16_mac//file",
        "@vaticle_dependencies//util/platform:is_linux": "@jdk16_linux//file",
        "@vaticle_dependencies//util/platform:is_windows": "@jdk16_windows//file",
    })

def assemble_jvm_platform(name,
                          image_name,
                          image_filename,
                          version_file,
                          java_deps,
                          main_jar,
                          main_class,
                          icon = None,
                          jdk = native_jdk16(),
                          additional_files = {},
                          mac_entitlements = None,
                          mac_code_signing_cert = None,
                          mac_deep_sign_jars_regex = None,
                          windows_wix_toolset = "@wix_toolset_311//file"):

    assemble_zip_name = "{}-assemble-zip".format(name)

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
        icon = icon,
        version_file = version_file,
        main_jar = main_jar,
        main_class = main_class,
        jdk = jdk,
        os = select({
            "@vaticle_dependencies//util/platform:is_mac": "Mac",
            "@vaticle_dependencies//util/platform:is_linux": "Linux",
            "@vaticle_dependencies//util/platform:is_windows": "Windows",
        }),
        mac_entitlements = mac_entitlements,
        mac_code_signing_cert = select({
            "@vaticle_bazel_distribution//platform/jvm:apple-code-sign": mac_code_signing_cert,
            "//conditions:default": None,
        }),
        # TODO: in typedb-studio, set this parameter to ".*(io-netty-netty|skiko-jvm-runtime).*"
        mac_deep_sign_jars_regex = mac_deep_sign_jars_regex,
        windows_wix_toolset = select({
            "@vaticle_dependencies//util/platform:is_windows": windows_wix_toolset,
            "//conditions:default": None,
        }),
    )
