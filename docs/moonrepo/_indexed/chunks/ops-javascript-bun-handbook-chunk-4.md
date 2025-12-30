---
doc_id: ops/javascript/bun-handbook
chunk_id: ops/javascript/bun-handbook#chunk-4
heading_path: ["Bun handbook", "Enable Bun toolchain with an explicit version"]
chunk_type: prose
tokens: 105
summary: "Enable Bun toolchain with an explicit version"
---

## Enable Bun toolchain with an explicit version
bun:
  version: '1.0.0'
```

> Versions can also be defined with [`.prototools`](/docs/proto/config).

### Configuring the toolchain

Since the JavaScript ecosystem supports multiple runtimes, moon is unable to automatically detect the correct runtime for all scenarios. Does the existence of a `package.json` mean Node.js or Bun? We don't know, and default to Node.js because of its popularity.

To work around this, you can set `toolchain` to "bun" at the task-level or project-level.

moon.yml

```
