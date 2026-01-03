---
id: ops/moonrepo/touched-files
title: "query touched-files"
category: ops
tags: ["query", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>query touched-files</title>
  <description>Use the `moon query touched-files` sub-command to query for a list of touched files (added, modified, deleted, etc) using the current VCS state. These are the same queries that [`moon ci`](/docs/comma</description>
  <created_at>2026-01-02T19:55:26.934718</created_at>
  <updated_at>2026-01-02T19:55:26.934718</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Options" level="3"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/commands/ci</entity>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/guides/ci</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>query,operations,moonrepo</tags>
</doc_metadata>
-->

# query touched-files

> **Context**: Use the `moon query touched-files` sub-command to query for a list of touched files (added, modified, deleted, etc) using the current VCS state. These

Use the `moon query touched-files` sub-command to query for a list of touched files (added, modified, deleted, etc) using the current VCS state. These are the same queries that [`moon ci`](/docs/commands/ci) and [`moon run`](/docs/commands/run) use under the hood.

Touches files are determined using the following logic:

- If `--defaultBranch` is provided, and the current branch is the [`vcs.defaultBranch`](/docs/config/workspace#defaultbranch), then compare against the previous revision of the default branch (`HEAD~1`). This is what [continuous integration](/docs/guides/ci) uses.
- If `--local` is provided, touched files are based on your local index only (`git status`).
- Otherwise, then compare the defined base (`--base`) against head (`--head`).

```
## Return all files
$ moon query touched-files

## Return deleted files
$ moon query touched-files --status deleted

## Return all files between 2 revisions
$ moon query touched-files --base <branch> --head <commit>
```

By default, this will output a list of absolute file paths, separated by new lines.

```
/absolute/file/one.ts
/absolute/file/two.ts
```

The files can also be output in JSON by passing the `--json` flag. The output has the following structure:

```
{
	files: string[],
	options: QueryOptions,
}
```

### Options

- `--defaultBranch` - When on the default branch, compare against the previous revision.
- `--base <rev>` - Base branch, commit, or revision to compare against. Defaults to [`vcs.defaultBranch`](/docs/config/workspace#defaultbranch).
- `--head <rev>` - Current branch, commit, or revision to compare with. Defaults to `HEAD`.
- `--json` - Display the files in JSON format.
- `--local` - Gather files from the local state instead of remote.
- `--remote` - Gather files from the remote state instead of local.
- `--status <type>` - Filter files based on a touched status. Can be passed multiple times.
  - Types: `all` (default), `added`, `deleted`, `modified`, `staged`, `unstaged`, `untracked`

### Configuration

- [`vcs`](/docs/config/workspace#vcs) in `.moon/workspace.yml`


## See Also

- [`moon ci`](/docs/commands/ci)
- [`moon run`](/docs/commands/run)
- [`vcs.defaultBranch`](/docs/config/workspace#defaultbranch)
- [continuous integration](/docs/guides/ci)
- [`vcs.defaultBranch`](/docs/config/workspace#defaultbranch)
