---
doc_id: ops/extending/module-dependencies
chunk_id: ops/extending/module-dependencies#chunk-4
heading_path: ["module-dependencies", "Update"]
chunk_type: mixed
tokens: 101
summary: "To update a dependency in your Dagger module to the latest version (or the version specified), us..."
---
To update a dependency in your Dagger module to the latest version (or the version specified), use the `dagger update` command. The target module must be local.

The commands below are equivalent:

```bash
dagger update hello
dagger update github.com/shykes/daggerverse/hello
```

> **Note:** Given a dependency like `github.com/path/name@branch/tag`:
> - `dagger update github.com/path/name` updates the dependency to the latest commit of the branch/tag.
> - `dagger update github.com/path/name@version` updates the dependency to the latest commit for the `version` branch/tag.
