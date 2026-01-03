---
doc_id: ops/moonrepo/extensions
chunk_id: ops/moonrepo/extensions#chunk-1
heading_path: ["Extensions"]
chunk_type: prose
tokens: 286
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Extensions</title>
  <description>An extension is a WASM plugin that allows you to extend moon with additional functionality, have whitelisted access to the file system, and receive partial information about the current workspace. Ext</description>
  <created_at>2026-01-02T19:55:27.126056</created_at>
  <updated_at>2026-01-02T19:55:27.126056</updated_at>
  <language>en</language>
  <sections count="15">
    <section name="Using extensions" level="2"/>
    <section name="Built-in extensions" level="2"/>
    <section name="`download`" level="3"/>
    <section name="Arguments" level="4"/>
    <section name="`migrate-nx` (v1.22.0)" level="3"/>
    <section name="Arguments" level="4"/>
    <section name="Unsupported" level="4"/>
    <section name="`migrate-turborepo` (v1.21.0)" level="3"/>
    <section name="Arguments" level="4"/>
    <section name="Creating an extension" level="2"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>built-in_extensions</feature>
    <feature>configuration_schema</feature>
    <feature>creating_an_extension</feature>
    <feature>download</feature>
    <feature>implementing_execution</feature>
    <feature>js_args</feature>
    <feature>js_config</feature>
    <feature>migrate-nx_v1220</feature>
    <feature>migrate-turborepo_v1210</feature>
    <feature>registering_metadata</feature>
    <feature>rust_execute_extension</feature>
    <feature>rust_host_log</feature>
    <feature>rust_register_extension</feature>
    <feature>supporting_arguments</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/commands/ext</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/commands/ext</entity>
    <entity relationship="uses">/proto</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="15">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>extensions,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Extensions

> **Context**: An extension is a WASM plugin that allows you to extend moon with additional functionality, have whitelisted access to the file system, and receive pa

v1.20.0

An extension is a WASM plugin that allows you to extend moon with additional functionality, have whitelisted access to the file system, and receive partial information about the current workspace. Extensions are extremely useful in offering new and unique functionality that doesn't need to be built into moon's core. It also enables the community to build and share their own extensions!
