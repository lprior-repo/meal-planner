---
doc_id: ref/moonrepo/task
chunk_id: ref/moonrepo/task#chunk-1
heading_path: ["Tasks"]
chunk_type: prose
tokens: 237
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>build-tools</category>
  <title>Tasks</title>
  <description>Tasks are commands that are ran in the context of a [project](/docs/concepts/project). Underneath the hood, a task is simply a binary or system command that is ran as a child process.</description>
  <created_at>2026-01-02T19:55:26.977460</created_at>
  <updated_at>2026-01-02T19:55:26.977460</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="IDs" level="2"/>
    <section name="Types" level="2"/>
    <section name="Modes" level="2"/>
    <section name="Local only" level="3"/>
    <section name="Internal only (v1.23.0)" level="3"/>
    <section name="Interactive (v1.12.0)" level="3"/>
    <section name="Persistent (v1.6.0)" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Commands vs Scripts" level="3"/>
    <section name="Inheritance" level="3"/>
  </sections>
  <features>
    <feature>commands_vs_scripts</feature>
    <feature>configuration</feature>
    <feature>inheritance</feature>
    <feature>interactive_v1120</feature>
    <feature>internal_only_v1230</feature>
    <feature>local_only</feature>
    <feature>modes</feature>
    <feature>persistent_v160</feature>
    <feature>types</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/commands/check</entity>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses">/docs/commands/task</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>tasks,advanced,reference,moonrepo</tags>
</doc_metadata>
-->

# Tasks

> **Context**: Tasks are commands that are ran in the context of a [project](/docs/concepts/project). Underneath the hood, a task is simply a binary or system comman

Tasks are commands that are ran in the context of a [project](/docs/concepts/project). Underneath the hood, a task is simply a binary or system command that is ran as a child process.
