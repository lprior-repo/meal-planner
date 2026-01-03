---
doc_id: ops/moonrepo/add
chunk_id: ops/moonrepo/add#chunk-1
heading_path: ["toolchain add"]
chunk_type: code
tokens: 145
summary: "toolchain add"
---

# toolchain add

> **Context**: The `moon toolchain add <id> [plugin]` command will add a toolchain to the workspace by injecting a configuration block into `.moon/toolchain.yml`. To

v1.38.0

The `moon toolchain add <id> [plugin]` command will add a toolchain to the workspace by injecting a configuration block into `.moon/toolchain.yml`. To do this, the command will download the WASM plugin, extract information, and call initialize functions.

For built-in toolchains, the [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations) argument is optional, and will be derived from the identifier.

```
$ moon toolchain add typescript
```

For third-party toolchains, the [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations) argument is required, and must point to the WASM plugin.

```
$ moon toolchain add custom https://example.com/path/to/plugin.wasm
```
