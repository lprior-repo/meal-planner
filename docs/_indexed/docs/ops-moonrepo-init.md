---
id: ops/moonrepo/init
title: "init"
category: ops
tags: ["init", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>init</title>
  <description>The `moon init` command will initialize moon into a repository and scaffold necessary config files by creating a `.moon` folder.</description>
  <created_at>2026-01-02T19:55:26.916550</created_at>
  <updated_at>2026-01-02T19:55:26.916550</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Initializing a specific tool" level="4"/>
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>initializing_a_specific_tool</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/toolchain</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>init,operations,moonrepo</tags>
</doc_metadata>
-->

# init

> **Context**: The `moon init` command will initialize moon into a repository and scaffold necessary config files by creating a `.moon` folder.

The `moon init` command will initialize moon into a repository and scaffold necessary config files by creating a `.moon` folder.

```
$ moon init

## In another directory
$ moon init --to ./app
```

### Initializing a specific tool

The command can also be used to initialize a specific tool into the toolchain *after* moon has already been initialized. Perfect for adopting a new language into the workspace.

```
$ moon init node
```

When ran, we'll prompt you with a handful of questions, and generate (or modify) the [`.moon/toolchain.yml`](/docs/config/toolchain) file.

### Arguments

-   `[tool]` - Individual tool to initialize and configure.
    -   Accepts: `bun`, `node`, `rust`, `typescript`

### Options

-   `--force` - Overwrite existing config files if they exist.
-   `--minimal` - Generate minimal configurations and sane defaults.
-   `--to` - Destination to initialize and scaffold into. Defaults to `.` (current working directory).
-   `--yes` - Skip all prompts and enables tools based on file detection.


## See Also

- [`.moon/toolchain.yml`](/docs/config/toolchain)
