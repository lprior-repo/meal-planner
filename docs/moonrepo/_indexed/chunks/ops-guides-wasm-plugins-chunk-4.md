---
doc_id: ops/guides/wasm-plugins
chunk_id: ops/guides/wasm-plugins#chunk-4
heading_path: ["WASM plugins", "Configuring plugin locations"]
chunk_type: code
tokens: 107
summary: "Configuring plugin locations"
---

## Configuring plugin locations

To use a WASM plugin, it'll need to be configured in both moon and proto. Luckily both tools use a similar approach for configuring plugins called the [plugin locator](https://docs.rs/warpgate/latest/warpgate/enum.PluginLocator.html). A locator string is composed of 2 parts separated by `://`, the former is the protocol, and the latter is the location.

```
"<protocol>://<location>"
```

The following locator patterns are supported:

### `file`

The `file://` protocol represents a file path, either absolute or relative (from the current configuration file).

```
