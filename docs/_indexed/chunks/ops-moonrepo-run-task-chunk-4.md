---
doc_id: ops/moonrepo/run-task
chunk_id: ops/moonrepo/run-task#chunk-4
heading_path: ["Run a task", "Running based on affected files only"]
chunk_type: code
tokens: 275
summary: "Running based on affected files only"
---

## Running based on affected files only

By default `moon run` will *always* run the target, regardless if files have actually changed. However, this is typically fine because of our smart hashing & cache layer. With that being said, if you'd like to *only* run a target if files have changed, pass the `--affected` flag.

```
$ moon run app:build --affected
```

Under the hood, we extract locally touched (created, modified, staged, etc) files from your configured VCS, and exit early if no files intersect with the task's inputs.

### Using remote changes

If you'd like to determine affected files based on remote changes instead of local changes, pass the `--remote` flag. This will extract touched files by comparing the current `HEAD` against the `vcs.defaultBranch`.

```
$ moon run app:build --affected --remote
```

### Filtering based on change status

We can take this a step further by filtering down affected files based on a change status, using the `--status` option. This option accepts the following values: `added`, `deleted`, `modified`, `staged`, `unstaged`, `untracked`. If not provided, the option defaults to all.

```
$ moon run app:build --affected --status deleted
```

Multiple status can be provided by passing the `--status` option multiple times.

```
$ moon run app:build --affected --status deleted --status modified
```
