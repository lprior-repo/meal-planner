---
doc_id: ops/extending/module-dependencies
chunk_id: ops/extending/module-dependencies#chunk-3
heading_path: ["module-dependencies", "Uninstallation"]
chunk_type: mixed
tokens: 56
summary: "To remove a dependency from your Dagger module, use the `dagger uninstall` command."
---
To remove a dependency from your Dagger module, use the `dagger uninstall` command. The `dagger uninstall` command can be passed either a remote repository reference or a local module name.

The commands below are equivalent:

```bash
dagger uninstall hello
dagger uninstall github.com/shykes/daggerverse/hello
```
