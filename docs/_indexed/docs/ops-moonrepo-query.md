---
id: ops/moonrepo/query
title: "query"
category: ops
tags: ["query", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>query</title>
  <description>Query information about moon, its projects, their tasks, the environment, the pipeline, and many other aspects of the workspace.</description>
  <created_at>2026-01-02T19:55:26.928301</created_at>
  <updated_at>2026-01-02T19:55:26.928301</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="hash" level="2"/>
    <section name="hash-diff" level="2"/>
    <section name="projects" level="2"/>
    <section name="tasks" level="2"/>
    <section name="touched-files" level="2"/>
  </sections>
  <features>
    <feature>hash</feature>
    <feature>hash-diff</feature>
    <feature>projects</feature>
    <feature>tasks</feature>
    <feature>touched-files</feature>
  </features>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>query,operations,moonrepo</tags>
</doc_metadata>
-->

# query

> **Context**: Query information about moon, its projects, their tasks, the environment, the pipeline, and many other aspects of the workspace.

Query information about moon, its projects, their tasks, the environment, the pipeline, and many other aspects of the workspace.

## hash

Use the moon query hash sub-command to inspect the contents and sources of a generated hash, also known as the hash manifest. This is extremely useful in debugging task inputs.

## hash-diff

Use the moon query hash-diff sub-command to query the content and source differences between 2 generated hashes.

## projects

Use the moon query projects sub-command to query information about all projects in the project graph.

## tasks

Use the moon query tasks sub-command to query task information for all projects in the project graph.

## touched-files

Use the moon query touched-files sub-command to query for a list of touched files (added, modified, deleted, etc) using the current VCS state.


## See Also

- [Documentation Index](./COMPASS.md)
