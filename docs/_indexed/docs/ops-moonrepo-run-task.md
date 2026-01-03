---
id: ops/moonrepo/run-task
title: "Run a task"
category: ops
tags: ["run", "advanced", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Run a task</title>
  <description>Even though we&apos;ve created a task, it&apos;s not useful unless we *run it*, which is done with the `moon run &lt;target&gt;` command. This command requires a single argument, a primary target, which is the pairin</description>
  <created_at>2026-01-02T19:55:27.230207</created_at>
  <updated_at>2026-01-02T19:55:27.230207</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Running dependents" level="2"/>
    <section name="Running based on affected files only" level="2"/>
    <section name="Using remote changes" level="3"/>
    <section name="Filtering based on change status" level="3"/>
    <section name="Passing arguments to the underlying command" level="2"/>
    <section name="Advanced run targeting" level="2"/>
    <section name="Next steps" level="2"/>
  </sections>
  <features>
    <feature>advanced_run_targeting</feature>
    <feature>filtering_based_on_change_status</feature>
    <feature>next_steps</feature>
    <feature>running_based_on_affected_files_only</feature>
    <feature>running_dependents</feature>
    <feature>using_remote_changes</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/migrate-to-moon</entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/commands/run</entity>
  </related_entities>
  <examples count="9">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>run,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Run a task

> **Context**: Even though we've created a task, it's not useful unless we *run it*, which is done with the `moon run <target>` command. This command requires a sing

Even though we've created a task, it's not useful unless we *run it*, which is done with the `moon run <target>` command. This command requires a single argument, a primary target, which is the pairing of a scope and task name. In the example below, our project is `app`, the task is `build`, and the target is `app:build`.

```
$ moon run app:build

## In v1.14+, "run" can be omitted
$ moon app:build
```

When this command is ran, it will do the following:

-   Generate a directed acyclic graph, known as the action (dependency) graph.
-   Insert `deps` as targets into the graph.
-   Insert the primary target into the graph.
-   Run all tasks in the graph in parallel and in topological order (the dependency chain).
-   For each task, calculate hashes and either:
    -   On cache hit, exit early and return the last run.
    -   On cache miss, run the task and generate a new cache.

## Running dependents

moon will *always* run upstream dependencies (`deps`) before running the primary target, as their outputs may be required for the primary target to function correctly.

However, if you're working on a project that is shared and consumed by other projects, you may want to verify that downstream dependents have not been indirectly broken by any changes. This can be achieved by passing the `--dependents` option, which will run dependent targets *after* the primary target.

```
$ moon run app:build --dependents
```

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

## Passing arguments to the underlying command

If you'd like to pass arbitrary arguments to the underlying task command, in addition to the already defined `args`, you can pass them after `--`. These arguments are *appended as-is*.

```
$ moon run app:build -- --force
```

> The `--` delimiter and any arguments *must* be defined last on the command line.

## Advanced run targeting

By this point you should have a basic understanding of how to run tasks, but with moon, we want to provide support for advanced workflows and development scenarios. For example, running a target in all projects:

```
$ moon run :build
```

Or perhaps running a target based on a query:

```
$ moon run :build --query "language=[javascript, typescript]"
```

Jump to the official `moon run` documentation for more examples!

## Next steps

- [Migrate to moon](/docs/migrate-to-moon)
- [Learn about tasks](/docs/concepts/task)
- [Learn about `moon run`](/docs/commands/run)


## See Also

- [Migrate to moon](/docs/migrate-to-moon)
- [Learn about tasks](/docs/concepts/task)
- [Learn about `moon run`](/docs/commands/run)
