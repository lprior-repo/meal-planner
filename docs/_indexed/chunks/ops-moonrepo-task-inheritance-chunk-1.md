---
doc_id: ops/moonrepo/task-inheritance
chunk_id: ops/moonrepo/task-inheritance#chunk-1
heading_path: ["Task inheritance"]
chunk_type: prose
tokens: 262
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Task inheritance</title>
  <description>Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be defined once at the workspace-level, and are then </description>
  <created_at>2026-01-02T19:55:26.973013</created_at>
  <updated_at>2026-01-02T19:55:26.973013</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Scope by project metadata" level="2"/>
    <section name="JavaScript runtimes" level="3"/>
    <section name="Merge strategies" level="2"/>
  </sections>
  <features>
    <feature>javascript_runtimes</feature>
    <feature>merge_strategies</feature>
    <feature>scope_by_project_metadata</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>task,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Task inheritance

> **Context**: Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be 

Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be defined once at the workspace-level, and are then inherited by *many or all* projects.

Workspace-level tasks (also known as global tasks) are defined in [`.moon/tasks.yml`](/docs/config/tasks) or [`.moon/tasks/**/*.yml`](/docs/config/tasks), and are inherited by default. However, projects are able to include, exclude, or rename inherited tasks using the [`workspace.inheritedTasks`](/docs/config/project#inheritedtasks) in [`moon.yml`](/docs/config/project).
