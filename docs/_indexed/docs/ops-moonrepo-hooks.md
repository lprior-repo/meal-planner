---
id: ops/moonrepo/hooks
title: "sync hooks"
category: ops
tags: ["sync", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>sync hooks</title>
  <description>The `moon sync hooks` command will manually sync hooks for the configured [VCS](/docs/config/workspace#vcs), by generating and referencing hook scripts from the [`vcs.hooks`](/docs/config/workspace#ho</description>
  <created_at>2026-01-02T19:55:26.941401</created_at>
  <updated_at>2026-01-02T19:55:26.941401</updated_at>
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
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/guides/vcs-hooks</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>sync,operations,moonrepo</tags>
</doc_metadata>
-->

# sync hooks

> **Context**: The `moon sync hooks` command will manually sync hooks for the configured [VCS](/docs/config/workspace#vcs), by generating and referencing hook script

v1.9.0

The `moon sync hooks` command will manually sync hooks for the configured [VCS](/docs/config/workspace#vcs), by generating and referencing hook scripts from the [`vcs.hooks`](/docs/config/workspace#hooks) setting. Refer to the official [VCS hooks](/docs/guides/vcs-hooks) guide for more information.

```
$ moon sync hooks
```

## Options

- `--clean` - Clean and remove previously generated hooks.
- `--force` - Bypass cache and force create hooks.

### Configuration

- [`vcs.hooks`](/docs/config/workspace#hooks) in `.moon/workspace.yml`


## See Also

- [VCS](/docs/config/workspace#vcs)
- [`vcs.hooks`](/docs/config/workspace#hooks)
- [VCS hooks](/docs/guides/vcs-hooks)
- [`vcs.hooks`](/docs/config/workspace#hooks)
