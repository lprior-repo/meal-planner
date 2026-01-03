---
doc_id: ops/moonrepo/toolchain-2
chunk_id: ops/moonrepo/toolchain-2#chunk-6
heading_path: [".moon/toolchain.{pkl,yml}", "`typescript`"]
chunk_type: code
tokens: 172
summary: "`typescript`"
---

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
