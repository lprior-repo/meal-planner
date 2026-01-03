---
doc_id: ops/moonrepo/run
chunk_id: ops/moonrepo/run#chunk-1
heading_path: ["run"]
chunk_type: prose
tokens: 228
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>run</title>
  <description>The `moon run` (or `moon r`, or `moonx`) command will run one or many [targets](/docs/concepts/target) and all of its dependencies in topological order. Each run will incrementally cache each task, im</description>
  <created_at>2026-01-02T19:55:26.936429</created_at>
  <updated_at>2026-01-02T19:55:26.936429</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Debugging" level="4"/>
    <section name="Affected" level="4"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>affected</feature>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>debugging</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/run-task</entity>
    <entity relationship="uses">/docs/cheat-sheet</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/run-task</entity>
    <entity relationship="uses">/docs/concepts/query-lang</entity>
    <entity relationship="uses">/docs/how-it-works/action-graph</entity>
    <entity relationship="uses">/docs/guides/profile</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>run,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# run

> **Context**: The `moon run` (or `moon r`, or `moonx`) command will run one or many [targets](/docs/concepts/target) and all of its dependencies in topological orde

The `moon run` (or `moon r`, or `moonx`) command will run one or many [targets](/docs/concepts/target) and all of its dependencies in topological order. Each run will incrementally cache each task, improving speed and development times... over time. View the official [Run a task](/docs/run-task) and [Cheat sheet](/docs/cheat-sheet#tasks) articles for more information!

```
