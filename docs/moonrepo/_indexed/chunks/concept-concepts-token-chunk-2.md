---
doc_id: concept/concepts/token
chunk_id: concept/concepts/token#chunk-2
heading_path: ["Tokens", "Functions"]
chunk_type: prose
tokens: 698
summary: "Functions"
---

## Functions

A token function is labeled as such as it takes a single argument, starts with an `@`, and is formatted as `@name(arg)`. The following token functions are available, grouped by their functionality.

> **Caution**: Token functions *must* be the only content within a value, as they expand to multiple files. When used in an `env` value, multiple files are joined with a comma (`,`).

### File groups

These functions reference file groups by name, where the name is passed as the argument.

### `@group`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@group(file_group)` token is a standard token that will be replaced with the file group items as-is, for both file paths and globs. This token merely exists for reusability purposes.

### `@dirs`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@dirs(file_group)` token will be replaced with an expanded list of directory paths, derived from the file group of the same name. If a glob pattern is detected within the file group, it will aggregate all directories found.

> **Warning**: This token walks the file system to verify each directory exists, and filters out those that don't. If using within `outputs`, you're better off using [`@group`](#group) instead.

### `@files`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@files(file_group)` token will be replaced with an expanded list of file paths, derived from the file group of the same name. If a glob pattern is detected within the file group, it will aggregate all files found.

> **Warning**: This token walks the file system to verify each file exists, and filters out those that don't. If using within `outputs`, you're better off using [`@group`](#group) instead.

### `@globs`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@globs(file_group)` token will be replaced with the list of glob patterns as-is, derived from the file group of the same name. If a non-glob pattern is detected within the file group, it will be ignored.

### `@root`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@root(file_group)` token will be replaced with the lowest common directory, derived from the file group of the same name. If a glob pattern is detected within the file group, it will walk the file system and aggregate all directories found before reducing.

> When there's no directories, or too many directories, this function will return the project root using `.`.

### `@envs` (v1.21.0)

> Usable in `inputs`.

The `@envs(file_group)` token will be replaced with all environment variables that have been configured in the group of the provided name.

### Inputs & outputs

### `@in`

> Usable in `script` and `args` only.

The `@in(index)` token will be replaced with a single path, derived from [`inputs`](/docs/config/project#inputs) by numerical index. If a glob pattern is referenced by index, the glob will be used as-is, instead of returning the expanded list of files.

### `@out`

> Usable in `script` and `args` only.

The `@out(index)` token will be replaced with a single path, derived from [`outputs`](/docs/config/project#outputs) by numerical index.

### Miscellaneous

### `@meta` (v1.28.0)

> Usable in `command`, `script`, `args`, `env`, `inputs`, and `outputs` only.

The `@meta(key)` token can be used to access project metadata and will be replaced with a value derived from [`project`](/docs/config/project#project) in [`moon.yml`](/docs/config/project).
