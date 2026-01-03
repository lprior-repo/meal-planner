---
id: ops/moonrepo/ext
title: "ext"
category: ops
tags: ["moonrepo", "operations", "ext"]
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

## Arguments

-   `<id>` - Name of the extension to execute.
-   `[-- <args>]` - Arguments to pass to the extension.

### Configuration

-   [`extensions`](/docs/config/workspace#extensions) in `.moon/workspace.yml`


## See Also

- [`extensions`](/docs/config/workspace#extensions)
- [`.moon/workspace.yml`](/docs/config)
- [extensions guide](/docs/guides/extensions)
- [`extensions`](/docs/config/workspace#extensions)
