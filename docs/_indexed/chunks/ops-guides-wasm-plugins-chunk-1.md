---
doc_id: ops/guides/wasm-plugins
chunk_id: ops/guides/wasm-plugins#chunk-1
heading_path: ["WASM plugins"]
chunk_type: prose
tokens: 143
summary: "WASM plugins"
---

# WASM plugins

> **Context**: [moon](/moon) and [proto](/proto) plugins can be written in [WebAssembly (WASM)](https://webassembly.org/), a portable binary format. This means that 

[moon](/moon) and [proto](/proto) plugins can be written in [WebAssembly (WASM)](https://webassembly.org/), a portable binary format. This means that plugins can be written in any language that compiles to WASM, like Rust, C, C++, Go, TypeScript, and more. Because WASM based plugins are powered by a programming language, they implicitly support complex business logic and behavior, have access to a sandboxed file system (via WASI), can execute child processes, and much more.

> **Danger:** Since our WASM plugin implementations are still experimental, expect breaking changes to occur in non-major releases.
