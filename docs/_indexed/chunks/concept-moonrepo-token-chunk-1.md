---
doc_id: concept/moonrepo/token
chunk_id: concept/moonrepo/token#chunk-1
heading_path: ["Tokens"]
chunk_type: prose
tokens: 218
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Tokens</title>
  <description>Tokens are variables and functions that can be used by [`command`](/docs/config/project#command), [`args`](/docs/config/project#args), [`env`](/docs/config/project#env) (&gt;= v1.12), [`inputs`](/docs/co</description>
  <created_at>2026-01-02T19:55:26.981168</created_at>
  <updated_at>2026-01-02T19:55:26.981168</updated_at>
  <language>en</language>
  <sections count="20">
    <section name="Functions" level="2"/>
    <section name="File groups" level="3"/>
    <section name="`@group`" level="3"/>
    <section name="`@dirs`" level="3"/>
    <section name="`@files`" level="3"/>
    <section name="`@globs`" level="3"/>
    <section name="`@root`" level="3"/>
    <section name="`@envs` (v1.21.0)" level="3"/>
    <section name="Inputs &amp; outputs" level="3"/>
    <section name="`@in`" level="3"/>
  </sections>
  <features>
    <feature>datetime</feature>
    <feature>dirs</feature>
    <feature>environment_v1300</feature>
    <feature>envs_v1210</feature>
    <feature>file_groups</feature>
    <feature>files</feature>
    <feature>functions</feature>
    <feature>globs</feature>
    <feature>group</feature>
    <feature>inputs_outputs</feature>
    <feature>meta_v1280</feature>
    <feature>miscellaneous</feature>
    <feature>project</feature>
    <feature>root</feature>
    <feature>task</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>tokens,concept,moonrepo</tags>
</doc_metadata>
-->

# Tokens

> **Context**: Tokens are variables and functions that can be used by [`command`](/docs/config/project#command), [`args`](/docs/config/project#args), [`env`](/docs/c

Tokens are variables and functions that can be used by [`command`](/docs/config/project#command), [`args`](/docs/config/project#args), [`env`](/docs/config/project#env) (>= v1.12), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs) when configuring a task. They provide a way of accessing file group paths, referencing values from other task fields, and referencing metadata about the project and task itself.
