---
doc_id: ops/moonrepo/run
chunk_id: ops/moonrepo/run#chunk-7
heading_path: ["run", "Run `build` in projects matching the query"]
chunk_type: prose
tokens: 523
summary: "Run `build` in projects matching the query"
---

## Run `build` in projects matching the query
$ moon run :build --query "language=javascript && projectType=library"
```

> **info**
> How affected status is determined is highly dependent on whether the command is running locally, in CI, and what options are provided. The following scenarios are possible:
> - When `--affected` is provided, will explicitly use `--remote` to determine CI or local.
> - When not provided, will use `git diff` in CI, or `git status` for local.
> - To bypass affected logic entirely, use `--force`.

> **info**
> The default behavior for `moon run` is to "fail fast", meaning that any failed task will immediately abort execution of the entire action graph. Pass `--no-bail` to execute as many tasks as safely possible (tasks with upstream failures will be skipped to avoid side effects). This is the default behavior for `moon ci`, and is also useful for pre-commit hooks.

### Arguments

- `...<target>` - [Targets](/docs/concepts/target) or project relative tasks to run.
- `[-- <args>]` - Additional arguments to [pass to the underlying command](/docs/run-task#passing-arguments-to-the-underlying-command).

### Options

- `-f`, `--force` - Force run and ignore touched files and affected status. Will not query VCS.
- `--dependents` - Run downstream dependent targets (of the same task name) as well.
- `-i`, `--interactive` - Run the target in an interactive mode.
- `--query` - Filter projects to run targets against using [a query statement](/docs/concepts/query-lang). v1.3.0
- `-s`, `--summary` - Display a summary and stats of the current run. v1.25.0
- `-u`, `--updateCache` - Bypass cache and force update any existing items.
- `--no-actions` - Run the task without running [other actions](/docs/how-it-works/action-graph) in the pipeline. v1.34.0
- `-n`, `--no-bail` - When a task fails, continue executing other tasks instead of aborting immediately

#### Debugging

- `--profile <type>` - Record and [generate a profile](/docs/guides/profile) for ran tasks.
  - Types: `cpu`, `heap`

#### Affected

- `--affected` - Only run target if affected by changed files, *otherwise* will always run.
- `--remote` - Determine affected against remote by comparing `HEAD` against a base revision (default branch), *otherwise* uses local changes.
  - Can control revisions with `MOON_BASE` and `MOON_HEAD`.
- `--status <type>` - Filter affected based on a change status. Can be passed multiple times.
  - Types: `all` (default), `added`, `deleted`, `modified`, `staged`, `unstaged`, `untracked`
- `--stdin` - Accept touched files from stdin for affected checks. v1.36.0

### Configuration

- [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
- [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
- [`tasks`](/docs/config/project#tasks) in `moon.yml`
