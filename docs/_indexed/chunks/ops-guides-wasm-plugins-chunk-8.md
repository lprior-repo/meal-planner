---
doc_id: ops/guides/wasm-plugins
chunk_id: ops/guides/wasm-plugins#chunk-8
heading_path: ["WASM plugins", "Creating a plugin"]
chunk_type: code
tokens: 161
summary: "Creating a plugin"
---

## Creating a plugin

> **Info:** Although plugins can be written in any language that compiles to WASM, we've only tested Rust. The rest of this article assume you're using Rust and Cargo! Refer to [Extism](https://extism.org/)'s documentation for other examples.

To start, create a new crate with Cargo:

```shell
cargo new plugin --lib
cd plugin
```

Set the lib type to `cdylib`, and provide other required settings.

Cargo.toml

```toml
[package]
name = "example_plugin"
version = "0.0.1"
edition = "2024"
publish = false

[lib]
crate-type = ['cdylib']

[profile.release]
codegen-units = 1
debug = false
lto = true
opt-level = "s"
panic = "abort"
```

Our Rust plugins are powered by [Extism](https://extism.org/), so lets add their PDK and ours as a dependency.

```shell
cargo add extism-pdk
