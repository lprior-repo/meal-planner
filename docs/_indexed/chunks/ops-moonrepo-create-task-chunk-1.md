---
doc_id: ops/moonrepo/create-task
chunk_id: ops/moonrepo/create-task#chunk-1
heading_path: ["Create a task"]
chunk_type: prose
tokens: 297
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Create a task</title>
  <description>The primary focus of moon is a task runner, and for it to operate in any capacity, it requires tasks to run. In moon, a task is a binary or system command that is ran as a child process within the con</description>
  <created_at>2026-01-02T19:55:27.031391</created_at>
  <updated_at>2026-01-02T19:55:27.031391</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Configuring a task" level="2"/>
    <section name="Inputs" level="3"/>
    <section name="Outputs" level="3"/>
    <section name="Depending on other tasks" level="2"/>
    <section name="Using file groups" level="2"/>
    <section name="Next steps" level="2"/>
  </sections>
  <features>
    <feature>configuring_a_task</feature>
    <feature>depending_on_other_tasks</feature>
    <feature>inputs</feature>
    <feature>next_steps</feature>
    <feature>outputs</feature>
    <feature>using_file_groups</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/run-task</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/concepts/token</entity>
  </related_entities>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>create,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Create a task

> **Context**: The primary focus of moon is a task runner, and for it to operate in any capacity, it requires tasks to run. In moon, a task is a binary or system com

The primary focus of moon is a task runner, and for it to operate in any capacity, it requires tasks to run. In moon, a task is a binary or system command that is ran as a child process within the context of a project (is the current working directory). Tasks are defined per project with `moon.yml`, or inherited by many projects with `.moon/tasks.yml`, but can also be inferred from a language's ecosystem (we'll talk about this later).
