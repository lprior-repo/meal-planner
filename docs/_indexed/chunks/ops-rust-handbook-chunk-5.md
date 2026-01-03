---
doc_id: ops/rust/handbook
chunk_id: ops/rust/handbook#chunk-5
heading_path: ["Rust handbook", "Enable Rust toolchain with an explicit version"]
chunk_type: prose
tokens: 76
summary: "Enable Rust toolchain with an explicit version"
---

## Enable Rust toolchain with an explicit version
rust:
  version: '1.69.0'
```

> Versions can also be defined with [`.prototools`](/docs/proto/config).

caution

moon requires `rustup` to exist in the environment, and will use this to install the necessary Rust toolchains. This requires Rust to be manually installed on the machine, as moon does not auto-install the language, just the toolchains.
