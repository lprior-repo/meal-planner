---
id: ops/commands/ci
title: "ci"
category: ops
tags: ["operations", "commands"]
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

## Arguments

-   `...[target]` - [Targets](/docs/concepts/target) to run.

### Options

-   `--base <rev>` - Base branch, commit, or revision to compare against ([learn more](/docs/guides/ci#comparing-revisions)).
-   `--downstream` - Control the depth of downstream dependents. Defaults to `direct`. v1.41.7
-   `--head <rev>` - Current branch, commit, or revision to compare with ([learn more](/docs/guides/ci#comparing-revisions)).
-   `--job <index>` - Index of the current job.
-   `--jobTotal <total>` Total amount of jobs to run.
-   `--stdin` - Accept touched files from stdin for affected checks. v1.36.0
-   `--upstream` - Control the depth of upstream dependencies. Defaults to `deep`. v1.41.7

### Configuration

-   [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
-   [`tasks`](/docs/config/project#tasks) in `moon.yml`
-   [`tasks.*.options.runInCI`](/docs/config/project#runinci) in `moon.yml`


## See Also

- [`runInCI`](/docs/config/project#runinci)
- [continuous integration guide](/docs/guides/ci)
- [Targets](/docs/concepts/target)
- [learn more](/docs/guides/ci#comparing-revisions)
- [learn more](/docs/guides/ci#comparing-revisions)
