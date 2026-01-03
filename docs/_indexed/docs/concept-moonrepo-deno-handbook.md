---
id: concept/moonrepo/deno-handbook
title: "Deno handbook"
category: concept
tags: ["moonrepo", "concept", "typescript", "deno"]
---

# Deno handbook

> **Context**: Utilizing Deno in a TypeScript based monorepo can be a non-trivial task. With this handbook, we'll help guide you through this process.

Utilizing Deno in a TypeScript based monorepo can be a non-trivial task. With this handbook, we'll help guide you through this process.

info

This guide is a living document and will continue to be updated over time!

## moon setup

For this part of the handbook, we'll be focusing on [moon](/moon), our task runner. To start, languages in moon act like plugins, where their functionality and support *is not* enabled unless explicitly configured. We follow this approach to avoid unnecessary overhead.

### Enabling the language

To enable TypeScript support via Deno, define the [`deno`](/docs/config/toolchain#deno) setting in [`.moon/toolchain.yml`](/docs/config/toolchain), even if an empty object.

.moon/toolchain.yml

```
## Enable Deno
deno: {}

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

## Coming soon!

The handbook is currently being written while we finalize our Deno integration support!


## See Also

- [moon](/moon)
- [`deno`](/docs/config/toolchain#deno)
- [`.moon/toolchain.yml`](/docs/config/toolchain)
- [`.prototools`](/docs/proto/config)
