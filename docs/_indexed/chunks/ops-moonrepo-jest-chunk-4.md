---
doc_id: ops/moonrepo/jest
chunk_id: ops/moonrepo/jest#chunk-4
heading_path: ["Jest example", "FAQ"]
chunk_type: prose
tokens: 111
summary: "FAQ"
---

## FAQ

### How to test a single file or folder?

You can filter tests by passing a file name, folder name, glob, or regex pattern after `--`. Any passed files are relative from the project's root, regardless of where the `moon` command is being ran.

```
$ moon run <project>:test -- filename
```

### How to use `projects`?

With moon, there's no reason to use [`projects`](https://jestjs.io/docs/configuration#projects-arraystring--projectconfig) as the `test` task is ran *per* project. If you'd like to test multiple projects, use [`moon run :test`](/docs/commands/run).
