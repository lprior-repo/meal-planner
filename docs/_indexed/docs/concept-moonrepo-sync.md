---
id: concept/moonrepo/sync
title: "sync"
category: concept
tags: ["sync", "concept", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>sync</title>
  <description>Operations for syncing the workspace to a healthy state.</description>
  <created_at>2026-01-02T19:55:26.939857</created_at>
  <updated_at>2026-01-02T19:55:26.939857</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="codeowners" level="2"/>
    <section name="config-schemas" level="2"/>
    <section name="hooks" level="2"/>
    <section name="projects" level="2"/>
  </sections>
  <features>
    <feature>codeowners</feature>
    <feature>config-schemas</feature>
    <feature>hooks</feature>
    <feature>projects</feature>
  </features>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>sync,concept,moonrepo</tags>
</doc_metadata>
-->

# sync

> **Context**: Operations for syncing the workspace to a healthy state.

Operations for syncing the workspace to a healthy state.

## codeowners

The moon sync codeowners command will manually sync code owners, by aggregating all owners from projects, and generating a single `CODEOWNERS` file.

## config-schemas

The moon sync config-schemas command will manually generate JSON schemas to .moon/cache/schemas for all configuration files.

## hooks

The moon sync hooks command will manually sync hooks for the configured VCS.

## projects

The moon sync projects command will force sync all projects in the workspace to help achieve a healthy repository state.


## See Also

- [Documentation Index](./COMPASS.md)
