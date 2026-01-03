---
doc_id: ops/moonrepo/extensions
chunk_id: ops/moonrepo/extensions#chunk-2
heading_path: ["Extensions", "Using extensions"]
chunk_type: code
tokens: 84
summary: "Using extensions"
---

## Using extensions

Before an extension can be executed with the [`moon ext`](/docs/commands/ext) command, it must be configured with the [`extensions`](/docs/config/workspace#extensions) setting in [`.moon/workspace.yml`](/docs/config/workspace) (excluding [built-in's](#built-in-extensions)).

.moon/workspace.yml

```yaml
extensions:
  example:
    plugin: 'https://example.com/path/to/example.wasm'
```

Once configured, it can be executed with [`moon ext`](/docs/commands/ext) by name. Arguments unique to the extension *must* be passed after a `--` separator.

```shell
$ moon ext example -- --arg1 --arg2
```
