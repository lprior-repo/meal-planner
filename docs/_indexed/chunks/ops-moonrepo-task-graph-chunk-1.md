---
doc_id: ops/moonrepo/task-graph
chunk_id: ops/moonrepo/task-graph#chunk-1
heading_path: ["task-graph"]
chunk_type: prose
tokens: 179
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>task-graph</title>
  <description>The `moon task-graph [target]` (or `moon tg`) command will generate and serve a visual graph of all configured tasks as nodes, with dependencies between as edges, and can also output the graph in [Gra</description>
  <created_at>2026-01-02T19:55:26.942794</created_at>
  <updated_at>2026-01-02T19:55:26.942794</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Example output" level="2"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>example_output</feature>
    <feature>options</feature>
  </features>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>taskgraph,operations,moonrepo</tags>
</doc_metadata>
-->

# task-graph

> **Context**: The `moon task-graph [target]` (or `moon tg`) command will generate and serve a visual graph of all configured tasks as nodes, with dependencies betwe

v1.30.0

The `moon task-graph [target]` (or `moon tg`) command will generate and serve a visual graph of all configured tasks as nodes, with dependencies between as edges, and can also output the graph in [Graphviz DOT format](https://graphviz.org/doc/info/lang.html).

```
