# Bzlmod Migration Status

## Summary

**Status: 52/53 targets build successfully**

## Build Command

```bash
bazelisk build //... \
  --java_runtime_version=remotejdk_21 \
  --extra_toolchains=@llvm_toolchain//:all \
  --host_action_env=LD_LIBRARY_PATH="/home/user/lib/extracted/usr/lib/aarch64-linux-gnu" \
  -- -//:docs -//:docs.extract
```

## Working Targets

All targets except docs:
- `//apt/...`
- `//brew/...`
- `//common/...`
- `//crates/...`
- `//docs/...` (subdirectories)
- `//github/...`
- `//maven/...`
- `//npm/...`
- `//pip/...`
- `//platform/...`
- `//packer/...`

## Failing Targets

| Target | Error | Reason |
|--------|-------|--------|
| `//:docs` | Missing bzl_library for @rules_pkg//:pkg.bzl | stardoc macro needs bzl_library targets |
| `//:docs.extract` | Same as above | Same root cause |

## Notes

- LLVM toolchain is configured as `dev_dependency = True` so it only applies when building this repo standalone
- When used as a dependency (e.g., from `dependencies`), the parent module must provide its own LLVM toolchain
- The `--host_action_env=LD_LIBRARY_PATH` is needed because ld.lld requires libxml2.so.2
