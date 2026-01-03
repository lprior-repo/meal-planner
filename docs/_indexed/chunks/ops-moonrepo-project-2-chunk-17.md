---
doc_id: ops/moonrepo/project-2
chunk_id: ops/moonrepo/project-2#chunk-17
heading_path: ["moon.{pkl,yml}", "`toolchain`"]
chunk_type: code
tokens: 340
summary: "`toolchain`"
---

## `toolchain`

### `default` (v1.31.0)

The default [`toolchain`](#toolchain-1) for all task's within the current project. When a task's `toolchain` has *not been* explicitly configured, the toolchain will fallback to this configured value, otherwise the toolchain will be detected from the project's environment.

moon.yml

```yaml
toolchain:
  default: 'node'
```

### `bun`

Configures Bun for this project and overrides the top-level [`bun`](/docs/config/toolchain#bun) setting.

#### `version`

Defines the explicit Bun [version specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  bun:
    version: '1.0.0'
```

### `deno`

Configures Deno for this project and overrides the top-level [`deno`](/docs/config/toolchain#deno) setting.

#### `version`

Defines the explicit Deno [version specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  deno:
    version: '1.40.0'
```

### `node`

Configures Node.js for this project and overrides the top-level [`node`](/docs/config/toolchain#node) setting. Currently, only the Node.js version can be overridden per-project, not the package manager.

#### `version`

Defines the explicit Node.js [version specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  node:
    version: '12.12.0'
```

### `python`

Configures Python for this project and overrides the top-level [`python`](/docs/config/toolchain#python) setting.

#### `version`

Defines the explicit Python [version/channel specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  python:
    version: '3.12.0'
```

### `rust`

Configures Rust for this project and overrides the top-level [`rust`](/docs/config/toolchain#rust) setting.

#### `version`

Defines the explicit Rust [version/channel specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  rust:
    version: '1.68.0'
```

### `typescript`

#### `disabled`

Disables [TypeScript support](/docs/config/toolchain#typescript) entirely for this project. Defaults to `false`.

moon.yml

```yaml
toolchain:
  typescript:
    disabled: true
```
