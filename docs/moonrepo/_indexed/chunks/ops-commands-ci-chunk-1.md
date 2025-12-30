---
doc_id: ops/commands/ci
chunk_id: ops/commands/ci#chunk-1
heading_path: ["ci"]
chunk_type: code
tokens: 169
summary: "ci"
---

# ci

> **Context**: The `moon ci` command is a special command that should be ran in a continuous integration (CI) environment, as it does all the heavy lifting necessary

The `moon ci` command is a special command that should be ran in a continuous integration (CI) environment, as it does all the heavy lifting necessary for effectively running tasks.

By default this will run all tasks that are affected by touched files and have the [`runInCI`](/docs/config/project#runinci) task option enabled.

```
$ moon ci
```

However, you can also provide a list of targets to explicitly run, which will still be filtered down by `runInCI`.

```
$ moon ci :build :lint
```

> View the official [continuous integration guide](/docs/guides/ci) for a more in-depth example of how to utilize this command.
