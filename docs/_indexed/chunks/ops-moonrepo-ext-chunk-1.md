---
doc_id: ops/moonrepo/ext
chunk_id: ops/moonrepo/ext#chunk-1
heading_path: ["ext"]
chunk_type: prose
tokens: 153
summary: "ext"
---

# ext

> **Context**: The `moon ext <id>` command will execute an extension (a WASM plugin) that has been configured with the [`extensions`](/docs/config/workspace#extensio

v1.20.0

The `moon ext <id>` command will execute an extension (a WASM plugin) that has been configured with the [`extensions`](/docs/config/workspace#extensions) setting in [`.moon/workspace.yml`](/docs/config). View our official [extensions guide](/docs/guides/extensions) for more information.

```
$ moon ext download -- --url https://github.com/moonrepo/moon/archive/refs/tags/v1.19.3.zip
```

Extensions typically support command line arguments, which *must* be passed after a `--` separator (as seen above). Any arguments before the separator will be passed to the `moon ext` command itself.

**Caution:** This command requires an internet connection if the extension's `.wasm` file must be downloaded from a URL, and it hasn't been cached locally.
