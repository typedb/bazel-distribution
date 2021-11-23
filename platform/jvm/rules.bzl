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

load("@vaticle_bazel_distribution//common:rules.bzl", "assemble_zip", "java_deps")


def _assemble_zip_to_jvm_platform_impl(ctx):
    # TODO: currently unreachable - but we should have unsupported com.vaticle.bazel.distribution.common.OS detection. Maybe just make OS_UNKNOWN var?
    if (ctx.attr.os == "unknown"):
        fail("jvm_application_image is not supported on this operating system")

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

    step_description = "Building native {} application image".format(ctx.attr.application_name)

    config = """/
verbose: {}
jdkPath: {}
srcFilename: {}
applicationName: {}
applicationFilename: {}
versionFilePath: {}
mainJar: {}
mainClass: {}
outFilename: {}
""".format(
    True,
    ctx.file.jdk.path,
    ctx.file.src.path,
    ctx.attr.application_name,
    ctx.attr.filename,
    version_file.path,
    ctx.attr.main_jar,
    ctx.attr.main_class,
    ctx.outputs.distribution_file.path)

    config_private = ""

    if "APPLE_CODE_SIGNING_CERT_PASSWORD" in ctx.var:

        if not ctx.file.mac_entitlements:
            fail("Parameter mac_entitlements must be set if variable APPLE_CODE_SIGNING_CERT_PASSWORD is set")
        if not ctx.file.mac_code_signing_cert:
            fail("Parameter mac_code_signing_cert must be set if variable APPLE_CODE_SIGNING_CERT_PASSWORD is set")

        if "APPLEID" not in ctx.var:
            fail("Variable APPLEID must be set if variable APPLE_CODE_SIGNING_CERT_PASSWORD is set")
        if "APPLEID_PASSWORD" not in ctx.var:
            fail("Variable APPLEID_PASSWORD must be set if variable APPLE_CODE_SIGNING_CERT_PASSWORD is set")

        config = config + """/
appleCodeSigningCertificatePath: {}
""".format(ctx.file.mac_code_signing_cert.path)

        config_private = config_private + """/
appleId: {}
appleIdPassword: {}
appleCodeSigningCertificatePassword: {}
""".format(
        ctx.var["APPLEID"],
        ctx.var["APPLEID_PASSWORD"],
        ctx.var["APPLE_CODE_SIGNING_CERT_PASSWORD"])

        step_description = step_description + " (NOTE: notarization typically takes several minutes to complete)"

    inputs = [ctx.file.jdk, ctx.file.src, version_file]

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

    if ctx.file.windows_wix_toolset:
        inputs = inputs + [ctx.file.windows_wix_toolset]
        config = config + """/
windowsWixToolsetPath: {}
""".format(ctx.file.windows_wix_toolset.path)

    config_file = ctx.actions.declare_file(ctx.attr.name + "__config.properties")

    ctx.actions.run(
        inputs = inputs,
        outputs = [ctx.outputs.distribution_file],
        executable = ctx.executable._jvm_application_image_builder_bin,
        arguments = [config_file.path] + credentials,
        progress_message = step_description,
    )

    return DefaultInfo(data_runfiles = ctx.runfiles(files=[ctx.outputs.distribution_file]))


assemble_zip_to_jvm_platform = rule(
    attrs = {
        "assemble_zip": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The ZIP assembly to pack into a platform-native application",
        ),
        "application_name": attr.string(
            mandatory = True,
            doc = "The application name",
        ),
        "icon": attr.label(
            allow_single_file = True,
            doc = "The application icon",
        ),
        "filename": attr.string(
            mandatory = True,
            doc = "The filename",
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
            doc = "The host com.vaticle.bazel.distribution.common.OS",
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
        "_application_builder_bin": attr.label(
            default = "//:application-builder-bin",
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
                          application_name,
                          filename,
                          version_file,
                          java_deps,
                          main_jar,
                          main_class,
                          icon = None,
                          jdk = native_jdk16(),
                          additional_files = {},
                          mac_entitlements = None,
                          mac_code_signing_cert = None,
                          windows_wix_toolset = "@wix_toolset_311//file"):

    deps_zip_name = "{}-deps-zip".format(name)

    assemble_zip(
        name = deps_zip_name,
        targets = [java_deps],
        additional_files = additional_files,
        output_filename = deps_zip_name,
    )

    assemble_zip_to_jvm_platform(
        name = name,
        assemble_zip = ":{}-assemble-zip".format(name),
        application_name = application_name,
        icon = icon,
        filename = filename,
        version_file = version_file,
        main_jar = main_jar,
        main_class = main_class,
        jdk = jdk,
        os = select({
            "@vaticle_dependencies//util/platform:is_mac": "mac",
            "@vaticle_dependencies//util/platform:is_linux": "linux",
            "@vaticle_dependencies//util/platform:is_windows": "windows",
        }),
        mac_entitlements = mac_entitlements,
        mac_code_signing_cert = select({
            "//platform/jvm:apple-code-sign": mac_code_signing_cert,
            "//conditions:default": None,
        }),
        windows_wix_toolset = select({
            "@vaticle_dependencies//util/platform:is_windows": windows_wix_toolset,
            "//conditions:default": None,
        }),
    )
