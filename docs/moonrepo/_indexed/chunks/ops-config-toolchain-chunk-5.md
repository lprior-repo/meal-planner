---
doc_id: ops/config/toolchain
chunk_id: ops/config/toolchain#chunk-5
heading_path: [".moon/toolchain.{pkl,yml}", "JavaScript"]
chunk_type: code
tokens: 380
summary: "JavaScript"
---

## JavaScript

### `node`

Enables and configures Node.js.

> **Warning**: This toolchain has been deprecated. We suggest using [`unstable_node`](#unstable_node) and a chosen package manager ([`unstable_npm`](#unstable_npm), [`unstable_pnpm`](#unstable_pnpm), or [`unstable_yarn`](#unstable_yarn)) instead!

#### `version`

Defines the explicit Node.js [version specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `node` binary will be used.

.moon/toolchain.yml

```yaml
node:
  version: '16.13'
```

> Version can also be defined with [`.prototools`](/docs/proto/config) or with the `MOON_NODE_VERSION` environment variable.

#### `packageManager`

Defines which package manager to utilize. Supports `npm` (default), `pnpm`, `yarn`, or `bun`.

.moon/toolchain.yml

```yaml
node:
  packageManager: 'yarn'
```

#### `npm`, `pnpm`, `yarn`, `bun`

Optional fields for defining package manager specific configuration. The chosen setting is dependent on the value of [`node.packageManager`](#packagemanager). If these settings *are not defined*, the latest version of the active package manager will be used (when applicable).

#### `version`

The `version` setting defines the explicit package manager [version specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `npm`, `pnpm`, `yarn`, and `bun` binaries will be used.

.moon/toolchain.yml

```yaml
node:
  packageManager: 'yarn'
  yarn:
    version: '3.1.0'
```

### `unstable_node` (v1.40.0)

Enables and configures Node.js using the new WASM plugin.

> This toolchain requires the [`unstable_javascript`](#unstable_javascript) toolchain to also be enabled.

#### `version`

Defines the explicit Node.js toolchain [version specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `node` binary will be used.

.moon/toolchain.yml

```yaml
unstable_node:
  version: '20.0.0'
```

### `unstable_javascript` (v1.40.0)

Enables and configures JavaScript using the new WASM plugin. This core JavaScript toolchain depends on these other JavaScript ecosystem toolchains:

-   Runtimes: [`unstable_bun`](#unstable_bun), [`unstable_deno`](#unstable_deno), [`unstable_node`](#unstable_node)
-   Package managers: [`unstable_bun`](#unstable_bun), [`unstable_deno`](#unstable_deno), [`unstable_npm`](#unstable_npm), [`unstable_pnpm`](#unstable_pnpm), [`unstable_yarn`](#unstable_yarn)

#### `packageManager`

Defines which package manager to utilize when installing dependencies. Supports `npm`, `pnpm`, `yarn`, `deno`, or `bun`. Defaults to no package manager.

.moon/toolchain.yml

```yaml
unstable_javascript:
  packageManager: 'yarn'
```
