---
doc_id: ops/moonrepo/check
chunk_id: ops/moonrepo/check#chunk-1
heading_path: ["check"]
chunk_type: prose
tokens: 192
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>check</title>
  <description>The `moon check [...projects]` (or `moon c`) command will run *all* [build and test tasks](/docs/concepts/task#types) for one or many projects. This is a convenience command for verifying the current </description>
  <created_at>2026-01-02T19:55:26.904124</created_at>
  <updated_at>2026-01-02T19:55:26.904124</updated_at>
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
  <related_entities>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>check,operations,moonrepo</tags>
</doc_metadata>
-->

# check

> **Context**: The `moon check [...projects]` (or `moon c`) command will run *all* [build and test tasks](/docs/concepts/task#types) for one or many projects. This i

The `moon check [...projects]` (or `moon c`) command will run *all* [build and test tasks](/docs/concepts/task#types) for one or many projects. This is a convenience command for verifying the current state of a project, instead of running multiple [`moon run`](/docs/commands/run) commands.

```
