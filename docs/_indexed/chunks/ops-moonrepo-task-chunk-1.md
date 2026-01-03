---
doc_id: ops/moonrepo/task
chunk_id: ops/moonrepo/task#chunk-1
heading_path: ["task"]
chunk_type: prose
tokens: 209
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>task</title>
  <description>The `moon task &lt;target&gt;` (or `moon t`) command will display information about a task that has been configured and exists within a project. If a task does not exist, the program will return with a 1 ex</description>
  <created_at>2026-01-02T19:55:26.943740</created_at>
  <updated_at>2026-01-02T19:55:26.943740</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Example output" level="2"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>example_output</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>task,operations,moonrepo</tags>
</doc_metadata>
-->

# task

> **Context**: The `moon task <target>` (or `moon t`) command will display information about a task that has been configured and exists within a project. If a task d

v1.1.0

The `moon task <target>` (or `moon t`) command will display information about a task that has been configured and exists within a project. If a task does not exist, the program will return with a 1 exit code.

```
$ moon task web:build
```
