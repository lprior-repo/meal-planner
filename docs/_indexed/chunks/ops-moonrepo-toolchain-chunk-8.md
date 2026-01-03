---
doc_id: ops/moonrepo/toolchain
chunk_id: ops/moonrepo/toolchain#chunk-8
heading_path: ["Toolchain", "Rust"]
chunk_type: code
tokens: 153
summary: "Rust"
---

## Rust

### `rust` (v1.5.0)

Enables and configures Rust.

> **Warning**: This toolchain has been deprecated. We suggest using [`unstable_rust`](#unstable_rust) instead!

#### `version`

Defines the explicit Rust toolchain [version/channel specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `cargo`, `rustc`, and other binaries will be used.

.moon/toolchain.yml

```yaml
rust:
  version: '1.69.0'
```

### `unstable_rust` (v1.37.0)

Enables and configures Rust. This setting enables the new WASM powered Rust toolchain, which is far more accurate and efficient, but still unstable.

Supports all the same settings as [`rust`](#rust), with the addition of:

#### `addMsrvConstraint` (v1.37.0)

When `version` is defined, syncs the version as a constraint to `Cargo.toml` under the `workspace.package.rust-version` or `package.rust-version` fields.

.moon/toolchain.yml

```yaml
unstable_rust:
  addMsrvConstraint: true
```
