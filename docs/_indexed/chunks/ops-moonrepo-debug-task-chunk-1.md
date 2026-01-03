---
doc_id: ops/moonrepo/debug-task
chunk_id: ops/moonrepo/debug-task#chunk-1
heading_path: ["Debugging a task"]
chunk_type: prose
tokens: 265
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Debugging a task</title>
  <description>Running [tasks](/docs/concepts/task) is the most common way to interact with moon, so what do you do when your task isn&apos;t working as expected? Diagnose it of course! Diagnosing the root cause of a bro</description>
  <created_at>2026-01-02T19:55:27.070721</created_at>
  <updated_at>2026-01-02T19:55:27.070721</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Verify configuration" level="2"/>
    <section name="Verify inherited configuration" level="3"/>
    <section name="Inspect trace logs" level="2"/>
    <section name="Inspect the hash manifest" level="2"/>
    <section name="Diffing a previous hash" level="3"/>
    <section name="Ask for help" level="2"/>
  </sections>
  <features>
    <feature>ask_for_help</feature>
    <feature>diffing_a_previous_hash</feature>
    <feature>inspect_the_hash_manifest</feature>
    <feature>inspect_trace_logs</feature>
    <feature>verify_configuration</feature>
    <feature>verify_inherited_configuration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/token</entity>
    <entity relationship="uses">/docs/concepts/token</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/commands/task</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>advanced,debugging,operations,moonrepo</tags>
</doc_metadata>
-->

# Debugging a task

> **Context**: Running [tasks](/docs/concepts/task) is the most common way to interact with moon, so what do you do when your task isn't working as expected? Diagnos

Running [tasks](/docs/concepts/task) is the most common way to interact with moon, so what do you do when your task isn't working as expected? Diagnose it of course! Diagnosing the root cause of a broken task can be quite daunting, but do not fret, as the following steps will help guide you in this endeavor.
