---
doc_id: concept/moonrepo/root-project
chunk_id: concept/moonrepo/root-project#chunk-1
heading_path: ["Root-level project"]
chunk_type: prose
tokens: 226
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Root-level project</title>
  <description>Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, maintenance, or process oriented tasks can be ran. moon </description>
  <created_at>2026-01-02T19:55:27.193268</created_at>
  <updated_at>2026-01-02T19:55:27.193268</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Caveats" level="2"/>
    <section name="Greedy inputs" level="3"/>
    <section name="Inherited tasks" level="3"/>
  </sections>
  <features>
    <feature>caveats</feature>
    <feature>greedy_inputs</feature>
    <feature>inherited_tasks</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>rootlevel,concept,moonrepo</tags>
</doc_metadata>
-->

# Root-level project

> **Context**: Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, mainte

Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, maintenance, or process oriented tasks can be ran. moon supports this through a concept known as a root-level project.

Begin by adding the root to [`projects`](/docs/config/workspace#projects) with a source value of `.` (current directory relative from the workspace).

.moon/workspace.yml

```yaml
