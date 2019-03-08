workspace(name="graknlabs_bazel_distribution")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

http_file(
    name = "ghr_osx_zip",
    urls = ["https://github.com/tcnksm/ghr/releases/download/v0.12.0/ghr_v0.12.0_darwin_amd64.zip"]
)

http_file(
    name = "ghr_linux_tar",
    urls = ["https://github.com/tcnksm/ghr/releases/download/v0.12.0/ghr_v0.12.0_linux_amd64.tar.gz"]
)
