---
doc_id: ops/guides/extensions
chunk_id: ops/guides/extensions#chunk-3
heading_path: ["Extensions", "Built-in extensions"]
chunk_type: code
tokens: 702
summary: "Built-in extensions"
---

## Built-in extensions

moon is shipped with a few built-in extensions that are configured and enabled by default. Official moon extensions are built and published in our [moonrepo/moon-extensions](https://github.com/moonrepo/moon-extensions) repository.

### `download`

The `download` extension can be used to download a file from a URL into the current workspace, as defined by the `--url` argument. For example, say we want to download the latest [proto](/proto) binary:

```shell
$ moon ext download --\
  --url https://github.com/moonrepo/proto/releases/latest/download/proto_cli-aarch64-apple-darwin.tar.xz
```

By default this will download `proto_cli-aarch64-apple-darwin.tar.xz` into the current working directory. To customize the location, use the `--dest` argument. However, do note that the destination *must be* within the current moon workspace, as only certain directories are whitelisted for WASM.

```shell
$ moon ext download --\
  --url https://github.com/moonrepo/proto/releases/latest/download/proto_cli-aarch64-apple-darwin.tar.xz\
  --dest ./temp
```

#### Arguments

- `--url` (required) - URL of a file to download.
- `--dest` - Destination folder to save the file. Defaults to the current working directory.
- `--name` - Override the file name. Defaults to the file name in the URL.

### `migrate-nx` (v1.22.0)

> This extension is currently *experimental* and will be improved over time.

The `migrate-nx` extension can be used to migrate an Nx powered repository to moon. This process will convert the root `nx.json` and `workspace.json` files, and any `project.json` and `package.json` files found within the repository. The following changes are made:

- Migrates `targetDefaults` as global tasks to [`.moon/tasks/node.yml`](/docs/config/tasks#tasks) (or `bun.yml`), `namedInputs` as file groups, `workspaceLayout` as projects, and more.
- Migrates all `project.json` settings to [`moon.yml`](/docs/config/project#tasks) equivalent settings. Target to task conversion assumes the following:
  - Target `executor` will be removed, and we'll attempt to extract the appropriate npm package command. For example, `@nx/webpack:build` -> `webpack build`.
  - Target `options` will be converted to task `args`.
  - The `{projectRoot}` and `{workspaceRoot}` interpolations will be replaced with moon tokens.

```shell
$ moon ext migrate-nx
```

> **Caution:** Nx and moon are quite different, so many settings are either ignored when converting, or are not a 1:1 conversion. We do our best to convert as much as possible, but some manual patching will most likely be required! We suggest testing each converted task 1-by-1 to ensure it works as expected.

#### Arguments

- `--bun` - Migrate to Bun based commands instead of Node.js.
- `--cleanup` - Remove Nx configs/files after migrating.

#### Unsupported

The following features are not supported in moon, and are ignored when converting.

- Most settings in `nx.json`.
- Named input variants: external dependencies, dependent task output files, dependent project inputs, or runtime commands.
- Target `configurations` and `defaultConfiguration`. Another task will be created instead that uses `extends`.
- Project `root` and `sourceRoot`.

### `migrate-turborepo` (v1.21.0)

The `migrate-turborepo` extension can be used to migrate a Turborepo powered repository to moon. This process will convert the root `turbo.json` file, and any `turbo.json` files found within the repository. The following changes are made:

- Migrates `pipeline` (v1) and `tasks` (v2) global tasks to [`.moon/tasks/node.yml`](/docs/config/tasks#tasks) (or `bun.yml`) and project scoped tasks to [`moon.yml`](/docs/config/project#tasks). Task commands will execute `package.json` scripts through a package manager.
- Migrates root `global*` settings to [`.moon/tasks/node.yml`](/docs/config/tasks#implicitinputs) (or `bun.yml`) as `implicitInputs`.

```shell
$ moon ext migrate-turborepo
```

#### Arguments

- `--bun` - Migrate to Bun based commands instead of Node.js.
- `--cleanup` - Remove Turborepo configs/files after migrating.
