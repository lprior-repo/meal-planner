---
doc_id: ops/moonrepo/wasm-plugins
chunk_id: ops/moonrepo/wasm-plugins#chunk-11
heading_path: ["WASM plugins", "Building and publishing"]
chunk_type: prose
tokens: 167
summary: "Building and publishing"
---

## Building and publishing

At this point, you should have a fully working WASM plugin, but to make it available to the community, you'll still need to build and make the `.wasm` file available. The easiest solution is to publish a GitHub release and include the `.wasm` file as an asset.

### Building, optimizing, and stripping

WASM files are pretty fat, even when compiling in release mode. To reduce the size of these files, we can use `wasm-opt` and `wasm-strip`, both of which are provided by the [WebAssembly](https://github.com/WebAssembly) group. The following script is what we use to build our own plugins.

> **Info:** This functionality is natively supported in our [moonrepo/build-wasm-plugin](https://github.com/moonrepo/build-wasm-plugin) GitHub Action!

build-wasm

```bash
#!/usr/bin/env bash

target="${CARGO_TARGET_DIR:-target}"
input="$target/wasm32-wasip1/release/$1.wasm"
output="$target/wasm32-wasip1/$1.wasm"

echo "Building"
cargo build --target wasm32-wasip1 --release

echo "Optimizing"
