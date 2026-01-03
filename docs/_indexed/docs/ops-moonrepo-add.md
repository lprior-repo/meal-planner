---
id: ops/moonrepo/add
title: "toolchain add"
category: ops
tags: ["moonrepo", "operations", "toolchain"]
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

## Arguments

- `<id>` - ID of the toolchain to use.
- `[plugin]` - Optional [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations) for third-party toolchains.

### Options

- `--minimal` - Generate minimal configurations and sane defaults.
- `--yes` - Skip all prompts and enables tools based on file detection.


## See Also

- [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations)
- [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations)
- [plugin locator](/docs/guides/wasm-plugins#configuring-plugin-locations)
