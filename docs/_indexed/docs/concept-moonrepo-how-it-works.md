---
id: concept/moonrepo/how-it-works
title: "How it works"
category: concept
tags: ["how", "javascript", "concept", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>How it works</title>
  <description>Although moon is currently focusing on the JavaScript ecosystem, our long-term vision is to be a multi-language task runner and monorepo management tool.</description>
  <created_at>2026-01-02T19:55:27.216077</created_at>
  <updated_at>2026-01-02T19:55:27.216077</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Languages" level="2"/>
    <section name="Project graph" level="2"/>
    <section name="Task graph" level="2"/>
    <section name="Action graph" level="2"/>
  </sections>
  <features>
    <feature>action_graph</feature>
    <feature>languages</feature>
    <feature>project_graph</feature>
    <feature>task_graph</feature>
  </features>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>how,javascript,concept,moonrepo</tags>
</doc_metadata>
-->

# How it works

> **Context**: Although moon is currently focusing on the JavaScript ecosystem, our long-term vision is to be a multi-language task runner and monorepo management to

## Languages

Although moon is currently focusing on the JavaScript ecosystem, our long-term vision is to be a multi-language task runner and monorepo management tool.

## Project graph

The project graph is a representation of all configured projects in the workspace and their relationships between each other.

## Task graph

The task graph is a representation of all configured tasks in the workspace and their relationships between each other.

## Action graph

When you run a task on the command line, we generate an action graph to ensure dependencies of tasks have ran before running run the primary task.


## See Also

- [Documentation Index](./COMPASS.md)
