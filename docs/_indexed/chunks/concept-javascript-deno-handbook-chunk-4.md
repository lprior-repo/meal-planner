---
doc_id: concept/javascript/deno-handbook
chunk_id: concept/javascript/deno-handbook#chunk-4
heading_path: ["Deno handbook", "Enable Deno and override default settings"]
chunk_type: code
tokens: 153
summary: "Enable Deno and override default settings"
---

## Enable Deno and override default settings
deno:
  lockfile: true
```

Or by pinning a `deno` version in [`.prototools`](/docs/proto/config) in the workspace root.

.prototools

```
deno = "1.31.0"
```

This will enable the Deno toolchain and provide the following automations around its ecosystem:

- Automatic handling and caching of lockfiles (when the setting is enabled).
- Relationships between projects will automatically be discovered based on `imports`, `importMap`, and `deps.ts` (currently experimental).
- And more to come!

### Work in progress

caution

Deno support is currently experimental while we finalize the implementation.

The following features are not supported:

- `deno.jsonc` files (use `deno.json` instead).
- `files.exclude` are currently considered an input. These will be filtered in a future release.
