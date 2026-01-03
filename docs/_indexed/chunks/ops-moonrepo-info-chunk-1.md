---
doc_id: ops/moonrepo/info
chunk_id: ops/moonrepo/info#chunk-1
heading_path: ["toolchain info"]
chunk_type: code
tokens: 157
summary: "toolchain info"
---

# toolchain info

> **Context**: The `moon toolchain info <id> [plugin]` command will display detailed information about a toolchain, like what files are scanned, what configuration s

v1.38.0

The `moon toolchain info <id> [plugin]` command will display detailed information about a toolchain, like what files are scanned, what configuration settings are available, and what tier APIs are supported. To do this, the command will download the WASM plugin, extract information, and call specific functions.

For built-in toolchains, the [plugin locator] argument is optional, and will be derived from the identifier.

```
$ moon toolchain info typescript
```

For third-party toolchains, the [plugin locator] argument is required, and must point to the WASM plugin.

```
$ moon toolchain info custom https://example.com/path/to/plugin.wasm
```
