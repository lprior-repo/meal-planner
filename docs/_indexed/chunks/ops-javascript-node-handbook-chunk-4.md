---
doc_id: ops/javascript/node-handbook
chunk_id: ops/javascript/node-handbook#chunk-4
heading_path: ["Node.js handbook", "Enable Node.js and override default settings"]
chunk_type: code
tokens: 345
summary: "Enable Node.js and override default settings"
---

## Enable Node.js and override default settings
node:
  packageManager: 'pnpm'
```

info

In moon v1.40+, use `unstable_javascript` and `unstable_node` instead of `node` to enable the new WASM powered Node.js toolchain, which is far more accurate and efficient. The non-WASM toolchain will be deprecated in the future.

Or by pinning a `node` version in [`.prototools`](/docs/proto/config) in the workspace root.

.prototools

```
node = "18.0.0"
pnpm = "7.29.0"
```

This will enable the Node.js toolchain and provide the following automations around its ecosystem:

- Node modules will automatically be installed if dependencies in `package.json` have changed, or the lockfile has changed, since the last time a task has ran.
  - We'll also take `package.json` workspaces into account and install modules in the correct location; either the workspace root, in a project, or both.
- Relationships between projects will automatically be discovered based on `dependencies`, `devDependencies`, and `peerDependencies` in `package.json`.
  - The versions of these packages will also be automatically synced when changed.
- Tasks can be [automatically inferred](/docs/config/toolchain#infertasksfromscripts) from `package.json` scripts.
- And much more!

### Utilizing the toolchain

When a language is enabled, moon by default will assume that the language's binary is available within the current environment (typically on `PATH`). This has the downside of requiring all developers and machines to manually install the correct version of the language, *and to stay in sync*.

Instead, you can utilize [moon's toolchain](/docs/concepts/toolchain), which will download and install the language in the background, and ensure every task is executed using the exact version across all machines.

Enabling the toolchain is as simple as defining the [`node.version`](/docs/config/toolchain#version) setting.

.moon/toolchain.yml

```
