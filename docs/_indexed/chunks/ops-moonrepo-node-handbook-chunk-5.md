---
doc_id: ops/moonrepo/node-handbook
chunk_id: ops/moonrepo/node-handbook#chunk-5
heading_path: ["Node.js handbook", "Enable Node.js toolchain with an explicit version"]
chunk_type: code
tokens: 114
summary: "Enable Node.js toolchain with an explicit version"
---

## Enable Node.js toolchain with an explicit version
node:
  version: '18.0.0'
```

> Versions can also be defined with [`.prototools`](/docs/proto/config).

### Using `package.json` scripts

If you're looking to prototype moon, or reduce the migration effort to moon tasks, you can configure moon to inherit `package.json` scripts, and internally convert them to moon tasks. This can be achieved with the [`node.inferTasksFromScripts`](/docs/config/toolchain#infertasksfromscripts) setting.

.moon/toolchain.yml

```
node:
  inferTasksFromScripts: true
```

Or you can run scripts through `npm run` (or `pnpm`, `yarn`) calls.

moon.yml

```
tasks:
  build:
    command: 'npm run build'
```
