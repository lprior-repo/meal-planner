---
doc_id: ops/moonrepo/setup
chunk_id: ops/moonrepo/setup#chunk-1
heading_path: ["docker setup"]
chunk_type: prose
tokens: 196
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>setup</title>
  <description>The `moon setup` command can be used to setup the developer and pipeline environments. It achieves this by downloading and installing all configured tools into the toolchain.</description>
  <created_at>2026-01-02T19:55:26.939254</created_at>
  <updated_at>2026-01-02T19:55:26.939254</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/toolchain</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>setup,operations,moonrepo</tags>
</doc_metadata>
-->

# setup

> **Context**: The `moon setup` command can be used to setup the developer and pipeline environments. It achieves this by downloading and installing all configured t

The `moon setup` command can be used to setup the developer and pipeline environments. It achieves this by downloading and installing all configured tools into the toolchain.

```
$ moon setup
```

> **info**
> This command should rarely be used, as the environment is automatically setup when running other commands, like detecting affected projects, running a task, or generating a build artifact.
