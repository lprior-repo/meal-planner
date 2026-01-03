---
id: concept/moonrepo/task-graph
title: "Task graph"
category: concept
tags: ["concept", "moonrepo", "task"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Task graph</title>
  <description>The task graph is a representation of all configured tasks in the workspace and their relationships between each other, and is represented internally as a directed acyclic graph (DAG). This graph is d</description>
  <created_at>2026-01-02T19:55:27.223744</created_at>
  <updated_at>2026-01-02T19:55:27.223744</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Relationships" level="2"/>
    <section name="Required" level="3"/>
    <section name="Optional" level="3"/>
    <section name="What is the graph used for?" level="2"/>
  </sections>
  <features>
    <feature>optional</feature>
    <feature>relationships</feature>
    <feature>required</feature>
    <feature>what_is_the_graph_used_for</feature>
  </features>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>concept,moonrepo,task</tags>
</doc_metadata>
-->

# Task graph

> **Context**: The task graph is a representation of all configured tasks in the workspace and their relationships between each other, and is represented internally 

The task graph is a representation of all configured tasks in the workspace and their relationships between each other, and is represented internally as a directed acyclic graph (DAG). This graph is derived from information in the project graph. Below is a visual representation of a task graph.

> The `moon task-graph` command can be used to view the structure of your workspace.

## Relationships

A relationship is between a dependent (downstream task) and a dependency/requirement (upstream task). Relationships are derived explicitly with the task `deps` setting, and fall into 1 of 2 categories:

### Required

These are dependencies that are required to run and complete with a success, before the owning task can run. If a required dependency fails, then the owning task will abort.

### Optional

The opposite of required, these are dependencies that can either a) not exist during task inheritance, or b) run and fail without aborting the owning task.

## What is the graph used for?

Great question, the task graph is extremely important for running tasks (duh), and it also:

-   Is fed into the action graph that can be executed in topological order.
-   Determines affected tasks in continuous integration workflows.


## See Also

- [Documentation Index](./COMPASS.md)
