---
doc_id: ops/rust/handbook
chunk_id: ops/rust/handbook#chunk-4
heading_path: ["Rust handbook", "Enable Rust and override default settings"]
chunk_type: code
tokens: 279
summary: "Enable Rust and override default settings"
---

## Enable Rust and override default settings
rust:
  syncToolchainConfig: true
```

info

In moon v1.37+, use `unstable_rust` instead of `rust` to enable the new WASM powered Rust toolchain, which is far more accurate and efficient. The non-WASM toolchain will be deprecated in the future.

Or by pinning a `rust` version in [`.prototools`](/docs/proto/config) in the workspace root.

.prototools

```
rust = "1.69.0"
```

This will enable the Rust toolchain and provide the following automations around its ecosystem:

- Manifests and lockfiles are parsed for accurate dependency versions for hashing purposes.
- Cargo binaries (in `~/.cargo/bin`) are properly located and executed.
- Automatically sync `rust-toolchain.toml` configuration files.
- For non-workspaces, will inherit `package.name` from `Cargo.toml` as a project alias.
- And more to come!

### Utilizing the toolchain

When a language is enabled, moon by default will assume that the language's binary is available within the current environment (typically on `PATH`). This has the downside of requiring all developers and machines to manually install the correct version of the language, *and to stay in sync*.

Instead, you can utilize [moon's toolchain](/docs/concepts/toolchain), which will download and install the language in the background, and ensure every task is executed using the exact version across all machines.

Enabling the toolchain is as simple as defining the [`rust.version`](/docs/config/toolchain#version-2) setting.

.moon/toolchain.yml

```yaml
