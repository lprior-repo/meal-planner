---
doc_id: ops/javascript/bun-handbook
chunk_id: ops/javascript/bun-handbook#chunk-5
heading_path: ["Bun handbook", "For all tasks in the project"]
chunk_type: code
tokens: 143
summary: "For all tasks in the project"
---

## For all tasks in the project
toolchain:
  default: 'bun'

tasks:
  build:
    command: 'webpack'
    # For this specific task
    toolchain: 'bun'
```

> The task-level `toolchain.default` only needs to be set if executing a `node_modules` binary! The `bun` binary automatically sets the toolchain to Bun.

### Using `package.json` scripts

If you're looking to prototype moon, or reduce the migration effort to moon tasks, you can configure moon to inherit `package.json` scripts, and internally convert them to moon tasks. This can be achieved with the [`bun.inferTasksFromScripts`](/docs/config/toolchain#infertasksfromscripts) setting.

.moon/toolchain.yml

```
bun:
  inferTasksFromScripts: true
```

Or you can run scripts through `bun run` calls.

moon.yml

```
tasks:
  build:
    command: 'bun run build'
```
