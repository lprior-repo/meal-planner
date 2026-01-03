---
doc_id: ref/moonrepo/file-group
chunk_id: ref/moonrepo/file-group#chunk-1
heading_path: ["File groups"]
chunk_type: prose
tokens: 210
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>build-tools</category>
  <title>File groups</title>
  <description>File groups are a mechanism for grouping similar types of files and environment variables within a project using [file glob patterns or literal file paths](/docs/concepts/file-pattern). These groups a</description>
  <created_at>2026-01-02T19:55:26.960844</created_at>
  <updated_at>2026-01-02T19:55:26.960844</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Configuration" level="2"/>
    <section name="Token functions" level="3"/>
    <section name="Inheritance and merging" level="2"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>inheritance_and_merging</feature>
    <feature>token_functions</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/file-pattern</entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/concepts/token</entity>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>file,reference,moonrepo</tags>
</doc_metadata>
-->

# File groups

> **Context**: File groups are a mechanism for grouping similar types of files and environment variables within a project using [file glob patterns or literal file p

File groups are a mechanism for grouping similar types of files and environment variables within a project using [file glob patterns or literal file paths](/docs/concepts/file-pattern). These groups are then used by [tasks](/docs/concepts/task) to calculate functionality like cache computation, affected files since last change, deterministic builds, and more.
