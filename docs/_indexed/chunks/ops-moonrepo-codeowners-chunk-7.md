---
doc_id: ops/moonrepo/codeowners
chunk_id: ops/moonrepo/codeowners#chunk-7
heading_path: ["sync codeowners", "Generating `CODEOWNERS`"]
chunk_type: code
tokens: 131
summary: "Generating `CODEOWNERS`"
---

## Generating `CODEOWNERS`

Code owners is an opt-in feature, and as such, the `CODEOWNERS` file can be generated in a few ways. The first is manually, with the [`moon sync codeowners`](/docs/commands/sync/codeowners) command.

```shell
$ moon sync codeowners
```

While this works, it is a manual process, and can easily be forgotten, resulting in an out-of-date file.

An alternative solution is the [`codeowners.syncOnRun`](/docs/config/workspace#synconrun) setting in [`.moon/workspace.yml`](/docs/config/workspace#codeowners), that when enabled, moon will automatically generate a `CODEOWNERS` file when a [target](/docs/concepts/target) is ran.

.moon/workspace.yml

```yaml
codeowners:
  syncOnRun: true
```

> The format and location of the `CODEOWNERS` file is based on the [`vcs.provider`](/docs/config/workspace#provider) setting.
