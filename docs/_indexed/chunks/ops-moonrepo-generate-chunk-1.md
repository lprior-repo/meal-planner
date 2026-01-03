---
doc_id: ops/moonrepo/generate
chunk_id: ops/moonrepo/generate#chunk-1
heading_path: ["generate"]
chunk_type: prose
tokens: 191
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>generate</title>
  <description>The `moon generate &lt;name&gt;` (or `moon g`) command will generate code (files and folders) from a pre-defined template of the same name, using an interactive series of prompts. Templates are located base</description>
  <created_at>2026-01-02T19:55:26.915343</created_at>
  <updated_at>2026-01-02T19:55:26.915343</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>options</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/guides/codegen</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>generate,operations,moonrepo</tags>
</doc_metadata>
-->

# generate

> **Context**: The `moon generate <name>` (or `moon g`) command will generate code (files and folders) from a pre-defined template of the same name, using an interac

The `moon generate <name>` (or `moon g`) command will generate code (files and folders) from a pre-defined template of the same name, using an interactive series of prompts. Templates are located based on the [`generator.templates`](/docs/config/workspace#templates) setting.

```
