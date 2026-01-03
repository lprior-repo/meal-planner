---
doc_id: ops/moonrepo/action-graph
chunk_id: ops/moonrepo/action-graph#chunk-1
heading_path: ["action-graph"]
chunk_type: prose
tokens: 243
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Action graph</title>
  <description>When you run a task on the command line, we generate an action graph to ensure dependencies of tasks have ran before running run the primary task.</description>
  <created_at>2026-01-02T19:55:27.216775</created_at>
  <updated_at>2026-01-02T19:55:27.216775</updated_at>
  <language>en</language>
  <sections count="11">
    <section name="Actions" level="2"/>
    <section name="Sync workspace" level="3"/>
    <section name="Setup toolchain" level="3"/>
    <section name="Setup environment (v1.35.0)" level="3"/>
    <section name="Setup proto (v1.39.0)" level="3"/>
    <section name="Install dependencies" level="3"/>
    <section name="Sync project" level="3"/>
    <section name="Run task" level="3"/>
    <section name="Run interactive task" level="3"/>
    <section name="Run persistent task" level="3"/>
  </sections>
  <features>
    <feature>actions</feature>
    <feature>install_dependencies</feature>
    <feature>run_interactive_task</feature>
    <feature>run_persistent_task</feature>
    <feature>run_task</feature>
    <feature>setup_environment_v1350</feature>
    <feature>setup_proto_v1390</feature>
    <feature>setup_toolchain</feature>
    <feature>sync_project</feature>
    <feature>sync_workspace</feature>
    <feature>what_is_the_graph_used_for</feature>
  </features>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>action,operations,moonrepo</tags>
</doc_metadata>
-->

# Action graph

> **Context**: When you run a task on the command line, we generate an action graph to ensure dependencies of tasks have ran before running run the primary task.

When you run a task on the command line, we generate an action graph to ensure dependencies of tasks have ran before running run the primary task.

The action graph is a representation of all tasks, derived from the project graph and task graph, and is also represented internally as a directed acyclic graph (DAG).
