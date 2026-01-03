---
id: ops/config/toolchain
title: ".moon/toolchain.{pkl,yml}"
category: ops
tags: ["operations", "config", "moontoolchainpklyml", "advanced"]
---

# .moon/toolchain.{pkl,yml}

> **Context**: The `.moon/toolchain.yml` file configures the toolchain and the workspace development environment. This file is *optional*.

The `.moon/toolchain.yml` file configures the toolchain and the workspace development environment. This file is *optional*.

Managing tool version's within the toolchain ensures a deterministic environment across any machine (whether a developer, CI, or production machine).

.moon/toolchain.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/toolchain.json'
```

> Toolchain configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.

## `extends`

Defines one or many external `.moon/toolchain.yml`'s to extend and inherit settings from. Perfect for reusability and sharing configuration across repositories and projects. When defined, this setting must be an HTTPS URL *or* relative file system path that points to a valid YAML document!

.moon/toolchain.yml

```yaml
extends: 'https://raw.githubusercontent.com/organization/repository/master/.moon/toolchain.yml'
```

> **Caution**: Settings will be merged recursively for blocks, with values defined in the local configuration taking precedence over those defined in the extended configuration.

## `moon` (v1.29.0)

Configures how moon will receive information about latest releases and download locations.

### `manifestUrl`

Defines an HTTPS URL in which to fetch the current version information from.

.moon/toolchain.yml

```yaml
moon:
  manifestUrl: 'https://proxy.corp.net/moon/version'
```

### `downloadUrl`

Defines an HTTPS URL in which the moon binary can be downloaded from. The download file name is hard-coded and will be appended to the provided URL.

Defaults to downloading from GitHub: https://github.com/moonrepo/moon/releases

.moon/toolchain.yml

```yaml
moon:
  downloadUrl: 'https://github.com/moonrepo/moon/releases/latest/download'
```

## `proto` (v1.39.0)

Configures how moon integrates with and utilizes [proto](/proto).

### `version`

The version of proto to install and run toolchains with. If proto or this version of proto has not been installed yet, it will be installed automatically when running a task.

.moon/toolchain.yml

```yaml
proto:
  version: '0.51.0'
```

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

## `typescript`

Dictates how moon interacts with and utilizes TypeScript within the workspace. This field is optional and is undefined by default. Define it to enable TypeScript support.

### `createMissingConfig`

When [syncing project references](#syncprojectreferences) and a depended on project *does not* have a `tsconfig.json`, automatically create one. Defaults to `true`.

.moon/toolchain.yml

```yaml
typescript:
  createMissingConfig: true
```

### `syncProjectReferences`

Will sync a project's [dependencies](/docs/concepts/project#dependencies) (when applicable) as project references within that project's `tsconfig.json`, and the root `tsconfig.json`. Defaults to `true` when the parent `typescript` setting is defined, otherwise `false`.

.moon/toolchain.yml

```yaml
typescript:
  syncProjectReferences: true
```

### `syncProjectReferencesToPaths`

Will sync a project's [`tsconfig.json`](#projectconfigfilename) project references to the `paths` compiler option, using the referenced project's `package.json` name. This is useful for mapping aliases to their source code. Defaults to `false`.

.moon/toolchain.yml

```yaml
typescript:
  syncProjectReferencesToPaths: true
```

## Python (v1.30.0)

### `python`

Enables and configures Python.

#### `version`

Defines the explicit Python toolchain [version specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `python` binary will be used.

.moon/toolchain.yml

```yaml
python:
  version: '3.11.10'
```

> Python installation's are based on pre-built binaries provided by [astral-sh/python-build-standalone](https://github.com/astral-sh/python-build-standalone).

#### `packageManager` (v1.32.0)

Defines which package manager to utilize. Supports `pip` (default) or `uv`.

.moon/toolchain.yml

```yaml
python:
  packageManager: 'uv'
```

## Rust

### `rust` (v1.5.0)

Enables and configures Rust.

> **Warning**: This toolchain has been deprecated. We suggest using [`unstable_rust`](#unstable_rust) instead!

#### `version`

Defines the explicit Rust toolchain [version/channel specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `cargo`, `rustc`, and other binaries will be used.

.moon/toolchain.yml

```yaml
rust:
  version: '1.69.0'
```

### `unstable_rust` (v1.37.0)

Enables and configures Rust. This setting enables the new WASM powered Rust toolchain, which is far more accurate and efficient, but still unstable.

Supports all the same settings as [`rust`](#rust), with the addition of:

#### `addMsrvConstraint` (v1.37.0)

When `version` is defined, syncs the version as a constraint to `Cargo.toml` under the `workspace.package.rust-version` or `package.rust-version` fields.

.moon/toolchain.yml

```yaml
unstable_rust:
  addMsrvConstraint: true
```

## Go

### `unstable_go` (v1.38.0)

Enables and configures Go. This setting enables the new WASM powered Go toolchain.

#### `version`

Defines the explicit Go toolchain [version specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `go` binary will be used.

.moon/toolchain.yml

```yaml
unstable_go:
  version: '1.24.0'
```


## See Also

- [Pkl](/docs/guides/pkl-config)
- [proto](/proto)
- [`unstable_node`](#unstable_node)
- [`unstable_npm`](#unstable_npm)
- [`unstable_pnpm`](#unstable_pnpm)
