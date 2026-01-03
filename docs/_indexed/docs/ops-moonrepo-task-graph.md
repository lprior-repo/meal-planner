---
id: ops/moonrepo/task-graph
title: "task-graph"
category: ops
tags: ["taskgraph", "operations", "moonrepo"]
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
## Run the visualizer locally
$ moon task-graph

## Export to DOT format
$ moon task-graph --dot > graph.dot
```

> A task target can be passed to focus the graph to only that task and its dependencies. For example, `moon task-graph app:build`.

### Arguments

- `[target]` - Optional target of task to focus.

### Options

- `--dependents` - Include direct dependents of the focused task.
- `--dot` - Print the graph in DOT format.
- `--host` - The host address. Defaults to `127.0.0.1`. v1.36.0
- `--json` - Print the graph in JSON format.
- `--port` - The port to bind to. Defaults to a random port. v1.36.0

## Example output

The following output is an example of the graph in DOT format.

```
digraph {
    0 [ label="types:build" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    1 [ label="runtime:build" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    2 [ label="website:build" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    1 -> 0 [ label="required" arrowhead=box, arrowtail=box]
    2 -> 1 [ label="required" arrowhead=box, arrowtail=box]
    2 -> 0 [ label="required" arrowhead=box, arrowtail=box]
}
```


## See Also

- [Documentation Index](./COMPASS.md)
