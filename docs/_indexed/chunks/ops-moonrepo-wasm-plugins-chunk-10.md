---
doc_id: ops/moonrepo/wasm-plugins
chunk_id: ops/moonrepo/wasm-plugins#chunk-10
heading_path: ["WASM plugins", "For moon"]
chunk_type: code
tokens: 58
summary: "For moon"
---

## For moon
cargo add moon_pdk
```

In all Rust files, we can import all the PDKs with the following:

src/lib.rs

```rust
use extism_pdk::*;
```

We can then build the WASM binary. The file will be available at `target/wasm32-wasip1/debug/<name>.wasm`.

```shell
cargo build --target wasm32-wasip1
```
