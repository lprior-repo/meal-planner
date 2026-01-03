---
doc_id: ops/moonrepo/teardown
chunk_id: ops/moonrepo/teardown#chunk-1
heading_path: ["teardown"]
chunk_type: prose
tokens: 169
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>teardown</title>
  <description>The `moon teardown` command, as its name infers, will teardown and clean the current environment, opposite the [`setup`](/docs/commands/setup) command. It achieves this by doing the following:</description>
  <created_at>2026-01-02T19:55:26.944663</created_at>
  <updated_at>2026-01-02T19:55:26.944663</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/commands/setup</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>teardown,operations,moonrepo</tags>
</doc_metadata>
-->

# teardown

> **Context**: The `moon teardown` command, as its name infers, will teardown and clean the current environment, opposite the [`setup`](/docs/commands/setup) command

The `moon teardown` command, as its name infers, will teardown and clean the current environment, opposite the [`setup`](/docs/commands/setup) command. It achieves this by doing the following:

- Uninstalling all configured tools in the toolchain.
- Removing any download or temporary files/folders.

```
$ moon teardown
```
