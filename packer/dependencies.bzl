load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def deploy_packer_dependencies():
    http_archive(
         name = "packer_osx",
         url = "https://releases.hashicorp.com/packer/1.4.0/packer_1.4.0_darwin_amd64.zip",
         sha256 = "475a2a63d37c5bbd27a4b836ffb1ac85d1288f4d55caf04fde3e31ca8e289773",
         build_file_content = 'exports_files(["packer"])'
    )

    http_archive(
         name = "packer_linux",
         url = "https://releases.hashicorp.com/packer/1.4.0/packer_1.4.0_linux_amd64.zip",
         sha256 = "7505e11ce05103f6c170c6d491efe3faea1fb49544db0278377160ffb72721e4",
         build_file_content = 'exports_files(["packer"])'
    )
