---
doc_id: ops/guides/wasm-plugins
chunk_id: ops/guides/wasm-plugins#chunk-2
heading_path: ["WASM plugins", "Powered by Extism"]
chunk_type: prose
tokens: 137
summary: "Powered by Extism"
---

## Powered by Extism

Our WASM plugin system is powered by [Extism](https://extism.org/), a Rust-based cross-language framework for building WASM plugins under a unified guest and host API. Under the hood, Extism uses [wasmtime](https://wasmtime.dev/) as its WASM runtime.

For the most part, you do *not* need to know about Extism's host SDK, as we have implemented the bulk of it within moon and proto directly. However, you *should* be familiar with the guest PDKs, as this is what you'll be using to implement Rust-based plugins. We suggest reading the following material:

- [Plugin development kits](https://extism.org/docs/concepts/pdk) (PDKs)
- The [extism-pdk](https://github.com/extism/rust-pdk) Rust crate
- [Host functions](https://extism.org/docs/concepts/host-functions) (how they work)
