---
doc_id: ops/moonrepo/project-graph
chunk_id: ops/moonrepo/project-graph#chunk-1
heading_path: ["project-graph"]
chunk_type: prose
tokens: 235
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Project graph</title>
  <description>The project graph is a representation of all configured projects in the workspace and their relationships between each other, and is represented internally as a directed acyclic graph (DAG). Below is </description>
  <created_at>2026-01-02T19:55:27.222005</created_at>
  <updated_at>2026-01-02T19:55:27.222005</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Relationships" level="2"/>
    <section name="Explicit" level="3"/>
    <section name="Implicit" level="3"/>
    <section name="Scopes" level="3"/>
    <section name="What is the graph used for?" level="2"/>
  </sections>
  <features>
    <feature>explicit</feature>
    <feature>implicit</feature>
    <feature>relationships</feature>
    <feature>scopes</feature>
    <feature>what_is_the_graph_used_for</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>project,operations,moonrepo</tags>
</doc_metadata>
-->

# Project graph

> **Context**: The project graph is a representation of all configured projects in the workspace and their relationships between each other, and is represented inter

The project graph is a representation of all configured projects in the workspace and their relationships between each other, and is represented internally as a directed acyclic graph (DAG). Below is a visual representation of a project graph, composed of multiple applications and libraries, where both project types depend on libraries.

> The `moon project-graph` command can be used to view the structure of your workspace.
