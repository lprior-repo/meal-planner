---
doc_id: ops/commands/ci
chunk_id: ops/commands/ci#chunk-2
heading_path: ["ci", "Arguments"]
chunk_type: prose
tokens: 140
summary: "Arguments"
---

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
