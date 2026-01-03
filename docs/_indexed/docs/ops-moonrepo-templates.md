---
id: ops/moonrepo/templates
title: "templates"
category: ops
tags: ["templates", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>templates</title>
  <description>The `moon templates` command will list all templates available for [code generation](/docs/commands/generate). This list will include the template title, description, default destination, where it&apos;s s</description>
  <created_at>2026-01-02T19:55:26.945143</created_at>
  <updated_at>2026-01-02T19:55:26.945143</updated_at>
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
    <entity relationship="uses">/docs/commands/generate</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>templates,operations,moonrepo</tags>
</doc_metadata>
-->

# templates

> **Context**: The `moon templates` command will list all templates available for [code generation](/docs/commands/generate). This list will include the template tit

v1.24.0

The `moon templates` command will list all templates available for [code generation](/docs/commands/generate). This list will include the template title, description, default destination, where it's source files are located, and more.

```
$ moon templates
```

## Options

- `--json` - Print templates in JSON format.

### Configuration

- [`generator`](/docs/config/workspace#generator) in `.moon/workspace.yml`


## See Also

- [code generation](/docs/commands/generate)
- [`generator`](/docs/config/workspace#generator)
