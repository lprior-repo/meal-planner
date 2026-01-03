---
doc_id: concept/moonrepo/tasks
chunk_id: concept/moonrepo/tasks#chunk-1
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}"]
chunk_type: prose
tokens: 243
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>.moon/tasks\[/\*\*/\*\].{pkl,yml}</title>
  <description>The `.moon/tasks.yml` file configures file groups and tasks that are inherited by *every* project in the workspace, while `.moon/tasks/**/*.yml` configures for projects based on their language or type</description>
  <created_at>2026-01-02T19:55:27.003240</created_at>
  <updated_at>2026-01-02T19:55:27.003240</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="`extends`" level="2"/>
    <section name="`fileGroups`" level="2"/>
    <section name="`implicitDeps`" level="2"/>
    <section name="`implicitInputs`" level="2"/>
    <section name="`tasks`" level="2"/>
    <section name="`taskOptions` (v1.20.0)" level="2"/>
  </sections>
  <features>
    <feature>extends</feature>
    <feature>filegroups</feature>
    <feature>implicitdeps</feature>
    <feature>implicitinputs</feature>
    <feature>taskoptions_v1200</feature>
    <feature>tasks</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/task-inheritance</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/pkl-config</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/file-group</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/file-pattern</entity>
  </related_entities>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>moontaskspklyml,advanced,concept,moonrepo</tags>
</doc_metadata>
-->

# .moon/tasks\[/\*\*/\*\].{pkl,yml}

> **Context**: The `.moon/tasks.yml` file configures file groups and tasks that are inherited by *every* project in the workspace, while `.moon/tasks/**/*.yml` confi

The `.moon/tasks.yml` file configures file groups and tasks that are inherited by *every* project in the workspace, while `.moon/tasks/**/*.yml` configures for projects based on their language or type. [Learn more about task inheritance!](/docs/concepts/task-inheritance)

Projects can override or merge with these settings within their respective [`moon.yml`](/docs/config/project).

.moon/tasks.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/tasks.json'
```

> Inherited tasks configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
